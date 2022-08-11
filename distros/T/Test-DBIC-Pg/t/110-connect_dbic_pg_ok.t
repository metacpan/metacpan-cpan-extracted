#! perl -I. -w
use Test::Tester;
use t::Test::abeltje;

use Test::DBIC::Pg;

plan skip_all => "set TEST_ONLINE to enable this test" unless $ENV{TEST_ONLINE};

my $dbname = "_test_dbic_pg_$$";

{
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_pg_ok('DummySchema');
        },
        {
            ok   => 1,
            name => "the schema ISA DummySchema"
        }
    );
    # Nog wat testjes op $schema

   # test the drop function
   check_test(
       sub {  drop_dbic_pg_ok() },
       {
           ok => 1,
           name => "$dbname DROPPED",
       }
   );
}

{
    my ($td, $schema);
    check_test(
        sub {
            $td = Test::DBIC::Pg->new(
                schema_class => 'DummySchema',
                TMPL_DB => 'postgres',
            );
            $schema = $td->connect_dbic_ok();
        },
        {
            ok   => 1,
            name => "the schema ISA DummySchema"
        }
    );
    # Nog wat testjes op $schema

   # test the drop function
   check_test(
       sub {  $td->drop_dbic_ok() },
       {
           ok => 1,
           name => "$dbname DROPPED",
       }
   );
}

{
    check_test(
        sub {
            my $schema = connect_dbic_pg_ok('DummySchema');
        },
        {
            ok   => 1,
            name => 'the schema ISA DummySchema',
        },
        "connect_dbic_pg_ok()"
    );
    check_test(
        sub { drop_dbic_pg_ok(); },
        {
            ok => 1,
            name => qq{_test_dbic_pg_$$ DROPPED},
        },
        "drop_dbic_pg_ok()"
    );
}

{
    my $dbname = "_test_dbic_pg_${$}_x";
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_pg_ok(
                'DummySchema',
                { dsn => "dbi:Pg:dbname=$dbname" },
            );
        },
        {
            ok => 1,
            name => "the schema ISA DummySchema",
        },
        "connect_dbic_pg_ok($dbname)"
    );
    is($schema->[0], "dbi:Pg:dbname=$dbname", "$dbname");

    check_test(
        sub { drop_dbic_pg_ok() },
        {
            ok => 1,
            name => "$dbname DROPPED",
        }
    );
}
{
    my $dbname = "WillNotEverExistInThisDistro";
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_pg_ok(
                'DummySchema',
                { dsn => "dbi:Pg:dbname=$dbname" },
            );
        },
        {
            ok => 1,
            name => "the schema ISA DummySchema",
        },
        "connect_dbic_pg_ok($dbname)"
    );
    is($schema->[0], "dbi:Pg:dbname=$dbname", "$dbname");

    check_test(
        sub { drop_dbic_pg_ok() },
        {
            ok => 1,
            name => "$dbname DROPPED",
        }
    );
}

{
    my $schema;
    my ($premature, @results) = run_tests(
        sub {
            $schema = connect_dbic_pg_ok('DummyNocompile');
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
    my $schema;
    my ($premature, @results) = run_tests(
        sub {
            $schema = connect_dbic_pg_ok('DummyNoconnect');
        }
    );
    like(
        $premature,
        qr{Error connecting 'DummyNoconnect' to 'dbi:Pg:dbname=_test_dbic_pg_$$'},
        "DummyNoconnect->connect(); fails"
    );
}

{
    my $schema;
    my ($premature, @results) = run_tests(
        sub {
            require DummySchema;
            no warnings 'redefine', 'once';
            local *DummySchema::deploy = sub { die "no deploy" };
            $schema = connect_dbic_pg_ok('DummySchema');
        }
    );
    like(
        $premature,
        qr{Error deploying 'DummySchema' to 'dbi:Pg:dbname=_test_dbic_pg_$$': no deploy},
        "DummySchema->deploy(); fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $callback = sub { die "error in callback" };
            my $schema = connect_dbic_pg_ok('DummySchema', undef, $callback);
        }
    );
    like(
        $premature,
        qr{Error in pre-deploy-hook: error in callback at $0},
        "calling callback fails"
    );
}

{
    my $dbname = "_test_dbic_pg_${$}_y";
    my $schema;
    check_test(
        sub {
            my $callback = sub { return 1; };
            $schema = connect_dbic_pg_ok(
                'DummySchema',
                { dsn => "dbi:Pg:dbname=$dbname" },
                $callback
            );
        },
        {
            ok   => 1,
            name => 'the schema ISA DummySchema',
        },
        "connect_dbic_pg_ok()"
    );
    check_test(
        sub { drop_dbic_pg_ok(); },
        {
            ok   => 1,
            name => "$dbname DROPPED",
        }
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            my $t = Test::DBIC::Pg->new(
                schema_class    => 'DummySchema',
                pre_deploy_hook => sub { die "In-PreDeployHook" },
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

abeltje_done_testing();
