use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE TB_MOD_MOTION);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;

# A 30 x 8 memory terminal showing one framed scroll box with $lines
# lines of text; returns the box and a harness with the terminal and UI.
sub box_ui ( $lines, %args ) {
	my $box = Term::Fabulous::Widget::ScrollBox->new(
		id           => 'log',
		layout       => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
		bordered     => 1,
		border_color => [ 1, 1, 1, 255 ],
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
		%args,
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => "Line $_" . ( $args{horizontal} ? ' ' . ( 'x' x 40 ) : '' ) ) ) foreach 1 .. $lines;
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($box);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 30, height => 8 );
	my $ui       = Term::Fabulous->new( root => $root, width => 30, height => 8, terminal => $terminal );
	$ui->step;
	return ( $box, { terminal => $terminal, ui => $ui } );
}

sub row ( $h, $y ) {
	return join '', map { ( $h->{terminal}->cell( $_, $y ) // [' '] )->[0] // ' ' } 0 .. 29;
}

sub column ( $h, $x ) {
	return join '', map { ( $h->{terminal}->cell( $x, $_ ) // [' '] )->[0] // ' ' } 0 .. 7;
}

sub click ( $h, $x, $y, $mod = 0 ) {
	$h->{terminal}->mouse( key => TB_KEY_MOUSE_LEFT,    x => $x, y => $y, mod => $mod );
	$h->{terminal}->mouse( key => TB_KEY_MOUSE_RELEASE, x => $x, y => $y, ch  => TB_KEY_MOUSE_LEFT ) unless $mod & TB_MOD_MOTION;
	$h->{ui}->step;
	return;
}

subtest 'directions' => sub {
	my $box = Term::Fabulous::Widget::ScrollBox->new( id => 'log' );
	is [ $box->horizontal, $box->vertical ], [ 0, 1 ], 'vertical by default';
	my $both = Term::Fabulous::Widget::ScrollBox->new( id => 'both', horizontal => 'yes', vertical => '' );
	is [ $both->horizontal, $both->vertical ], [ 1, 0 ], 'the constructor takes any truth value';
	is $both->to_config->{clip}, { horizontal => 1, vertical => 0 }, 'and hands Clay the directions';
	like dies { Term::Fabulous::Widget::ScrollBox->new }, qr/requires an explicit 'id'/, 'an id is required: Clay keeps the scroll position by it';
};

subtest 'KDL properties' => sub {
	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::ScrollBox as ScrollBox
ScrollBox "table" {
	horizontal #true
	vertical #false
}
KDL
	is [ $built->id, $built->horizontal, $built->vertical ], [ 'table', 1, 0 ], 'horizontal and vertical';
};

subtest 'vertical scrollbar' => sub {
	my ( $box, $h ) = box_ui(30);
	is column( $h, 28 ),           "─\x{2503}\x{2503}││││─", 'the last content column shows the track with the thumb at the top';
	is scalar @{ $box->children }, 30,                       'the scrollbar is not among the children';
	click( $h, 28, 6 );
	like row( $h, 6 ),     qr/Line 30/,     'a click at the end of the scrollbar shows the end';
	like column( $h, 28 ), qr/\x{2503}─\z/, 'and the thumb is at the bottom';
	click( $h, 28, 1, TB_MOD_MOTION );
	like row( $h, 1 ), qr/Line 1 /, 'dragging to the top shows the start';

	my ( $fits, $fits_h ) = box_ui(3);
	is column( $fits_h, 28 ), '─' . ( ' ' x 6 ) . '─', 'the column is kept but empty while the content fits';

	$box->scrollbar(0);
	$h->{ui}->step;
	like row( $h, 1 ), qr/Line 1 {22}│\z/, 'scrollbar(0) gives the column back to the content';
};

subtest 'the scrollbars sit inside the border' => sub {
	my ( $box, $h ) = box_ui(30);
	$box->bordered(0);
	$h->{ui}->step;
	like column( $h, 29 ), qr/\A\x{2503}/, 'without a border the scrollbar takes the last column';
	$box->bordered( { right => 1 } );
	$h->{ui}->step;
	like column( $h, 28 ), qr/\A\x{2503}/, 'with a right border it moves inside it';
};

subtest 'horizontal scrollbar' => sub {
	my ( $box, $h ) = box_ui( 3, horizontal => 1 );
	like row( $h, 6 ), qr/\A│\x{2501}+─+ │\z/, 'the last content row shows the horizontal track with the thumb at the left';
	is substr( column( $h, 28 ), 1, 6 ), ' ' x 6, 'the vertical scrollbar column is empty: nothing to scroll down';
	click( $h, 20, 6 );
	like row( $h, 6 ),   qr/\A│─+\x{2501}+ │\z/, 'a click at the right of the track scrolls sideways';
	unlike row( $h, 1 ), qr/Line 1/,             'and the start of the lines is out of view';
};

subtest 'scrollbar parameters' => sub {
	my $box = Term::Fabulous::Widget::ScrollBox->new( id => 'log', scrollbar => '', track_color => '#464c5a', thumb_color => [ 1, 2, 3, 255 ] );
	is [ $box->scrollbar, $box->track_color, $box->thumb_color ], [ 0, [ 70, 76, 90, 255 ], [ 1, 2, 3, 255 ] ], 'scrollbar is a boolean, the colors are stored as [r, g, b, a]';
	is $box->thumb_color('#ff0000'), [ 255, 0, 0, 255 ], 'the color accessors set and return the color';
	like dies { $box->track_color('no') },                                                  qr/track_color/, 'an invalid color dies';
	like dies { Term::Fabulous::Widget::ScrollBox->new( id => 'x', thumb_color => 'no' ) }, qr/thumb_color/, 'also in the constructor';
	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::ScrollBox as ScrollBox
ScrollBox "log" {
	scrollbar #false
	thumb_color "#010203"
}
KDL
	is [ $built->scrollbar, $built->thumb_color ], [ 0, [ 1, 2, 3, 255 ] ], 'scrollbar and the colors are KDL properties';
};

subtest 'reveal' => sub {
	my ( $box, $h ) = box_ui(30);
	my $ui    = $h->{ui};
	my @lines = @{ $box->children };
	ref_is $box->reveal( $lines[19] ), $box, 'returns the box';
	$ui->step;
	is $ui->bounding_box( $lines[19] )->{y}, 6, 'nearest: a line below the view lands on the last inner row';
	$box->reveal( $lines[9], align => 'top' );
	$ui->step;
	is $ui->bounding_box( $lines[9] )->{y}, 1, 'top: its first row at the top of the view';
	$box->reveal( $lines[28], align => 'top' );
	$ui->step;
	is [ $ui->bounding_box( $lines[28] )->{y}, $ui->bounding_box( $lines[-1] )->{y} ], [ 5, 6 ], 'as far as the content allows';

	my $added = Term::Fabulous::Widget::Text->new( text => 'Line 31' );
	$box->insert_children( 0, $added );
	$box->reveal($added);
	$ui->step;
	$ui->step;
	is $ui->bounding_box($added)->{y}, 1, 'a widget laid out one frame later is revealed after that frame';

	like dies { $box->reveal( Term::Fabulous::Widget::Text->new( text => 'elsewhere' ) ) }, qr/reveal needs a widget inside the box/, 'a widget outside the box dies';
	like dies { $box->reveal( $added, align  => 'bottom' ) }, qr/align must be/,                     'so does another align';
	like dies { $box->reveal( $added, frames => 0 ) },        qr/frames must be a positive integer/, 'and frames that are not a positive integer';
	like dies { $box->reveal( $added, slowly => 1 ) },        qr/reveal does not take slowly/,       'and another option';
};

subtest 'a focused descendant is scrolled into view' => sub {
	require Term::Fabulous::Widget::Button;
	my $box     = Term::Fabulous::Widget::ScrollBox->new( id => 'form', layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my @buttons = map { Term::Fabulous::Widget::Button->new( layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } ) } 1 .. 20;
	$box->add_child(@buttons);
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($box);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 30, height => 8 );
	my $ui       = Term::Fabulous->new( root => $root, width => 30, height => 8, terminal => $terminal );
	$ui->step;
	$ui->interaction->set_focused_widget( $buttons[15] );
	$ui->step;
	my $shown = $ui->bounding_box( $buttons[15] );
	ok $shown->{y} >= 0 && $shown->{y} + $shown->{height} <= 8, 'the focused button far below lies in the viewport';
	is $ui->bounding_box( $buttons[15] )->{y}, 7, 'the box scrolled the smallest way: the button is on the last row';
	$ui->interaction->set_focused_widget( $buttons[2] );
	$ui->step;
	ok $ui->bounding_box( $buttons[2] )->{y} >= 0, 'and back up for a button above the viewport';

	my $text = Term::Fabulous::Widget::Text->new( markup => '[link=x]a link[/]' );
	$box->add_child($text);
	$ui->interaction->set_focused_widget($text);
	$ui->step;
	$ui->step;
	my $parent_row = $ui->bounding_box($box)->{y};
	my $frame      = $ui->last_frame;
	my @rows       = $frame->text_rows($text);
	is scalar(@rows), 1, 'a text added and focused in one step is revealed after the frame that laid it out';
	ok $rows[0][0] >= $parent_row && $rows[0][0] < 8, 'on a row of the viewport';
};

done_testing;
