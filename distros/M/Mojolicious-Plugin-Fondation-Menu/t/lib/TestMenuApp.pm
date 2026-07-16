package TestMenuApp;
use Mojo::Base 'Mojolicious', -signatures;
use File::Temp 'tempdir';

sub startup {
    my $self = shift;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";

    $self->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestMenuSchema',
                        workers      => 1,
                        quote_char   => '"',
                    },
                ],
            }},
            'Fondation::Authorization',
            'Fondation::Menu',
        ],
        actions => ['Templates'],
    });

    # Deploy tables
    my $c      = $self->build_controller;
    my $schema = $c->schema;
    $schema->await($schema->deploy);

    # Populate test data via sync schema
    my $be   = $c->backend_config;
    my $sync = $be->{schema_class}->connect(
        $be->{dsn}, $be->{user}, $be->{pass}, $be->{dbi_attrs},
    );

    # Users
    my $rs_user = $sync->resultset('User');
    unless ($rs_user->count) {
        $rs_user->create({ username => 'admin',  password => 'pass', email => 'admin@test.com',  active => 1 });
        $rs_user->create({ username => 'guest',  password => 'pass', email => 'guest@test.com',  active => 1 });
        $rs_user->create({ username => 'reader', password => 'pass', email => 'reader@test.com', active => 1 });
    }

    # Groups
    my $rs_group = $sync->resultset('Group');
    unless ($rs_group->count) {
        $rs_group->create({ name => 'admin' });
        $rs_group->create({ name => 'readers' });
    }

    # Permissions
    my $rs_perm = $sync->resultset('Perm');
    unless ($rs_perm->count) {
        $rs_perm->create({ name => 'menu_read' });
        $rs_perm->create({ name => 'extra_perm' });
    }

    # Group membership
    my $rs_ug = $sync->resultset('UserGroup');
    unless ($rs_ug->count) {
        my $admin_user  = $sync->resultset('User')->find({ username => 'admin' });
        my $reader_user = $sync->resultset('User')->find({ username => 'reader' });
        my $admin_grp   = $sync->resultset('Group')->find({ name => 'admin' });
        my $readers_grp = $sync->resultset('Group')->find({ name => 'readers' });
        $rs_ug->create({ user_id => $admin_user->id,  group_id => $admin_grp->id });
        $rs_ug->create({ user_id => $reader_user->id, group_id => $readers_grp->id });
    }

    # Group permissions
    my $rs_gp = $sync->resultset('GroupPerm');
    unless ($rs_gp->count) {
        my $admin_grp   = $sync->resultset('Group')->find({ name => 'admin' });
        my $readers_grp = $sync->resultset('Group')->find({ name => 'readers' });
        my $menu_read   = $sync->resultset('Perm')->find({ name => 'menu_read' });
        my $extra       = $sync->resultset('Perm')->find({ name => 'extra_perm' });
        # admin group: has menu_read + extra_perm
        $rs_gp->create({ group_id => $admin_grp->id,   perm_id => $menu_read->id });
        $rs_gp->create({ group_id => $admin_grp->id,   perm_id => $extra->id });
        # readers group: has menu_read only
        $rs_gp->create({ group_id => $readers_grp->id, perm_id => $menu_read->id });
    }

    # Menus for testing conditions
    my $rs_menu = $sync->resultset('Menu');
    unless ($rs_menu->count) {
        $rs_menu->create({ title => 'Admin only',   name => 'test', condition => 'group:admin',   sort_order => 1 });
        $rs_menu->create({ title => 'Perm required', name => 'test', condition => 'perm:menu_read', sort_order => 2 });
        $rs_menu->create({ title => 'Auth required', name => 'test', condition => 'auth',          sort_order => 3 });
        $rs_menu->create({ title => 'Public',        name => 'test', condition => '',               sort_order => 4 });
        $rs_menu->create({ title => 'Not auth',      name => 'test', condition => '!auth',          sort_order => 5 });
    }

    # Test route: evaluate all menu conditions
    my $r = $self->routes;
    $r->get('/menu-conditions')->to(cb => sub ($c) {
        $c->render(json => {
            authenticated      => $c->is_user_authenticated ? \1 : \0,
            admin_only         => $c->check_menu_condition('group:admin')          ? \1 : \0,
            perm_required      => $c->check_menu_condition('perm:menu_read')       ? \1 : \0,
            auth_required      => $c->check_menu_condition('auth')                 ? \1 : \0,
            public_menu        => $c->check_menu_condition('')                     ? \1 : \0,
            not_auth           => $c->check_menu_condition('!auth')                ? \1 : \0,
            mode_dev           => $c->check_menu_condition('mode:development')     ? \1 : \0,
            mode_prod          => $c->check_menu_condition('mode:production')      ? \1 : \0,
            mode_not_prod      => $c->check_menu_condition('mode:!production')     ? \1 : \0,
            compound           => $c->check_menu_condition('group:admin,mode:development') ? \1 : \0,
        });
    });

    $r->get('/auth-status')->to(cb => sub ($c) {
        $c->render(json => {
            authenticated => $c->is_user_authenticated ? \1 : \0,
        });
    });
}

1;
