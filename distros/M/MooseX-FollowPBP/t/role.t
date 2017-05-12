use strict;
use warnings;

use Test::More;

use Moose ();

plan skip_all => 'This test requires Moose 1.9900+'
    unless $Moose::VERSION ge '1.9900';

{
    package Role::SAA;

    use Moose::Role;
    use MooseX::FollowPBP;

    has 'foo'  => ( is => 'rw' );
    has '_bar' => ( is => 'rw' );
}

{
    package Class;

    use Moose;

    with 'Role::SAA';

    has 'thing'    => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

can_ok( 'Class', 'thing' );
ok( ! Class->can('set_thing') );
can_ok( 'Class', '_private' );
ok( ! Class->can('_set_private') );

can_ok( 'Class', qw( get_foo set_foo _get_bar _set_bar ) );

done_testing();
