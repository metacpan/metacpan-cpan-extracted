#! perl -I. -w
use t::Test::abeltje;

use Test::DBIC::Pg;

ok(defined(&connect_dbic_pg_ok), "connect_dbic_pg_ok is EXPORTed");
ok(defined(&drop_dbic_pg_ok), "drop_dbic_pg_ok is EXPORTed");

{
    my $tdp = Test::DBIC::Pg->new(
        schema_class => 'DummySchema',
    );
    isa_ok($tdp, "Test::DBIC::Pg");
    is_deeply(
        $tdp->dbi_connect_info,
        {
            dsn => "dbi:Pg:dbname=_test_dbic_pg_$$",
        },
        "dbi_connect_info set"
    );
}

{
    my $tdp = Test::DBIC::Pg->new(
        schema_class => 'DummySchema',
        dbi_connect_info => {
            dsn      => "dbi:Pg:dbname=blah_blah_blah_$$",
            username => 'postgres',
            password => undef,
            options  => {
                PrintWarn  => 1,
                RaiseWarn  => 1,
                PrintError => 1,
                RaiseError => 1,
            },
            },
    );
    isa_ok($tdp, "Test::DBIC::Pg");
    is_deeply(
        $tdp->dbi_connect_info,
        {
            dsn      => "dbi:Pg:dbname=blah_blah_blah_$$",
            username => 'postgres',
            password => undef,
            options  => {
                PrintWarn  => 1,
                RaiseWarn  => 1,
                PrintError => 1,
                RaiseError => 1,
            },
        },
        "dbi_connect_info set"
    );
}

abeltje_done_testing();
