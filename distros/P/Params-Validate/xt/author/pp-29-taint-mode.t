#!perl -T

BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}


use strict;
use warnings;

use Test::Requires {
    'Test::Taint' => 0.02,
};

use Test::Fatal;
use Test::More;

use Params::Validate qw( validate validate_pos ARRAYREF );

taint_checking_ok('These tests are meaningless unless we are in taint mode.');

sub test1 {
    my $def = $0;
    tainted_ok( $def, 'make sure $def is tainted' );

    # The spec is irrelevant, all that matters is that there's a
    # tainted scalar as the default
    my %p = validate( @_, { foo => { default => $def } } );
}

{
    is(
        exception { test1() },
        undef,
        'no taint error when we validate with tainted default value'
    );
}

sub test2 {
    return validate_pos( @_, { regex => qr/^b/ } );
}

SKIP:
{
    skip 'This test only passes on Perl 5.14+', 1
        unless $] >= 5.014;

    my @p = 'cat';
    taint(@p);

    like(
        exception { test2(@p) },
        qr/\QParameter #1 ("cat") to main::test2 did not pass regex check/,
        'no taint error when we validate with tainted value values being validated'
    );
}

done_testing();

