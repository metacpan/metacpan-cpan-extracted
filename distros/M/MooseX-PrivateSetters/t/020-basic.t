use strict;
use warnings;

#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use Data::Dump 'pp';

use Test::More tests => 23;

{
    package Standard;

    use Moose;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

ok(   Standard->can('thing'),        'Standard->thing() exists' );
ok( ! Standard->can('set_thing'),    'Standard->set_thing() does not exist' );
ok(   Standard->can('_private'),     'Standard->_private() exists' );
ok( ! Standard->can('_set_private'), 'Standard->_set_private() does not exist' );

{
    package PS;

    use Moose;
    use MooseX::PrivateSetters;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

ok( PS->can('thing'),        'PS->thing() exists' );
ok( PS->can('_set_thing'),   'PS->set_thing() exists' );
ok( PS->can('_private'),     'PS->_private() exists' );
ok( PS->can('_set_private'), 'PS->_set_private() exists' );

{
    package PS2;

    # load order does matter
    use Moose;
    use MooseX::PrivateSetters;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

ok( PS2->can('thing'),        'PS2->thing() exists' );
ok( PS2->can('_set_thing'),   'PS2->set_thing() exists' );
ok( PS2->can('_private'),     'PS2->_private() exists' );
ok( PS2->can('_set_private'), 'PS2->_set_private() exists' );

{
    package PS3;

    use Moose;
    use MooseX::PrivateSetters;

    has 'ro'     => ( is => 'ro' );
    has 'thing'  => ( is => 'rw', reader => 'get_thing' );
    has 'thing2' => ( is => 'rw', writer => 'set_it' );
}

ok(   PS3->can('ro'),         'PS3->ro exists' );
ok( ! PS3->can('set_ro'),     'PS3->set_ro does not exist' );
ok(   PS3->can('thing'),      'PS3->thing exists' );
ok( ! PS3->can('set_thing'),  'PS3->set_thing does not exist' );
ok(   PS3->can('thing2'),     'PS3->thing2 exists' );
ok( ! PS3->can('set_thing2'), 'PS3->set_thing2 does not exist' );
ok(   PS3->can('set_it'),     'PS3->set_it does exist' );

{
    package PS4;

    use Moose;
    use MooseX::PrivateSetters;

    has bare => ( is => 'bare' );
}

ok( ! PS4->can('bare'),     'PS4->bare does not exist' );
ok( ! PS4->can('set_bare'), 'PS4->set_bare does not exist' );

{
    package PS5;

    use Moose;
    use MooseX::PrivateSetters;

    has '__private' => ( is => 'rw' );
}

ok( PS5->can('__private'),     'PS5->__private exists' );
ok( PS5->can('_set__private'), 'PS5->_set__private exists' );
