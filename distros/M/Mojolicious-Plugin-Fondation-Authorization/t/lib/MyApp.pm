package MyApp;
use Mojo::Base 'Mojolicious', -signatures;
use File::Temp 'tempdir';

sub startup {
    my $self = shift;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";

    # Fondation resolves all dependencies from Authorization
    $self->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestAuthSchema',
                        workers      => 1,
                        quote_char   => '"',
                    },
                ],
            }},
            'Fondation::Authorization',
        ],
        actions => ['Templates'],
    });

    # ── Deploy tables from Result classes ─────────────────────────

    my $c      = $self->build_controller;
    my $schema = $c->schema;
    $schema->await($schema->deploy);

    # ── Populate test data (sync schema) ──────────────────────────

    my $be     = $c->backend_config;
    my $sync   = $be->{schema_class}->connect(
        $be->{dsn}, $be->{user}, $be->{pass}, $be->{dbi_attrs},
    );

    my $rs_user = $sync->resultset('User');
    unless ($rs_user->count) {
        $rs_user->create({
            username => 'alice',
            password => 'pass',
            email    => 'alice@example.com',
            active   => 1,
        });
        $rs_user->create({
            username => 'bob',
            password => 'pass',
            email    => 'bob@example.com',
            active   => 1,
        });
        $rs_user->create({
            username => 'carol',
            password => 'pass',
            email    => 'carol@example.com',
            active   => 1,
        });
    }

    my $rs_group = $sync->resultset('Group');
    unless ($rs_group->count) {
        $rs_group->create({ name => 'admins' });
        $rs_group->create({ name => 'editors' });
    }

    my $rs_perm = $sync->resultset('Perm');
    unless ($rs_perm->count) {
        $rs_perm->create({ name => 'user_create' });
        $rs_perm->create({ name => 'user_list' });
        $rs_perm->create({ name => 'group_create' });
    }

    my $rs_ug = $sync->resultset('UserGroup');
    unless ($rs_ug->count) {
        my $alice   = $sync->resultset('User')->find({ username => 'alice' });
        my $bob     = $sync->resultset('User')->find({ username => 'bob' });
        my $admins  = $sync->resultset('Group')->find({ name => 'admins' });
        my $editors = $sync->resultset('Group')->find({ name => 'editors' });
        $rs_ug->create({ user_id => $alice->id,  group_id => $admins->id });
        $rs_ug->create({ user_id => $alice->id,  group_id => $editors->id });
        $rs_ug->create({ user_id => $bob->id,    group_id => $editors->id });
    }

    my $rs_gp = $sync->resultset('GroupPerm');
    unless ($rs_gp->count) {
        my $admins  = $sync->resultset('Group')->find({ name => 'admins' });
        my $editors = $sync->resultset('Group')->find({ name => 'editors' });
        my $uc      = $sync->resultset('Perm')->find({ name => 'user_create' });
        my $ul      = $sync->resultset('Perm')->find({ name => 'user_list' });
        my $gc      = $sync->resultset('Perm')->find({ name => 'group_create' });
        $rs_gp->create({ group_id => $admins->id,  perm_id => $uc->id });
        $rs_gp->create({ group_id => $admins->id,  perm_id => $ul->id });
        $rs_gp->create({ group_id => $editors->id, perm_id => $gc->id });
    }

    # ── Test routes ──────────────────────────────────────────────

    my $r = $self->routes;

    $r->get('/has-perm/:perm')->to(cb => sub ($c) {
        my $perm = $c->param('perm');
        $c->render(json => {
            has_perm  => $c->check_perm($perm)  ? \1 : \0,
            has_group => $c->check_group($perm) ? \1 : \0,
        });
    });

    $r->get('/auth-status')->to(cb => sub ($c) {
        $c->render(json => {
            authenticated => $c->is_user_authenticated ? \1 : \0,
        });
    });

    # ── Protected routes (route conditions) ────────────────────────

    $r->get('/protected/perm')
      ->requires('fondation.perm' => 'user_create')
      ->to(cb => sub ($c) {
          $c->render(text => 'OK', status => 200);
      });

    $r->get('/protected/group')
      ->requires('fondation.group' => 'admins')
      ->to(cb => sub ($c) {
          $c->render(text => 'OK', status => 200);
      });
}

1;
