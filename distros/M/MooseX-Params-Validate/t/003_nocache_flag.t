## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::Params::Validate;

    sub bar {
        my ( $self, $args, $params ) = @_;
        $params->{MX_PARAMS_VALIDATE_NO_CACHE}++;
        return validated_hash( $args, %$params );
    }
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );

is(
    exception {
        $foo->bar( [ baz => 1 ], { baz => { isa => 'Int' } } );
    },
    undef,
    '... successfully applied the parameter validation'
);

is(
    exception {
        $foo->bar( [ baz => [ 1, 2, 3 ] ], { baz => { isa => 'ArrayRef' } } );
    },
    undef,
    '... successfully applied the parameter validation (look mah no cache)'
);

is(
    exception {
        $foo->bar( [ baz => { one => 1 } ], { baz => { isa => 'HashRef' } } );
    },
    undef,
    '... successfully applied the parameter validation (look mah no cache) (just checkin)'
);

done_testing();
