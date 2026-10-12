use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
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

done_testing;
