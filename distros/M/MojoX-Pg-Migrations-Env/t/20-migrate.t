use Mojo::Base -strict, -signatures;

use lib 'lib';
use lib 'local/lib/perl5';

use Test2::V0;
use Mojo::File qw(path);
use Mojo::Pg;

use MojoX::Pg::Migrations::Env;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

my $pg     = Mojo::Pg->new( $ENV{TEST_ONLINE} );
my $schema = $pg->search_path->[0] or plan skip_all => 'TEST_ONLINE needs a search_path';

sub reset_schema
{
    $pg->db->query("DROP SCHEMA IF EXISTS $schema CASCADE");
    $pg->db->query("CREATE SCHEMA $schema");
}

my $fixtures = path('t/fixtures');

sub load ( $file, %env )
{
    return MojoX::Pg::Migrations::Env->new( pg => $pg, name => 'test', env => {%env} )->from_file( $fixtures->child($file) );
}

sub tables
{
    return [ sort map { $_->{tablename} }
          $pg->db->query( 'SELECT tablename FROM pg_tables WHERE schemaname = ?', $schema )->hashes->each ];
}

sub notes
{
    return $pg->db->query('SELECT note FROM notes ORDER BY id')->arrays->flatten->to_array;
}

subtest 'migrations without placeholders' => sub {
    reset_schema();
    my $m = load('plain.sql');
    is $m->active, 0, 'fresh schema';
    $m->migrate;
    is $m->active, 10,                      'at latest';
    is tables(),   [qw(a mojo_migrations)], 'tables created';
    is $pg->db->query('SELECT price, note FROM a ORDER BY id')->arrays->to_array, [ [ '$5', 'ten comes after two' ] ],
      'dollar signs in the sql are left alone';
    is $pg->db->query(q{SELECT add_tax(100)::int AS tax, label('x') AS label})->hash, { tax => 125, label => '$x$$' },
      'dollar quoted function bodies work';
    $m->migrate(0);
    is $m->active, 0,                     'back at zero';
    is tables(),   [qw(mojo_migrations)], 'tables dropped';
};

subtest 'migrate up with values from env' => sub {
    reset_schema();
    my $m = load( 'placeholders.sql', ENV_TEST_WHO => 'bob', ENV_TEST_GREETING => 'hi' );
    $m->migrate;
    is $m->active, 2,                                 'at latest';
    is notes(),    [ 'up 1 as bob', 'up 2 for bob' ], 'values from env are in the applied sql';
    is $pg->db->query(q{SELECT greet('you') AS greeting})->hash->{greeting}, 'hi you',
      'placeholder inside a dollar quoted function body is replaced';
};

subtest 'migrate up with fallbacks' => sub {
    reset_schema();
    my $m = load('placeholders.sql');
    $m->migrate(1);
    is $m->active, 1,                  'at version 1';
    is notes(),    ['up 1 as nobody'], 'fallback is in the applied sql';

    $m = load( 'placeholders.sql', ENV_TEST_WHO => 'bob' );
    $m->migrate;
    is $m->active,                                                           2,           'at latest';
    is $pg->db->query(q{SELECT greet('you') AS greeting})->hash->{greeting}, 'hello you', 'fallback inside a function body';
};

subtest 'migrate down with values from env' => sub {
    reset_schema();
    load( 'placeholders.sql', ENV_TEST_WHO => 'bob' )->migrate;
    my $m = load( 'placeholders.sql', ENV_TEST_WHO => 'carol' );
    $m->migrate(1);
    is $m->active, 1, 'at version 1';
    is notes(), [ 'up 1 as bob', 'up 2 for bob', 'down 2 for carol, literally ${ENV_TEST_WHO}' ],
      'down sql has the value in effect on the way down, and the escaped placeholder as a literal';
    $m->migrate(0);
    is $m->active, 0,                     'back at zero';
    is tables(),   [qw(mojo_migrations)], 'tables dropped';
};

subtest 'missing variable applies nothing' => sub {
    reset_schema();
    my $m = load('placeholders.sql');
    like dies { $m->migrate },
      qr/^Migration 2 needs environment variable ENV_TEST_WHO, which is not set and has no fallback at \Q${\__FILE__}\E line/,
      'migrate dies, names the version and the variable and blames the caller';
    is $m->active, 0,                     'still at zero';
    is tables(),   [qw(mojo_migrations)], 'migration 1 on the same path was not applied';

    $m->migrate(1);
    like dies { load( 'placeholders.sql', ENV_TEST_WHO => 'bob' )->migrate->env( {} )->migrate(0) },
      qr/^Migration 2 needs environment variable ENV_TEST_WHO/, 'migrate down dies';
    is $m->active, 2,                                    'still at version 2';
    is notes(),    [ 'up 1 as nobody', 'up 2 for bob' ], 'nothing was rolled back';
};

$pg->db->query("DROP SCHEMA IF EXISTS $schema CASCADE");

done_testing;
