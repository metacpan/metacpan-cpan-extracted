use strict;
use warnings;

use Test::More;

plan skip_all => 'This test is flaky';

use Params::Validate::Array qw( validate );

sub test {
    my $def = $0;

    # The spec is irrelevant, all that matters is that there's a
    # tainted scalar as the default
    my %p = validate( @_, { foo => { default => $def } } );
}

TODO:
{
    local $TODO = 'I cannot figure out how to prevent this error in XS mode'
        unless $ENV{PV_TEST_PERL};

    eval { test() };
    is(
        $@, '',
        'no taint error when we validate with tainted value in caller sub'
    );
}
