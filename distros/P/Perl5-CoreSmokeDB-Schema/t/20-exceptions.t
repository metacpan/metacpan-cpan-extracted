#! perl -I. -w
use t::Test::abeltje;

use File::Spec::Functions qw( catfile );
use File::Temp qw( tempdir );

use Perl5::CoreSmokeDB::Schema;

my $tmpdir = tempdir(CLEANUP => 1);
my $dbname = catfile($tmpdir, "p5sdb_test_$$.db");
{

    my $schema = Perl5::CoreSmokeDB::Schema->connect(
        "dbi:SQLite:dbname=$dbname", "", "", { ignore_version => 1 }
    );
    $schema->deploy;

    my $dbversion = $schema->resultset('TsgatewayConfig')->find({ name => 'dbversion' });
    # Higher version in the Database is not a problem:
    $schema->txn_do(
        sub {
            my $new_version = $dbversion->value + 1;
            $dbversion->update({value => $new_version});
            $dbversion->discard_changes;
        }
    );

    is(
        $dbversion->value,
        $Perl5::CoreSmokeDB::Schema::SCHEMAVERSION + 1,
        "new db version " . $dbversion->value
    );
    $schema->storage->disconnect;
}
{
    my $schema;
    lives_ok(
        sub { $schema = Perl5::CoreSmokeDB::Schema->connect("dbi:SQLite:dbname=$dbname"); },
        "We can connect with the higher db-version"
    );

    my $dbversion = $schema->resultset('TsgatewayConfig')->find({ name => 'dbversion' });
    is(
        $dbversion->value,
        $Perl5::CoreSmokeDB::Schema::SCHEMAVERSION + 1,
        "new db version " . $dbversion->value
    );
    # Lower version in the Database is a problem:
    $schema->txn_do(
        sub {
            my $new_version = $Perl5::CoreSmokeDB::Schema::SCHEMAVERSION - 1;
            $dbversion->update({value => $new_version});
            $dbversion->discard_changes;
        }
    );

    is(
        $dbversion->value,
        $Perl5::CoreSmokeDB::Schema::SCHEMAVERSION - 1,
        "new db version " . $dbversion->value
    );
    $schema->storage->disconnect;
}
{
    my $schema;
    my $exception = exception {
        $schema = Perl5::CoreSmokeDB::Schema->connect("dbi:SQLite:dbname=$dbname");
    };

    isa_ok($exception, 'Perl5::CoreSmokeDB::Schema::VersionMismatchException');
}

{ ok(unlink($dbname), "tmpdb($dbname) removed"); }

{
    # Use a driver that is part of the DBI, but not supported.
    my $schema = Perl5::CoreSmokeDB::Schema->connect(
        "dbi:Mem:", "", "", { ignore_version => 1 }
    );
    my $exception = exception { $schema->deploy };
    isa_ok($exception, 'Perl5::CoreSmokeDB::Schema::DBDriverMismatchExeption');
}

abeltje_done_testing();
