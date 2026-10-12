use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use List::Util qw(sum);
use Term::Fabulous;
use Term::Fabulous::Static;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Term::Fabulous::Widget::Table;

my ( $OPAQUE, $GLASS ) = ( [ 10, 20, 30, 255 ], [ 200, 100, 50, 128 ] );
my $DARK_SCREEN  = [ 22,  22,  34,  255 ];
my $LIGHT_SCREEN = [ 250, 250, 247, 255 ];

sub box (%args) {
	return Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } }, %args );
}

# Parent links and a widget's link to its UI are weak: the roots and the
# UIs of the tests are kept here.
my @alive;

# A chain root > middle > leaf; returns the leaf.

sub chain ( $root, $middle ) {
	my $leaf = box();
	$middle->add_child($leaf);
	$root->add_child($middle);
	push @alive, $root;
	return $leaf;
}

# A live UI on a memory terminal around $root, drawn once.
sub live ( $root, %args ) {
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 12 );
	my $ui       = Term::Fabulous->new( root => $root, width => 40, height => 12, terminal => $terminal, %args );
	$ui->step;
	push @alive, $ui;
	return $terminal;
}

# The position of the first cell showing $text on the screen.
sub find_text ( $terminal, $text ) {
	my @lines = $terminal->lines;
	foreach my $y ( 0 .. $#lines ) {
		my $x = index $lines[$y], $text;
		return ( $x, $y ) if $x >= 0;
	}
	return;
}

sub channels ($packed) {
	return [ ( $packed >> 16 ) & 0xFF, ( $packed >> 8 ) & 0xFF, $packed & 0xFF ];
}

subtest 'an opaque background of the widget or an ancestor' => sub {
	my $leaf = chain( box( background_color => $OPAQUE ), box() );
	is $leaf->background_below, $OPAQUE, 'the nearest ancestor with an opaque background';
	$leaf->background_color('#ff0000');
	is $leaf->background_below, [ 255, 0, 0, 255 ], 'the widget itself first';
	my $copy = $leaf->background_below;
	$copy->[0] = 0;
	is $leaf->background_color, [ 255, 0, 0, 255 ], 'a new array';
};

subtest 'a translucent ancestor' => sub {
	my $leaf = chain( box( background_color => $OPAQUE ), box( background_color => $GLASS ) );
	is $leaf->background_below,                     $OPAQUE, 'is skipped: the colors below it show through';
	is $leaf->background_below( translucent => 1 ), $GLASS,  'counts with translucent => 1';
	like dies { $leaf->background_below( opaque => 1 ) }, qr/background_below does not take opaque \(known: translucent\)/, 'other options die';
};

subtest 'the screen background of the live UI' => sub {
	my $leaf = chain( box(), box( background_color => $GLASS ) );
	live( $leaf->root );
	is $leaf->background_below,                     $DARK_SCREEN, "without an opaque background: the theme's background token";
	is $leaf->background_below( translucent => 1 ), $GLASS,       'a translucent one still counts with translucent => 1';

	my $light = chain( box(), box() );
	live( $light->root, theme => 'light' );
	is $light->background_below, $LIGHT_SCREEN, 'of the theme in use';

	my $glass_screen = chain( box(), box() );
	live( $glass_screen->root, theme => Term::Fabulous::Theme->new( palette => { background => [ 1, 2, 3, 100 ] } ) );
	is $glass_screen->background_below, [ 1, 2, 3, 255 ], 'opaque, as the screen is painted';

	my $none = chain( box(), box() );
	live( $none->root, theme => Term::Fabulous::Theme->new( palette => { background => [ 0, 0, 0, 0 ] } ) );
	is $none->background_below, undef, 'none for a token with alpha 0';
};

subtest 'no screen' => sub {
	my $static = chain( box(), box() );
	Term::Fabulous::Static->new( root => $static->root, width => 10, height => 2 );
	is $static->background_below,               undef, 'in a Term::Fabulous::Static';
	is chain( box(), box() )->background_below, undef, 'in no UI';
};

subtest 'a light theme: table cells lie on the screen' => sub {
	my $table = Term::Fabulous::Widget::Table->new( id => 'people', columns => [ { key => 'name', title => 'Name' } ], rows => [ { name => 'Ann' }, { name => 'Bob' } ] );
	my $root  = box();
	$root->add_child($table);
	my $terminal = live( $root, theme => 'light' );
	my ( $x, $y ) = find_text( $terminal, 'Bob' );
	is channels( $terminal->cell( $x, $y )->[2] ), [ @$LIGHT_SCREEN[ 0 .. 2 ] ], 'a body cell is painted in the screen color';

	my $static = Term::Fabulous::Widget::Table->new( id => 'static', columns => [ { key => 'name', title => 'Name' } ], rows => [ { name => 'Ann' } ] );
	my $lines  = join "\n", Term::Fabulous::Static->new( root => $static, width => 10 )->render_lines( colors => 1 );
	like $lines, qr/\e\[48;2;22;25;31m/, 'on nothing (Static), cells keep their fixed dark color';
};

subtest 'a light theme: chart ink suits the screen' => sub {
	my $chart = Term::Fabulous::Widget::LineChart->new( title => 'Load', labels => [qw(a b)], series => [ { name => 'cpu', data => [ 1, 2 ] } ] );
	my $root  = box();
	$root->add_child($chart);
	my $terminal = live( $root, theme => 'light' );
	my ( $x, $y ) = find_text( $terminal, 'Load' );
	my ( undef, $fg, $bg ) = @{ $terminal->cell( $x, $y ) };
	is channels($bg), [ @$LIGHT_SCREEN[ 0 .. 2 ] ], 'the title lies on the screen';
	ok( ( sum( @{ channels($fg) } ) < 3 * 128 ), 'and is drawn in dark ink, readable on it' );
	is $chart->effective_background, 0xFAFAF7, 'effective_background is the screen color';
};

done_testing;
