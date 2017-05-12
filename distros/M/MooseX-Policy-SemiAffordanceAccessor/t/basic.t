use strict;
use warnings;

use Test::More tests => 8;


{
    package Standard;

    use Moose;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}

{
    package SF;

    use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
    use Moose;

    has 'thing' => ( is => 'rw' );
    has '_private' => ( is => 'rw' );
}


ok( Standard->can('thing'), 'Standard->thing() exists' );
ok( ! Standard->can('set_thing'), 'Standard->set_thing() does not exist' );
ok( Standard->can('_private'), 'Standard->_private() exists' );
ok( ! Standard->can('_set_private'), 'Standard->_set_private() does not exist' );

ok( SF->can('thing'), 'SF->thing() exists' );
ok( SF->can('set_thing'), 'SF->set_thing() exists' );
ok( SF->can('_private'), 'SF->_private() exists' );
ok( SF->can('_set_private'), 'SF->_set_private() exists' );
