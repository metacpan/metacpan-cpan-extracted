use strict;
use warnings;

use Test::More tests => 24;

{
    package MyApp;
    use Moose;
    use MooseX::EasyAcc;

    has 'name' => (
        is => 'rw',
        isa => 'Str'
    );
    # This creates methods: name, set_name, has_name

    has 'supernumber' => (
        is => 'ro',
        isa => 'Int',
    );
    # This creates methods: supernumber, _set_supernumber, has_supernumber

    has '_superhero_name' => (
        is => 'ro',
        isa => 'Str'
    );
    # This creates methods: _superhero_name, _set__superhero_name, _has__superhero_name

    has 'superpower' => (
        is => 'ro',
        isa => 'Str',
        predicate => 'is_awesome',
    );
    # This creates methods: superpower, _set_supernumber, is_awesome
   
    has 'nemisis' => (
        is => 'rw',
        isa => 'MyApp',
        predicate => 'is_loved',
        reader => 'best_friend',
    );
    # This creates methods: best_friend , set_nemisis, is_loved
    # and so on....
    
}

    
ok ( MyApp->can('name'), 'MyApp->name exists');
ok ( MyApp->can('set_name'), 'MyApp->set_name exists');
ok ( MyApp->can('has_name'), 'MyApp->has_name exists');

ok ( MyApp->can('supernumber'), 'MyApp->supernumber exists');
ok ( MyApp->can('_set_supernumber'), 'MyApp->_set_supernumber exists');
ok ( MyApp->can('has_supernumber'), 'MyApp->has_supernumber exists');
ok ( ! MyApp->can('set_supernumber'), 'MyApp->set_supernumber does not exist');

ok ( MyApp->can('_superhero_name'), 'MyApp->_superhero_name exists');
ok ( MyApp->can('_set__superhero_name'), 'MyApp->_set__superhero_name exists');
ok ( MyApp->can('_has__superhero_name'), 'MyApp->_has__superhero_name exists');
ok (! MyApp->can('superhero_name'), 'MyApp->superhero_name does not exist');
ok (! MyApp->can('set_superhero_name'), 'MyApp->set_superhero_name does not exist');
ok (! MyApp->can('has_superhero_name'), 'MyApp->has_superhero_name does not exist');
ok (! MyApp->can('_set_superhero_name'), 'MyApp->_set_superhero_name does not exist');
ok (! MyApp->can('_has_superhero_name'), 'MyApp->_has_superhero_name does not exist');

ok ( MyApp->can('superpower'), 'MyApp->superpower exists');
ok ( MyApp->can('_set_supernumber'), 'MyApp->_set_supernumber exists');
ok ( MyApp->can('is_awesome'), 'MyApp->is_awesome exists');
ok ( ! MyApp->can('has_superpower'), 'MyApp->has_superpower does not exist');

ok ( MyApp->can('best_friend'), 'MyApp->best_friend exists');
ok ( MyApp->can('set_nemisis'), 'MyApp->set_nemisis exists');
ok ( MyApp->can('is_loved'), 'MyApp->is_loved exists');
ok (! MyApp->can('has_nemisis'), 'MyApp->has_nemisis does not exist');
ok (! MyApp->can('nemisis'), 'MyApp->nemisis does not exist');

