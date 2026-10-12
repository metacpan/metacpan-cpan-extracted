use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Viewport qw(max_offset clamp_offset reveal_range scroll_thumb);

subtest 'max_offset and clamp_offset' => sub {

	# [ content, viewport, offset, max offset, clamped offset, what ]
	my @cases = (
		[ 40, 10,  12, 30, 12,  'inside' ],
		[ 40, 10, -3,  30, 0,   'above the start' ],
		[ 40, 10,  31, 30, 30,  'past the end' ],
		[ 5,  10,  2,  0,  0,   'content that fits does not scroll' ],
		[ 10, 10,  0,  0,  0,   'content as large as the viewport' ],
		[ 40, 10, 2.5, 30, 2.5, 'fractions stay (Clay positions are floats)' ],
	);
	foreach my $case (@cases) {
		my ( $content, $viewport, $offset, $max, $clamped, $what ) = @$case;
		is [ max_offset( $content, $viewport ), clamp_offset( $content, $viewport, $offset ) ], [ $max, $clamped ], $what;
	}
};

subtest 'reveal_range' => sub {

	# [ offset, from, to, new offset, what ] in 40 rows content, 10 visible
	my @cases = (
		[ 10, 12, 13, 10, 'a row in view: no change' ],
		[ 10, 10, 20, 10, 'a range filling the view exactly' ],
		[ 10, 4,  5,  4,  'a row above: it becomes the first' ],
		[ 10, 25, 26, 16, 'a row below: it becomes the last' ],
		[ 10, 18, 22, 12, 'a range across the end: its end becomes the last' ],
		[ 10, 25, 40, 25, 'a range larger than the viewport: its start' ],
		[ 10, 2,  30, 2,  'also when it starts above' ],
		[ 30, 39, 40, 30, 'the last row at the end' ],
		[ 0,  45, 46, 30, 'beyond the content: clamped' ],
	);
	foreach my $case (@cases) {
		my ( $offset, $from, $to, $expected, $what ) = @$case;
		is reveal_range( 40, 10, $offset, $from, $to ), $expected, $what;
	}
	is reveal_range( 5, 10, 0, 3, 4 ), 0, 'content that fits stays at 0';
};

subtest 'scroll_thumb' => sub {

	# [ content, viewport, offset, track, [ first, size ], what ]
	my @cases = (
		[ 40,  10, 0,   10, [ 0, 3 ],  'at the start' ],
		[ 40,  10, 30,  10, [ 7, 3 ],  'at the end' ],
		[ 40,  10, 15,  10, [ 4, 3 ],  'in the middle, rounded' ],
		[ 20,  10, 5,   10, [ 3, 5 ],  'half the content visible: half the track' ],
		[ 400, 10, 0,   10, [ 0, 1 ],  'at least one cell' ],
		[ 400, 10, 390, 10, [ 9, 1 ],  'which reaches the last cell at the end' ],
		[ 40,  10, 31,  10, [ 7, 3 ],  'an offset past the end stays in the track' ],
		[ 40,  10, 12,  1,  [ 0, 1 ],  'a track of one cell is all thumb' ],
		[ 40,  10, 12,  0,  [ 0, 0 ],  'a track of no cells has no thumb' ],
		[ 5,   10, 0,   10, [ 0, 10 ], 'content smaller than the viewport fills the track' ],
		[ 10,  10, 0,   10, [ 0, 10 ], 'so does content as large as it' ],
		[ 40,  10, 0,   20, [ 0, 5 ],  'a track longer than the viewport' ],
	);
	foreach my $case (@cases) {
		my ( $content, $viewport, $offset, $track, $expected, $what ) = @$case;
		is scroll_thumb( $content, $viewport, $offset, $track ), $expected, $what;
	}
};

done_testing;
