#! perl

# These tests were copied nearly verbatim from the Moosex::StrictConstructor
# distribution.

use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

{

    package Standard;

    use Moo;

    has 'thing' => ( is => 'rw' );
}

{

    package Stricter;

    use Moo;
    use MooX::StrictConstructor;

    has 'thing' => ( is => 'rw' );
}

{

    package Subclass;

    use Moo;
    use MooX::StrictConstructor;

    extends 'Stricter';

    has 'size' => ( is => 'rw' );
}

{

    package StrictSubclass;

    use Moo;

    extends 'Stricter';

    has 'size' => ( is => 'rw' );
}

{

    package OtherStrictSubclass;

    use Moo;
    use MooX::StrictConstructor;

    extends 'Standard';

    has 'size' => ( is => 'rw' );
}

{

    package Tricky;

    use Moo;
    use MooX::StrictConstructor;

    has 'thing' => ( is => 'rw' );

    sub BUILD {
        my $self   = shift;
        my $params = shift;

        delete $params->{spy};
    }
}

{

    package TrickyBuildArgs;

    use Moo;
    use MooX::StrictConstructor;

    has 'thing' => ( is => 'rw' );

    sub BUILDARGS {
        my ($self, %params) = @_;
        delete $params{spy};
        return \%params;
    }
}

{

    package InitArg;

    use Moo;
    use MooX::StrictConstructor;

    has 'thing' => ( is => 'rw', 'init_arg' => 'other' );
    has 'size'  => ( is => 'rw', 'init_arg' => undef );
}

is( exception { Standard->new( thing => 1, bad => 99 ) },
    undef, 'standard Moo class ignores unknown params' );

like(
    exception { Stricter->new( thing => 1, bad => 99 ) },
    qr/unknown attribute.+: bad/,
    'strict constructor blows up on unknown params'
);

is( exception { Subclass->new( thing => 1, size => 'large' ) },
    undef, 'subclass constructor handles known attributes correctly' );

like(
    exception { Subclass->new( thing => 1, bad => 99 ) },
    qr/unknown attribute.+: bad/,
    'subclass correctly recognizes bad attribute'
);

is( exception { StrictSubclass->new( thing => 1, size => 'large', ) },
    undef,
    q{subclass that doesn't use strict constructor handles known attributes correctly}
);

like(
    exception { StrictSubclass->new( thing => 1, bad => 99 ) },
    qr/unknown attribute.+: bad/,
    q{subclass that doesn't use strict correctly recognizes bad attribute}
);

is( exception { OtherStrictSubclass->new( thing => 1, size => 'large', ) },
    undef,
    q{strict subclass from parent that doesn't use strict constructor handles known attributes correctly}
);

like(
    exception { OtherStrictSubclass->new( thing => 1, bad => 99 ) },
    qr/unknown attribute.+: bad/,
    q{strict subclass from parent that doesn't use strict correctly recognizes bad attribute}
);

TODO: {
    local $TODO = "Moose trick.  Doesn't work 'cuz my code runs before object built.";
    is( exception { Tricky->new( thing => 1, spy => 99 ) },
        undef,
        'can work around strict constructor by deleting params in BUILD()' );
}

is( exception { TrickyBuildArgs->new( thing => 1, spy => 99 ) },
    undef,
    'can work around strict constructor by deleting params in BUILDARGS()'
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

is( exception { InitArg->new( other => 1 ) },
    undef, 'InitArg works when given proper init_arg' );

done_testing();
