use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose qw( with_immutable );
use Test::Deep;

plan skip_all => 'This module requires Moose 2.0 to work from roles.'
    if Moose->VERSION < 1.9900;

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

my @classes = qw( Standard );
with_immutable {

    my $obj;
    is(
        exception { $obj = Standard->new( thing => 1, bad => 99 ) },
        undef,
        'slurpy constructor doesn\'t die on unknown params',
    );
    cmp_deeply($obj->slurpy, { bad => 99 }, 'slurpy attr grabs unknown param');
}
@classes;

done_testing();
