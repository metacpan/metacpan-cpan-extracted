## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    use MooseX::Params::Validate;

    sub foo {
        my ( $x, $y ) = validated_list(
            \@_,
            x => { isa => 'Any' },
            y => { isa => 'Any' },
        );

        return { x => $x, y => $y };
    }

    sub bar {
        my %p = validated_hash(
            \@_,
            x => { isa => 'Any' },
            y => { isa => 'Any' },
        );

        return \%p;
    }
}

is_deeply(
    foo( x => 42, y => 84 ),
    { x => 42, y => 84 },
    'validated_list accepts a plain hash'
);

is_deeply(
    foo( { x => 42, y => 84 } ),
    { x => 42, y => 84 },
    'validated_list accepts a hash reference'
);

is_deeply(
    bar( x => 42, y => 84 ),
    { x => 42, y => 84 },
    'validated_hash accepts a plain hash'
);

is_deeply(
    bar( { x => 42, y => 84 } ),
    { x => 42, y => 84 },
    'validated_hash accepts a hash reference'
);

done_testing();
