use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Path::Hilbert::XS') }

can_ok( Path::Hilbert::XS::, qw<d2xy xy2d> );
can_ok( __PACKAGE__, qw<d2xy xy2d> );

is_deeply(
    [ d2xy( 16, 127 ) ],
    [ 7, 8 ],
    'd2xy() works as expected',
);

is(
    xy2d( 16, 7, 8 ),
    127,
    'xy2d() works as expected',
);

done_testing();
