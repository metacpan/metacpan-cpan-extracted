use strict;
use warnings;
use Test::More;
use lib 't/try/lib';
use 5.014;

BEGIN {
    if ($] >= 5.041000) {
        plan skip_all => "given/when not supported on perl >= 5.41";
    }
    if (!eval { require Try::Tiny }) {
        plan skip_all => "This test requires Try::Tiny";
    }
}

no if $] >= 5.018000, warnings => 'experimental::smartmatch';
no if $] >= 5.037011, warnings => 'deprecated::smartmatch';

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
