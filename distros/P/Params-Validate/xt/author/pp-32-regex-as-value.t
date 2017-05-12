BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}

use strict;
use warnings;

use Params::Validate qw( validate SCALAR SCALARREF );

use Test::More;
use Test::Fatal;

is(
    exception { v( foo => qr/foo/ ) },
    undef,
    'no exception with regex object'
);

is(
    exception { v( foo => 'foo' ) },
    undef,
    'no exception with plain scalar'
);

my $foo = 'foo';
is(
    exception { v( foo => \$foo ) },
    undef,
    'no exception with scalar ref'
);

done_testing();

sub v {
    validate(
        @_, {
            foo => { type => SCALAR | SCALARREF },
        },
    );
    return;
}

