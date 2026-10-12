use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Clay::XS qw(sizing_fixed CLAY_TOP_TO_BOTTOM);
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Sparkline;

my $RISING = "\x{2581}\x{2582}\x{2583}\x{2584}\x{2585}\x{2586}\x{2587} ";    # the last bar is a full cell

sub sparkline ( $width, %args ) { return sized( 'Term::Fabulous::Widget::Sparkline', $width, 1, %args ) }

sub shown ($sparkline) {
	draw($sparkline);
	return glyph_row( $sparkline, 0 );
}

subtest 'one row high, as wide as its parent lets it be' => sub {
	my $sparkline = Term::Fabulous::Widget::Sparkline->new( values => [ 1 .. 8 ], type => 'bar' );
	my $root      = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(12), height => sizing_fixed(5) } } );
	$root->add_child($sparkline);
	my @lines = Term::Fabulous::Static->new( root => $root, width => 12 )->render_lines( colors => 0 );
	is [ $sparkline->columns, $sparkline->rows ], [ 12, 1 ], 'the natural size';
	is scalar(@lines),                            1,         'nothing below it';
	unlike $lines[0], qr/[0-9]/, 'no axes, no labels';
};

subtest 'bars in eighths of the row' => sub {
	my $sparkline = sparkline( 8, values => [ 1 .. 8 ], type => 'bar', color => '#ff0000' );
	is shown($sparkline),                                        $RISING,                            'from 0 to the largest value';
	is [ fg_at( $sparkline, 0, 0 ), bg_at( $sparkline, 7, 0 ) ], [ rgb('#ff0000'), rgb('#ff0000') ], 'in the color';

	$sparkline->values( [ (8) x 4, 1 .. 8 ] );
	is shown($sparkline), $RISING, 'with more values than columns, the newest that fit';

	$sparkline->values( [ 9 .. 16 ] );
	$sparkline->min(8);
	is shown($sparkline), $RISING, 'min sets the bottom';
	$sparkline->min(undef);
	$sparkline->max(32);
	is shown($sparkline), "\x{2582}\x{2583}\x{2583}\x{2583}\x{2583}\x{2584}\x{2584}\x{2584}", 'max the top';
};

subtest 'lines and areas' => sub {
	my $sparkline = sparkline( 8, values => [ 1 .. 8 ] );
	is $sparkline->type, 'line', 'a line by default';
	like shown($sparkline), qr/\A[\x{2800}-\x{28FF} ]+\z/, 'drawn in Braille';
	$sparkline->type('area');
	is shown($sparkline), $RISING, 'an area fills from 0';

	my $high  = "\x{2585}\x{2585}\x{2586}\x{2586}\x{2587}\x{2587}  ";
	my $spent = " \x{2581}\x{2582}\x{2583}\x{2585}\x{2586}\x{2587} ";
	$sparkline->values( [ 9 .. 16 ] );
	is shown($sparkline),   $high,  'values far from 0 use little of the row';
	is $sparkline->zero(0), 0,      'zero returns the setting';
	is shown($sparkline),   $spent, 'zero 0 spends the row on the values';
	$sparkline->zero(undef);
	is shown($sparkline),                                                        $high,  'undef returns to the default of the type';
	is shown( sparkline( 8, type => 'bar', values => [ 9 .. 16 ], zero => 0 ) ), $spent, 'bars with zero 0 grow from the smallest value';
};

subtest 'values' => sub {
	my $sparkline = sparkline( 8, values => [ 1, 2 ] );
	is $sparkline->values, [ 1, 2 ], 'values';
	ref_is $sparkline->add_values( 3, 4 ), $sparkline, 'add_values returns the sparkline';
	is $sparkline->values, [ 1 .. 4 ], 'and adds at the end';

	my $window = sparkline( 8, values => [ 1 .. 5 ], max_points => 3 );
	is $window->values, [ 3, 4, 5 ], 'max_points keeps the newest';
	$window->add_values(6);
	is $window->values, [ 4, 5, 6 ], 'also when values are added';

	my $bars = sparkline( 4, type => 'bar', values => [2] );
	unlike shown($bars), qr/\x{2584}/, 'one full bar';
	$bars->add_values(1);
	like shown($bars), qr/\x{2584}/, 'each change shows in the next frame';
};

subtest 'the min must be below the max' => sub {
	like dies { sparkline( 8, min => 5, max => 1 ) }, qr/the min of y_axis \(5\) must be less than its max \(1\)/, 'a min above the max dies';
	my $sparkline = sparkline( 8, min => 1, values => [ 1, 2 ] );
	like dies { $sparkline->max(0) }, qr/the min of y_axis \(1\) must be less than its max \(0\)/, 'also when the max is set later';
	is $sparkline->max, undef, 'which leaves the max as it was';
};

subtest 'invalid input dies' => sub {
	like dies { sparkline( 8, type => 'scatter' ) }, qr/type must be one of area, bar, line, got 'scatter'/, 'an unknown type';
	my $sparkline = sparkline( 8, values => [ 1, 2 ] );
	like dies { $sparkline->type('pie') },               qr/type must be one of area, bar, line, got 'pie'/,             'an unknown type later';
	like dies { $sparkline->values( [ [ 1, 2, 3 ] ] ) }, qr/data point 0 of series 'values' must be \[ x, y \]/,         'a wrong value';
	like dies { $sparkline->min('low') },                qr/the min of y_axis must be a number, got 'low'/,              'a min that is no number';
	like dies { $sparkline->zero( [] ) },                qr/zero must be a plain boolean value, got an ARRAY reference/, 'a zero that is no boolean';
	is $sparkline->min, undef, 'the min is unchanged';
	ok lives { $sparkline->type('bar') }, 'and the sparkline can still change its type';
};

done_testing;
