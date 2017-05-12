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

my ( $error, $topic );

given ("foo") {
    when (qr/./) {
        try {
            die "blah\n";
        } catch {
            $topic = $_;
            $error = $_[0];
        }
        pass("syntax ok");
    };
}

is( $error, "blah\n", "error caught" );

{
    local $TODO = "perhaps a workaround can be found"
        if $] < 5.018;
    is( $topic, $error, 'error is also in $_' );
}

done_testing;
