## no critic (Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable, Moose::RequireCleanNamespace)
use strict;
use warnings;

use Test::Fatal;
use Test::Moose qw( with_immutable );
use Test::More 0.88;

{
    package Standard;

    use Moose;

    has 'thing' => ( is => 'rw' );
}

{
    package Stricter;

    use Moose;
    use MooseX::StrictConstructor;

    has 'thing' => ( is => 'rw' );
}

{
    package Subclass;

    use Moose;
    use MooseX::StrictConstructor;

    extends 'Stricter';

    has 'size' => ( is => 'rw' );
}

{
    package StrictSubclass;

    use Moose;

    extends 'Stricter';

    has 'size' => ( is => 'rw' );
}

{
    package OtherStrictSubclass;

    use Moose;
    use MooseX::StrictConstructor;

    extends 'Standard';

    has 'size' => ( is => 'rw' );
}

{
    package Tricky;

    use Moose;
    use MooseX::StrictConstructor;

    has 'thing' => ( is => 'rw' );

    sub BUILD {
        my $self   = shift;
        my $params = shift;

        delete $params->{spy};
    }
}

{
    package InitArg;

    use Moose;
    use MooseX::StrictConstructor;

    has 'thing' => ( is => 'rw', 'init_arg' => 'other' );
    has 'size'  => ( is => 'rw', 'init_arg' => undef );
}

my @classes
    = qw( Standard Stricter Subclass StrictSubclass OtherStrictSubclass Tricky InitArg );

with_immutable {
    is(
        exception { Standard->new( thing => 1, bad => 99 ) }, undef,
        'standard Moose class ignores unknown params'
    );

    like(
        exception { Stricter->new( thing => 1, bad => 99 ) },
        qr/unknown attribute.+: bad/,
        'strict constructor blows up on unknown params'
    );

    is(
        exception { Subclass->new( thing => 1, size => 'large' ) }, undef,
        'subclass constructor handles known attributes correctly'
    );

    like(
        exception { Subclass->new( thing => 1, bad => 99 ) },
        qr/unknown attribute.+: bad/,
        'subclass correctly recognizes bad attribute'
    );

    is(
        exception { StrictSubclass->new( thing => 1, size => 'large', ) },
        undef,
        q{subclass that doesn't use strict constructor handles known attributes correctly}
    );

    like(
        exception { StrictSubclass->new( thing => 1, bad => 99 ) },
        qr/unknown attribute.+: bad/,
        q{subclass that doesn't use strict correctly recognizes bad attribute}
    );

    is(
        exception { OtherStrictSubclass->new( thing => 1, size => 'large', ) }
        ,
        undef,
        q{strict subclass from parent that doesn't use strict constructor handles known attributes correctly}
    );

    like(
        exception { OtherStrictSubclass->new( thing => 1, bad => 99 ) },
        qr/unknown attribute.+: bad/,
        q{strict subclass from parent that doesn't use strict correctly recognizes bad attribute}
    );

    is(
        exception { Tricky->new( thing => 1, spy => 99 ) }, undef,
        'can work around strict constructor by deleting params in BUILD()'
    );

    like(
        exception { Tricky->new( thing => 1, agent => 99 ) },
        qr/unknown attribute.+: agent/,
        'Tricky still blows up on unknown params other than spy'
    );

    like(
        exception { InitArg->new( thing => 1 ) },
        qr/unknown attribute.+: thing/,
        'InitArg blows up with attribute name'
    );

    like(
        exception { InitArg->new( size => 1 ) },
        qr/unknown attribute.+: size/,
        'InitArg blows up when given attribute with undef init_arg'
    );

    is(
        exception { InitArg->new( other => 1 ) }, undef,
        'InitArg works when given proper init_arg'
    );
}
@classes;

done_testing();
