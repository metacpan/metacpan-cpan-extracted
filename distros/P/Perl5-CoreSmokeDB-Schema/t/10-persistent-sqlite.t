#! perl -I. -w
use t::Test::abeltje;

use File::Temp 'tempdir';
use File::Spec::Functions 'catfile';
use JSON;
use Test::DBIC::SQLite;

my $tmp = tempdir(CLEANUP => 1);
my $dbname = catfile($tmp, "p5sdb-test-$$.sqlite");

my $t = Test::DBIC::SQLite->new(
    schema_class => 'Perl5::CoreSmokeDB::Schema',
    dbi_connect_info => $dbname,
);

note("Testing clean deploy with sql-funcion");
{
    my $schema = $t->connect_dbic_ok();

    my $plevel = $schema->storage->dbh->selectall_arrayref(
        'SELECT git_describe_as_plevel(?)',
        undef,
        'v5.37.2-42-g03840a1d3f'
    );
    is($plevel->[0][0], '5.037002zzz042', "sql-git_describe_as_plevel $plevel->[0][0]")
        or diag(explain($plevel));

    $schema->storage->disconnect;
}

note("Testing persistency of sql-function");
{
    my $schema = $t->connect_dbic_ok();

    my $plevel = $schema->storage->dbh->selectall_arrayref(
        'SELECT git_describe_as_plevel(?)',
        undef,
        'v5.37.2-448-g03840a1d3f'
    );
    is($plevel->[0][0], '5.037002zzz448', "sql-git_describe_as_plevel $plevel->[0][0]")
        or diag(explain($plevel));

    $schema->storage->disconnect;
}

$t->drop_dbic_ok();

abeltje_done_testing();
