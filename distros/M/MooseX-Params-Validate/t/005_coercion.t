## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

# Note that setting coerce => 1 for the Num type tests that we don't try to do
# coercions for a type which doesn't have any coercions.
{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Validate;

    subtype 'Size' => as 'Int' => where { $_ >= 0 };

    coerce 'Size' => from 'ArrayRef' => via { scalar @{$_} };

    sub bar {
        my $self   = shift;
        my %params = validated_hash(
            \@_,
            size1  => { isa => 'Size', coerce => 1 },
            size2  => { isa => 'Size', coerce => 0 },
            number => { isa => 'Num',  coerce => 1 },
        );
        [ $params{size1}, $params{size2}, $params{number} ];
    }

    # added to test 'optional' on validated_hash
    sub baropt {
        my $self   = shift;
        my %params = validated_hash(
            \@_,
            size1  => { isa => 'Size', coerce => 1, optional => 1 },
            size2  => { isa => 'Size', coerce => 0, optional => 1 },
            number => { isa => 'Num',  coerce => 1, optional => 1 },
        );
        [ $params{size1}, $params{size2}, $params{number} ];
    }

    sub baz {
        my $self = shift;
        my ( $size1, $size2, $number ) = validated_list(
            \@_,
            size1  => { isa => 'Size', coerce => 1 },
            size2  => { isa => 'Size', coerce => 0 },
            number => { isa => 'Num',  coerce => 1 },
        );
        [ $size1, $size2, $number ];
    }

    sub quux {
        my $self = shift;
        my ( $size1, $size2, $number ) = validated_list(
            \@_,
            size1  => { isa => 'Size', coerce => 1, optional => 1 },
            size2  => { isa => 'Size', coerce => 0, optional => 1 },
            number => { isa => 'Num',  coerce => 1, optional => 1 },
        );
        [ $size1, $size2, $number ];
    }

    sub ran_out {
        my $self = shift;
        my ( $size1, $size2, $number ) = pos_validated_list(
            \@_,
            { isa => 'Size', coerce => 1, optional => 1 },
            { isa => 'Size', coerce => 0, optional => 1 },
            { isa => 'Num',  coerce => 1, optional => 1 },
        );
        [ $size1, $size2, $number ];
    }
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );

is_deeply(
    $foo->bar( size1 => 10, size2 => 20, number => 30 ),
    [ 10, 20, 30 ],
    'got the return value right without coercions'
);

is_deeply(
    $foo->bar( size1 => [ 1, 2, 3 ], size2 => 20, number => 30 ),
    [ 3, 20, 30 ],
    'got the return value right with coercions for size1'
);

like(
    exception { $foo->bar( size1 => 30, size2 => [ 1, 2, 3 ], number => 30 ) }
    ,
    qr/\QThe 'size2' parameter/, '... the size2 param cannot be coerced'
);

like(
    exception { $foo->bar( size1 => 30, size2 => 10, number => 'something' ) }
    ,
    qr/\QThe 'number' parameter/,
    '... the number param cannot be coerced because there is no coercion defined for Num'
);

is_deeply(
    $foo->baz( size1 => 10, size2 => 20, number => 30 ),
    [ 10, 20, 30 ],
    'got the return value right without coercions'
);

is_deeply(
    $foo->baz( size1 => [ 1, 2, 3 ], size2 => 20, number => 30 ),
    [ 3, 20, 30 ],
    'got the return value right with coercions for size1'
);

like(
    exception { $foo->baz( size1 => 30, size2 => [ 1, 2, 3 ], number => 30 ) }
    ,
    qr/\QThe 'size2' parameter/, '... the size2 param cannot be coerced'
);

like(
    exception { $foo->baz( size1 => 30, size2 => 10, number => 'something' ) }
    ,
    qr/\QThe 'number' parameter/,
    '... the number param cannot be coerced'
);

is_deeply(
    $foo->baropt( size2 => 4 ),
    [ undef, 4, undef ],
    '... validated_hash does not try to coerce keys which are not provided'
);

is_deeply(
    $foo->quux( size2 => 4 ),
    [ undef, 4, undef ],
    '... validated_list does not try to coerce keys which are not provided'
);

is_deeply(
    $foo->ran_out( 1, 2, 3 ),
    [ 1, 2, 3 ],
    'got the return value right without coercions'
);

is_deeply(
    $foo->ran_out( [1], 2, 3 ),
    [ 1, 2, 3 ],
    'got the return value right with coercion for the first param'
);

like(
    exception { $foo->ran_out( [ 1, 2 ], [ 1, 2 ] ) },
    qr/\QParameter #2/,
    '... did not attempt to coerce the second parameter'
);

is_deeply(
    $foo->ran_out(),
    [ undef, undef, undef ],
    'did not try to coerce non-existent parameters'
);

done_testing();
