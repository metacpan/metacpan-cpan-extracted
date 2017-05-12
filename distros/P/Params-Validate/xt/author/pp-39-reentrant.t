BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}

use strict;
use warnings;

use Params::Validate qw( validate SCALAR );
use Test::More;

for my $i ( 1 .. 1000 ) {
    ok( bar(), 'bar()' );
    is( foo( foo => $i ), $i, "reentrant validation works ($i)" );
}

done_testing();

sub foo {
    my %p = validate(
        @_,
        {
            foo => {
                callbacks => {
                    'call bar' => sub { bar() }
                },
            },
        },
    );

    return $p{foo};
}

sub bar {
    my %p = baz( baz => 42 );

    return $p{baz} == 42;
}

sub baz {
    my %p = validate(
        @_,
        {
            baz => {
                type      => SCALAR,
                callbacks => {
                    'is num' => sub { $_[0] =~ /^\d+$/ },
                },
            },
        },
    );

    return %p;
}

