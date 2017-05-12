use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose qw( with_immutable );

{
    package DoubleUsage;

    use Moose;
    use MooseX::SlurpyConstructor;

    has slurpy => (
        is      => 'ro',
        slurpy  => 1,
    );
}

pass('adding single slurpy attribute succeeds');

like(
    exception {
        package DoubleUsage;
        has slurpy2 => (
            is      => 'ro',
            slurpy  => 1,
        );
    },
    qr/\QAttempting to use slurpy attribute slurpy2 in class DoubleUsage that already has a slurpy attribute (slurpy)\E/,
    'expected error when trying to add two slurpy attributes to a class',
);

{
    package Role;

    use Moose::Role;
    use MooseX::SlurpyConstructor;

    has thing  => ( is => 'rw' );
    has slurpy => ( is => 'ro', slurpy => 1 );
}

{
    package Standard;

    use Moose;
    with 'Role';

    has 'thing' => ( is => 'rw' );
}

like(
    exception {
        package Standard;
        use MooseX::SlurpyConstructor;
        has slurpy2 => ( is => 'ro', slurpy => 1 );
    },
    qr/\QAttempting to use slurpy attribute slurpy2 in class Standard that already has a slurpy attribute (slurpy)\E/,
    'cannot add a second slurpy attribute in the class when one is already in the role',
);


done_testing();
