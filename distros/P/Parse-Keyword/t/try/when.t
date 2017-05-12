use strict;
use warnings;
use Test::More;
use lib 't/try/lib';
use 5.014;

BEGIN {
    if (!eval { require Try::Tiny }) {
        plan skip_all => "This test requires Try::Tiny";
    }
}

no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Try;

my ( $foo, $bar, $other );

$_ = "magic";

try {
    die "foo";
} catch {

    like( $_, qr/foo/ );

    when (/bar/) { $bar++ };
    when (/foo/) { $foo++ };
    default { $other++ };
}

is( $_, "magic", '$_ not clobbered' );

ok( !$bar, "bar didn't match" );
ok( $foo, "foo matched" );
ok( !$other, "fallback didn't match" );

done_testing;
