use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package OverloadingRole;
    use MooseX::Role::WithOverloading;

    use overload
        q{""}    => 'stringify',
        fallback => 1;

    sub stringify { 'moo' }
}

{
    package MyRole;
    use Moose::Role;

    has hitid => ( is => 'ro' );

    # Note ordering here. If metaclass reinitialization nukes attributes, we are screwed..
    with 'OverloadingRole';
}

{
    package Class;
    use Moose;

    with 'MyRole';
}

my $i = Class->new( hitid => 21 );

is("$i", 'moo', 'overloading works');
can_ok($i, 'hitid' );
is($i->hitid, 21, 'Attribute works');

done_testing();
