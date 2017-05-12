## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util;

{
    package Foo;
    use Moose;
    use MooseX::Params::Validate;

    sub bar {
        my ( $self, $args, $params ) = @_;
        $params->{MX_PARAMS_VALIDATE_CACHE_KEY}
            = Scalar::Util::refaddr($self);
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

like(
    exception {
        $foo->bar( [ baz => [ 1, 2, 3 ] ], { baz => { isa => 'ArrayRef' } } );
    },
    qr/\QThe 'baz' parameter/,
    '... successfully re-used the parameter validation for this instance'
);

my $foo2 = Foo->new;
isa_ok( $foo2, 'Foo' );

is(
    exception {
        $foo2->bar(
            [ baz => [ 1, 2, 3 ] ],
            { baz => { isa => 'ArrayRef' } }
        );
    },
    undef,
    '... successfully applied the parameter validation'
);

like(
    exception {
        $foo2->bar( [ baz => 1 ], { baz => { isa => 'Int' } } );
    },
    qr/\QThe 'baz' parameter/,
    '... successfully re-used the parameter validation for this instance'
);

is(
    exception {
        $foo->bar( [ baz => 1 ], { baz => { isa => 'Int' } } );
    },
    undef,
    '... successfully applied the parameter validation (just checking)'
);

done_testing();
