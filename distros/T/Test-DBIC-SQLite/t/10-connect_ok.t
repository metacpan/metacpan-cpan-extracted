#! perl -I. -w
use utf8;
use Test::Tester;
use t::Test::abeltje;
use File::Temp qw( tempdir );
use File::Spec::Functions qw( catfile );

use Test::DBIC::SQLite;

{
    check_test(
        sub {
            my $schema = connect_dbic_sqlite_ok('DummySchema');
        },
        {
            ok   => 1,
            name => 'the schema ISA DummySchema',
        },
        "connect_dbic_sqlite_ok()"
    );
    check_test(
        sub { drop_dbic_sqlite_ok(); },
        {
            ok => 1,
            name => ':memory: DROPPED',
        },
        "drop_dbic_sqlite_ok()"
    );
}

{
    my $dbname = $0;
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_sqlite_ok(
                'DummySchema', $dbname
            );
        },
        {
            ok => 1,
            name => "the schema ISA DummySchema",
        },
        "connect_dbic_sqlite_ok($dbname)"
    );
    is($schema->[0], "dbi:SQLite:dbname=$dbname", "$dbname");
}
{
    my $dbname = "WillNotEverExistInThis.distro";
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_sqlite_ok(
                'DummySchema', $dbname
            );
        },
        {
            ok => 1,
            name => "the schema ISA DummySchema",
        },
        "connect_dbic_sqlite_ok($dbname)"
    );
    is($schema->[0], "dbi:SQLite:dbname=$dbname", "$dbname");
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $schema = connect_dbic_sqlite_ok('DummyNocompile');
        }
    );
    like(
        $premature,
        qr{Error\ loading\ 'DummyNocompile':
          \ DummyNocompile.pm\ did\ not\ return\ a\ true\ value}x,
        "require DummyNoCompile; fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $schema = connect_dbic_sqlite_ok('DummyNoconnect');
        }
    );
    like(
        $premature,
        qr{Error connecting 'DummyNoconnect' to 'dbi:SQLite:dbname=:memory:'},
        "DummyNoconnect->connect(); fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            no warnings 'redefine', 'once';
            local *DummySchema::deploy = sub { die "no deploy" };
            my $schema = connect_dbic_sqlite_ok('DummySchema');
        }
    );
    like(
        $premature,
        qr{Error deploying 'DummySchema' to 'dbi:SQLite:dbname=:memory:': no deploy},
        "DummySchema->deploy(); fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $callback = sub { die "error in callback" };
            my $schema = connect_dbic_sqlite_ok('DummySchema', undef, $callback);
        }
    );
    like(
        $premature,
        qr{Error in post-connect-hook: error in callback at $0},
        "calling callback fails"
    );
}

{
    check_test(
        sub {
            my $callback = sub { return 1; };
            my $schema = connect_dbic_sqlite_ok('DummySchema', undef, $callback);
        },
        {
            ok   => 1,
            name => 'the schema ISA DummySchema',
        },
        "connect_dbic_sqlite_ok()"
     );
}

{
    my ($premature, @results) = run_tests(
        sub {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            my $t = Test::DBIC::SQLite->new(
                schema_class => 'DummySchema',
                pre_deploy_hook => sub { die "In-PreDeployHook\n" },
            );
            my $schema = $t->connect_dbic_ok();
        },
    );
    like(
        $premature,
        qr{^Error in pre-deploy-hook: In-PreDeployHook},
        "Premature test fail in pre-deploy-hook"
    );
}

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbname = catfile($tmpdir, "test-dbic-sqlite-$$");
    check_test(
        sub {
            local $Test::DBIC::SQLite::LeaveCreatedDatabases = 0;
            my $t = Test::DBIC::SQLite->new(
                schema_class      => 'Music::Schema',
                dbi_connect_info  => $dbname,
                post_connect_hook => \&populate_db,
            );
            my $schema = $t->connect_dbic_ok();
            $schema->storage->disconnect();
        },
        {
            ok => 1,
            name => "the schema ISA Music::Schema",
        },
        "$dbname auto-dropped"
    );
    ok(! -e $dbname, "database auto-dropped");
}

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbname = catfile($tmpdir, "test-dbic-sqlite-$$");
    check_test(
        sub {
            local $Test::DBIC::SQLite::LeaveCreatedDatabases = 1;
            my $t = Test::DBIC::SQLite->new(
                schema_class      => 'Music::Schema',
                dbi_connect_info  => $dbname,
                post_connect_hook => \&populate_db,
            );
            my $schema = $t->connect_dbic_ok();
            $schema->storage->disconnect();
        },
        {
            ok => 1,
            name => "the schema ISA Music::Schema",
        },
        "$dbname not auto-dropped"
    );
    ok( -d $tmpdir, "tempdir exists");
    ok( -e $dbname, "database $dbname exists");
}

abeltje_done_testing();

sub populate_db {
    my $schema = shift;
    use Music::FromYAML;
    artist_from_yaml($schema, catfile('t', 'madness.yml'))
}
