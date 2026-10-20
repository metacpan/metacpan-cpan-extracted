use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::Placement qw(place_popup TOPMOST_Z_INDEX);

# A popup on a 40 x 20 screen.
sub placed ( $anchor, $size, %options ) {
	my %box;
	@box{qw(x y width height)} = @$anchor;
	my $place = place_popup( anchor => \%box, size => $size, screen => [ 40, 20 ], %options );
	return [ @{$place}{qw(x y flipped rows)} ];
}

subtest 'below and above an anchor' => sub {
	my @cases = (

		# anchor [x, y, w, h], size [w, h], options => [x, y, flipped, rows], what
		[ [ 2, 3, 10, 1 ],  [ 12, 5 ],  [],                    [ 2, 4, 0, 16 ],  'below, room enough' ],
		[ [ 2, 14, 10, 1 ], [ 12, 5 ],  [],                    [ 2, 15, 0, 5 ],  'below, exactly fits' ],
		[ [ 2, 15, 10, 1 ], [ 12, 5 ],  [],                    [ 2, 10, 1, 15 ], 'too little room below: above' ],
		[ [ 2, 9, 10, 2 ],  [ 12, 12 ], [],                    [ 2, 8, 0, 9 ],   'fits neither side, more room below: below, moved up' ],
		[ [ 2, 10, 10, 2 ], [ 12, 12 ], [],                    [ 2, 0, 1, 10 ],  'fits neither side, more room above: above, moved down' ],
		[ [ 2, 6, 10, 1 ],  [ 12, 5 ],  [ prefer => 'above' ], [ 2, 1, 0, 6 ],   'above, room enough' ],
		[ [ 2, 2, 10, 1 ],  [ 12, 5 ],  [ prefer => 'above' ], [ 2, 3, 1, 17 ],  'too little room above: below' ],
		[ [ 2, 8, 10, 4 ],  [ 12, 12 ], [ prefer => 'above' ], [ 2, 0, 0, 8 ],   'fits neither side, as much room below: above, moved down' ],
	);
	foreach my $case (@cases) {
		my ( $anchor, $size, $options, $expected, $what ) = @$case;
		is placed( $anchor, $size, @$options ), $expected, $what;
	}
};

subtest 'at an anchor and at a point' => sub {
	is placed( [ 5, 4, 0, 0 ], [ 10, 6 ], prefer => 'at' ),                      [ 5, 4, 0, 20 ],   'at a point';
	is placed( [ 35, 17, 0, 0 ], [ 10, 6 ], prefer => 'at' ),                    [ 30, 14, 0, 20 ], 'at a point in the bottom right corner: moved up and left';
	is placed( [ 0, 15, 30, 5 ], [ 12, 12 ], prefer => 'at', align => 'right' ), [ 18, 8, 0, 20 ],  'over the top right corner of a box near the bottom';
	is placed( [ 0, 0, 0, 0 ], [ 50, 30 ], prefer => 'at' ),                     [ 0, 0, 0, 20 ],   'larger than the screen: from the top left corner';
};

subtest 'kept on the screen sideways' => sub {
	is placed( [ 34, 3, 6, 1 ], [ 35, 5 ] ), [ 5, 4, 0, 16 ], 'a wide popup under a box at the right edge moves left';
	is placed( [ 34, 3, 6,  1 ], [ 35, 5 ], align => 'right' ), [ 5,  4, 0, 16 ], 'so does one aligned right';
	is placed( [ 0,  3, 6,  1 ], [ 12, 5 ], align => 'right' ), [ 0,  4, 0, 16 ], 'one aligned right at the left edge moves right';
	is placed( [ 10, 3, 20, 1 ], [ 12, 5 ], align => 'right' ), [ 18, 4, 0, 16 ], 'aligned right, room enough';
};

subtest 'arguments' => sub {
	my %good = ( anchor => { x => 0, y => 0, width => 1, height => 1 }, size => [ 1, 1 ], screen => [ 10, 10 ] );
	like dies { place_popup( %good, side => 'left' ) }, qr/\ATerm::Fabulous::Placement: place_popup does not take side \(known: align anchor prefer screen size\)/, 'unknown option';
	like dies { place_popup( %good, anchor => { x => 0, y => 0 } ) },
		qr/\ATerm::Fabulous::Placement: place_popup anchor must be a hash reference with the numbers x, y, width and height, got a HASH reference/, 'anchor';
	like dies { place_popup( %good, size   => [ 1, -1 ] ) }, qr/\ATerm::Fabulous::Placement: place_popup size must be an array reference of two numbers of at least 0, got an ARRAY reference/, 'size';
	like dies { place_popup( %good, screen => undef ) },     qr/screen must be an array reference of two numbers of at least 0, got undef/, 'screen';
	like dies { place_popup( %good, prefer => 'left' ) },    qr/prefer must be one of above, at, below, got 'left'/,                        'prefer';
	like dies { place_popup( %good, align  => 'center' ) },  qr/align must be one of left, right, got 'center'/,                            'align';
	is TOPMOST_Z_INDEX, 32767, 'the topmost z_index is the highest Clay has';
};

done_testing;
