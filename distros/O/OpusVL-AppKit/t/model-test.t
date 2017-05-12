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
            ['client'],
            ['grunt'],
            ['superuser'],
        ],
        User => [
            [qw/username password email name tel/],
            [ 'colin', 'colin', 'colin@opusvl.com', 'Colin' ,'555333' ],
            [ 'rich', 'rich', 'rich@opusvl.com', 'Rich' ,'555333' ],
            [ 'nuria', 'nuria', 'nuria@opusvl.com', 'Nuria' ,'555333' ],
            [ 'macky', 'macky', 'macky@opusvl.com', 'Stuart' ,'555333' ],
            [ 'dom', 'dom', 'dom@opusvl.com', 'Dom', '321321' ],
            [ 'bill', 'bill', 'bill@opusvl.com', 'Bill', '321321' ],
        ],
    }, 'Loaded data for testing';

    my $admin       = Role->find({ role => 'admin'});
    my $user        = Role->find({ role => 'user'});
    my $guest       = Role->find({ role => 'guest'});
    my $supervisor  = Role->find({ role => 'supervisor'});
    my $grunt       = Role->find({ role => 'grunt'});
    my $client      = Role->find({ role => 'client'});
    my $superuser   = Role->find({ role => 'superuser'});

    ok my $colin = User->find({ name => 'Colin' }), 'Found user';
    ok my $nuria = User->find({ name => 'Nuria' }), 'Found user';
    ok my $macky = User->find({ name => 'Stuart' }), 'Found user';
    ok my $rich  = User->find({ name => 'Rich' }), 'Found user';
    ok my $dom   = User->find({ name => 'Dom' }), 'Found user';
    ok my $bill   = User->find({ name => 'Bill' }), 'Found user';

    $colin->set_roles($user);
    $rich->set_roles($admin);
    $nuria->set_roles($supervisor);
    $macky->set_roles($admin, $supervisor, $user);
    $dom->set_roles($client, $grunt);
    $bill->set_roles($superuser);

    ok !$superuser->can_change_any_role, 'Check flag not set';
    $superuser->can_change_any_role(1);
    ok $superuser->can_change_any_role, 'Check flag set';
    $superuser->can_change_any_role(0);
    ok !$superuser->can_change_any_role, 'Check flag not set';
    $superuser->can_change_any_role(1);
    ok $superuser->can_change_any_role, 'Check flag set';

    is $rich->roles_modifiable->count, 0, 'Shouldn\'t be able to access anything at the moment because there is a superuser and no roles have been permitted';

    $admin->add_to_roles_allowed_roles({ role_allowed => $admin });
    $admin->add_to_roles_allowed_roles({ role_allowed => $user });
    $admin->add_to_roles_allowed_roles({ role_allowed => $guest });
    $admin->add_to_roles_allowed_roles({ role_allowed => $supervisor });

    $supervisor->add_to_roles_allowed_roles({ role_allowed => $supervisor });
    $supervisor->add_to_roles_allowed_roles({ role_allowed => $user });
    $supervisor->add_to_roles_allowed_roles({ role_allowed => $guest });

    $client->add_to_roles_allowed_roles({ role_allowed => $client });
    $grunt->add_to_roles_allowed_roles({ role_allowed => $grunt });

    is $bill->roles_modifiable->count, Role->count, 'superuser should be able to modify all roles';

    my $roles = $rich->roles_modifiable;
    is $roles->count, 4, 'Should be allowed to modify all the roles';

    my $sup_roles = $nuria->roles_modifiable;
    is $sup_roles->count, 3, 'Should be allowed to modify all the roles bar admin';

    my $mroles = $macky->roles_modifiable;
    is $mroles->count, 4, 'Should be allowed to modify all the roles';

    my $no_roles = $colin->roles_modifiable;
    is $no_roles->count, 0, 'Shouldn\'t be able to modify any roles';

    my $dom_roles = $dom->roles_modifiable;
    is $dom_roles, 2, 'Should be able to modify the grunt and client roles';

    ok $bill->can_modify_user($dom->username), 'Should be able to modify user';
    ok !$dom->can_modify_user($bill->username), 'Shouln\'t be allowed to modify user';
    
    $admin->delete_related('roles_allowed_roles', { role_allowed => $guest->id } );
    
    is $rich->roles_modifiable->count, 3, 'Should only be able to modify 3 roles now';

    ok Role->find({ role => 'admin'});
    ok Role->find({ role => 'supervisor'});
    ok Role->find({ role => 'superuser'});
    ok Role->find({ role => 'guest'});
    ok Role->find({ role => 'user'});
    ok Role->find({ role => 'grunt'});
    ok Role->find({ role => 'client'});

    $rich->delete;
    $admin->delete;

    done_testing;
}
