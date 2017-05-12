use strict;
use warnings;

use Test::More;

{

    package Standard;

    use Moose;

    has 'thing'    => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

{

    package SAA;

    use Moose;
    use MooseX::SemiAffordanceAccessor;

    has 'thing'    => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

{

    package SAA3;

    use Moose;
    use MooseX::SemiAffordanceAccessor;

    has 'ro'     => ( is => 'ro' );
    has 'thing'  => ( is => 'rw', reader => 'get_thing' );
    has 'thing2' => ( is => 'rw', writer => 'set_it' );
}

{

    package SAA4;

    use Moose;
    use MooseX::SemiAffordanceAccessor;

    has bare => ( is => 'bare' );
}

ok( Standard->can('thing'),      'Standard->thing() exists' );
ok( !Standard->can('set_thing'), 'Standard->set_thing() does not exist' );
ok( Standard->can('_private'),   'Standard->_private() exists' );
ok( !Standard->can('_set_private'),
    'Standard->_set_private() does not exist' );

ok( SAA->can('thing'),        'SAA->thing() exists' );
ok( SAA->can('set_thing'),    'SAA->set_thing() exists' );
ok( SAA->can('_private'),     'SAA->_private() exists' );
ok( SAA->can('_set_private'), 'SAA->_set_private() exists' );

ok( SAA3->can('ro'),          'SAA3->ro exists' );
ok( !SAA3->can('set_ro'),     'SAA3->set_ro does not exist' );
ok( SAA3->can('thing'),       'SAA3->thing exists' );
ok( !SAA3->can('set_thing'),  'SAA3->set_thing does not exist' );
ok( SAA3->can('thing2'),      'SAA3->thing2 exists' );
ok( !SAA3->can('set_thing2'), 'SAA3->set_thing2 does not exist' );
ok( SAA3->can('set_it'),      'SAA3->set_it does exist' );

ok( !SAA4->can('bare'),     'SAA4->bare does not exist' );
ok( !SAA4->can('set_bare'), 'SAA4->set_bare does not exist' );

done_testing();
