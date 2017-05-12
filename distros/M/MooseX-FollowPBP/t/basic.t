use strict;
use warnings;

use Test::More;


{
    package Standard;

    use Moose;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

{
    package PBP;

    use Moose;
    use MooseX::FollowPBP;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

{
    package PBP3;

    use Moose;
    use MooseX::FollowPBP;

    has 'ro' => ( is => 'ro' );
    has 'thing' => ( is => 'rw', reader => 'thing' );
    has 'thing2' => ( is => 'rw', writer => 'set_it' );
}

{
    package PBP4;

    use Moose;
    use MooseX::FollowPBP;

    has 'bare' => ( is => 'bare' );
}


ok( ! Standard->can('get_thing'), 'Standard->get_thing() does not exist' );
ok( ! Standard->can('set_thing'), 'Standard->set_thing() does not exist' );
ok( ! Standard->can('_get_private'), 'Standard->_get_private() does not exist' );
ok( ! Standard->can('_set_private'), 'Standard->_set_private() does not exist' );

ok( PBP->can('get_thing'), 'PBP->get_thing() exists' );
ok( PBP->can('set_thing'), 'PBP->set_thing() exists' );
ok( PBP->can('_get_private'), 'PBP->_get_private() exists' );
ok( PBP->can('_set_private'), 'PBP->_set_private() exists' );

ok( PBP3->can('get_ro'), 'PBP3->get_ro exists' );
ok( ! PBP3->can('set_ro'), 'PBP3->set_ro does not exist' );
ok( ! PBP3->can('get_thing'), 'PBP3->get_thing does not exist' );
ok( ! PBP3->can('set_thing'), 'PBP3->set_thing does not exist' );
ok( ! PBP3->can('get_thing2'), 'PBP3->get_thing2 does not exist' );
ok( ! PBP3->can('set_thing2'), 'PBP3->set_thing2 does not exist' );

ok( !PBP4->can('get_bare'), 'is => bare attribute is respected' );
ok( !PBP4->can('set_bare'), 'is => bare attribute is respected' );

done_testing();
