# this test is needed because we also need to test role 
# stuff with an empty RoleAllowed table.
use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More; 
{

    use strict;
    use warnings;

    use Test::DBIx::Class {
        schema_class => 'OpusVL::AppKit::Schema::AppKitAuthDB',
    }, 'Role', 'RoleAllowed', 'User';

    fixtures_ok { 
        Role => [
            [qw/role/],
            ['admin'],
            ['user'],
            ['guest'],
            ['supervisor'],
        ],
        User => [
            [qw/username password email name tel/],
            [ 'colin', 'colin', 'colin@opusvl.com', 'Colin' ,'555333' ],
            [ 'rich', 'rich', 'rich@opusvl.com', 'Rich' ,'555333' ],
            [ 'nuria', 'nuria', 'nuria@opusvl.com', 'Nuria' ,'555333' ],
            [ 'macky', 'macky', 'macky@opusvl.com', 'Stuart' ,'555333' ],
        ],
    }, 'Loaded data for testing';

    my $admin       = Role->find({ role => 'admin'});
    my $user        = Role->find({ role => 'user'});
    my $guest       = Role->find({ role => 'guest'});
    my $supervisor  = Role->find({ role => 'supervisor'});

    ok my $colin = User->find({ name => 'Colin' }), 'Found user';
    ok my $nuria = User->find({ name => 'Nuria' }), 'Found user';
    ok my $macky = User->find({ name => 'Stuart' }), 'Found user';
    ok my $rich = User->find({ name => 'Rich' }), 'Found user';
    $colin->set_roles($user);
    $rich->set_roles($admin);
    $nuria->set_roles($supervisor);
    $macky->set_roles($admin, $supervisor, $user);


    my $roles = $rich->roles_modifiable;
    is $roles->count, 4, 'Should be allowed to modify all the roles';

    my $sup_roles = $nuria->roles_modifiable;
    is $sup_roles->count, 4, 'Should be allowed to modify all the roles ';

    my $mroles = $macky->roles_modifiable;
    is $mroles->count, 4, 'Should be allowed to modify all the roles';

    my $no_roles = $colin->roles_modifiable;
    is $no_roles->count, 4, 'No fancy config so should be able to modify everythign';

    done_testing;
}

