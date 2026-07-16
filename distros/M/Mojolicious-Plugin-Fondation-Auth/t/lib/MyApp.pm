package MyApp;
use Mojo::Base 'Mojolicious';
use File::Basename qw(dirname);
use Mojo::File;

sub startup {
    my $self = shift;

    my $test_dir = dirname(__FILE__);
    my $data_dir = Mojo::File->new("$test_dir/../data");
    $data_dir->make_path unless -d $data_dir;
    my $dbfile = "$data_dir/test.db";

    # Remove stale test database
    unlink $dbfile if -e $dbfile;

    # Load via Fondation
    $self->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestAuthSchema',
                        workers      => 1,
                    },
                ],
            }},
            'Fondation::Auth',
        ],
        actions => ['Templates'],
    });

    # ── Setup test database ──────────────────────────────────────────
    # Build a sync schema from the same backend config to create
    # the users table and insert the test user.

    my $c  = $self->build_controller;
    my $be = $c->backend_config;
    die "No backend config" unless $be;

    my $schema = $be->{schema_class}->connect(
        $be->{dsn}, $be->{user}, $be->{pass}, $be->{dbi_attrs},
    );

    # Create the users table using raw SQL (no SQL::Translator dependency)
    $schema->storage->dbh_do(sub {
        my ($storage, $dbh) = @_;
        $dbh->do(q{
            CREATE TABLE IF NOT EXISTS users (
                id         TEXT PRIMARY KEY,
                username   TEXT NOT NULL UNIQUE,
                password   TEXT NOT NULL,
                active     INTEGER NOT NULL DEFAULT 1,
                email      TEXT,
                created_at TEXT,
                updated_at TEXT
            )
        });
    });

    # Insert test user (only if table is empty)
    my $rs = $schema->resultset('User');
    unless ($rs->count) {
        $rs->create({
            id       => '00000000-0000-0000-0000-000000000001',
            username => 'test',
            password => 'pass',    # auto-hashed by Result::User insert()
            email    => 'test@example.com',
            active   => 1,
        });
    }

    # ── Routes ───────────────────────────────────────────────────────

    my $r = $self->routes;

    # Public route
    $r->get('/public')->to(cb => sub { shift->render(text => 'public content') });

    # Protected route — requires authentication
    $r->get('/protected')->to(cb => sub {
        my $c = shift;
        if ($c->current_user) {
            $c->render(text => 'Protected content');
        }
        else {
            $c->render(text => 'Access denied', status => 403);
        }
    });
}

1;
