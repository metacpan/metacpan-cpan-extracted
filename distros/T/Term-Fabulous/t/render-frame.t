use v5.32;
use warnings;

use Test2::V0;

use Object::Pad 0.825;
use Clay::XS qw(
	sizing_fixed sizing_grow
	CLAY_TOP_TO_BOTTOM
	CLAY_RENDER_COMMAND_TYPE_RECTANGLE
	CLAY_RENDER_COMMAND_TYPE_BORDER
	CLAY_RENDER_COMMAND_TYPE_TEXT
	CLAY_RENDER_COMMAND_TYPE_IMAGE
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_START
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
	CLAY_RENDER_COMMAND_TYPE_CUSTOM
);
use Term::Fabulous::Render::Frame;
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Canvas;
use Term::Fabulous::Widget::ScrollBox;

sub command {
	my ( $type, $x, $y, $width, $height, %extra ) = @_;
	return { commandType => $type, id => $extra{id} // 0, boundingBox => { x => $x, y => $y, width => $width, height => $height }, renderData => $extra{data} // {} };
}

sub frame {
	my (@commands) = @_;
	return Term::Fabulous::Render::Frame->new( commands => \@commands, width => 10, height => 5 );
}

sub rectangle {
	my (@bounds) = @_;
	return command( CLAY_RENDER_COMMAND_TYPE_RECTANGLE, @bounds );
}

sub scissor_start {
	my (@bounds) = @_;
	return command( CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, @bounds );
}

sub scissor_end { return command( CLAY_RENDER_COMMAND_TYPE_SCISSOR_END, 0, 0, 0, 0 ) }

subtest 'clip rects replay nested scissors' => sub {
	my $frame = frame(
		rectangle( 0, 0, 10, 5 ),
		scissor_start( 2, 1, 6, 10 ),
		rectangle( 0, 0, 10, 5 ),
		scissor_start( 5, 0, 10, 2 ),
		rectangle( 0, 0, 10, 5 ),
		scissor_end(),
		rectangle( 0, 0, 10, 5 ),
		scissor_end(),
		rectangle( 0, 0, 10, 5 ),
		scissor_start( 20, 0, 5, 5 ),
		rectangle( 0, 0, 10, 5 ),
		scissor_end(),
	);
	is [ map { $frame->clip_rect($_) } 0 .. 10 ], [
		[ 0,  0, 10, 5 ],    # no scissor: the viewport
		[ 0,  0, 10, 5 ],    # a scissor start is outside its own scissor
		[ 2,  1, 8,  5 ],    # cut to the viewport
		[ 2,  1, 8,  5 ],
		[ 5,  1, 8,  2 ],    # a nested scissor is cut to the one around it
		[ 5,  1, 8,  2 ],
		[ 2,  1, 8,  5 ],    # the end restores the outer scissor
		[ 2,  1, 8,  5 ],
		[ 0,  0, 10, 5 ],
		[ 0,  0, 10, 5 ],
		[ 20, 0, 20, 5 ],    # a scissor outside the viewport leaves an empty rect
		],
		'one clip rect per command';
	is [ $frame->painted_rects(1) ],  [],                 'a scissor paints nothing';
	is [ $frame->painted_rects(4) ],  [ [ 5, 1, 8, 2 ] ], 'a rectangle paints its clipped box';
	is [ $frame->painted_rects(10) ], [],                 'nothing outside an empty clip rect';

	like dies { frame( scissor_end() ) },                                         qr/\ATerm::Fabulous::Render::Frame: scissor end without an open scissor/, 'an unmatched end dies';
	like dies { frame( command( CLAY_RENDER_COMMAND_TYPE_IMAGE, 0, 0, 1, 1 ) ) }, qr/unhandled render command type IMAGE/,                                  'an unpainted command type dies';
	like dies { $frame->clip_rect(12) },                                          qr/no command at index '12'; the frame has 12 commands/,                  'an index past the end dies';
};

subtest 'a border paints the edges of its sides with a width' => sub {
	my $frame = frame( command( CLAY_RENDER_COMMAND_TYPE_BORDER, 1, 1, 4, 3, data => { width => { top => 1, right => 0, bottom => 2, left => 1 } } ) );
	is [ $frame->painted_rects(0) ], [
		[ 1, 3, 5, 4 ],    # bottom: one cell thick whatever its width
		[ 1, 1, 2, 4 ],    # left
		[ 1, 1, 5, 2 ],    # top
		],
		'no right edge, and nothing inside';
	is [ $frame->topmost_at( 2, 2 ) ], [], 'the inside is not painted';
};

subtest 'paint order, painted_after and topmost_at' => sub {
	my $frame = frame(
		rectangle( 0, 0, 10, 5, id => 1 ),
		command( CLAY_RENDER_COMMAND_TYPE_CUSTOM, 1, 1, 4, 2, id => 2, data => { backgroundColor => { r => 10, g => 20, b => 30, a => 255 } } ),
		command( CLAY_RENDER_COMMAND_TYPE_TEXT,   3, 2, 5, 1, id => 3 ),
	);
	is [ map { [ $_->{commandType}, $_->{id} ] } $frame->commands ],
		[ [ CLAY_RENDER_COMMAND_TYPE_RECTANGLE, 1 ], [ CLAY_RENDER_COMMAND_TYPE_RECTANGLE, 2 ], [ CLAY_RENDER_COMMAND_TYPE_CUSTOM, 2 ], [ CLAY_RENDER_COMMAND_TYPE_TEXT, 3 ] ],
		"a canvas's background, carried in its command, is painted as a rectangle before the canvas";
	is $frame->command_count, 4, 'command_count';

	is $frame->painted_after( 2, [ 1, 1, 3, 2 ] ), 0, 'nothing is painted over the top row of the canvas';
	is $frame->painted_after( 2, [ 1, 1, 5, 3 ] ), 1, 'the text is painted over its bottom row';

	is [ $frame->topmost_at( 3,  2 ) ], [ 3, 2, 1, 0 ], 'every command painting the cell, the topmost first';
	is [ $frame->topmost_at( 9,  0 ) ], [0],            'only the root';
	is [ $frame->topmost_at( 10, 0 ) ], [],             'outside the viewport';

	my $empty = Term::Fabulous::Render::Frame->new( commands => [], width => 3, height => 2 );
	is [ $empty->command_count, [ $empty->topmost_at( 0, 0 ) ] ], [ 0, [] ], 'an empty frame';
	like dies { Term::Fabulous::Render::Frame->new( commands => {}, width =>  3, height => 2 ) }, qr/commands must be an array reference/,            'commands are checked';
	like dies { Term::Fabulous::Render::Frame->new( commands => [], width => -1, height => 2 ) }, qr/width must be a number of at least 0, got '-1'/, 'the size is checked';
};

subtest 'painting stays inside the scissors of a scroll box' => sub {
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $box  = Term::Fabulous::Widget::ScrollBox->new( id => 'log', layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(3), height => sizing_fixed(2) } } );
	$box->add_child( Term::Fabulous::Widget::Box->new( background_color => [ 9, 9, 9, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } ) ) foreach 1 .. 4;
	$root->add_child($box);
	my $ui = Term::Fabulous::Static->new( root => $root, width => 5, height => 4 );

	is [ $ui->last_frame->command_count ], [0], 'before the first frame, last_frame is empty';
	$ui->draw;
	is [ map { defined $ui->cell( 0, $_ ) ? 1 : 0 } 0 .. 3 ], [ 1, 1, 0, 0 ], 'the rows below the box are not painted';
	like dies { $ui->clip_rect }, qr/clip_rect is only known while a render command is painted/, 'clip_rect outside painting dies';
};

class DyingCanvas :isa(Term::Fabulous::Widget::Canvas) {
	method cell_row :override ($y) { die "cannot paint\n" }
}

subtest 'the last frame is complete when painting dies partway' => sub {
	my $root   = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $canvas = DyingCanvas->new( layout => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } } );
	my $after  = Term::Fabulous::Widget::Box->new( background_color => [ 1, 1, 1, 255 ], layout => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } } );
	$root->add_child( $canvas, $after );
	my $ui = Term::Fabulous::Static->new( root => $root, width => 6, height => 1 );

	is dies { $ui->draw }, "cannot paint\n", 'painting the canvas dies';
	my $frame = $ui->last_frame;
	my ($top) = $frame->topmost_at( 2, 0 );
	ref_is $ui->widget_for( $frame->command($top)->{userData} ), $after, 'the frame also holds the commands after the one that failed';
};

done_testing;
