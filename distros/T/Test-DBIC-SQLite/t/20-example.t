#! perl -I. -w
use utf8;
use Test::Tester;
use t::Test::abeltje;

use File::Temp qw( tempfile );
use Test::DBIC::SQLite;

{
    my ($schema, $td);
    # This is the only Test::Tester thing we do for an actual database
    # the rest of the tests is there to check that the hooks worked
    check_test(
        sub {
            $td = Test::DBIC::SQLite->new(
                schema_class      => 'Music::Schema',
                pre_deploy_hook   => \&pre_deploy_hook,
                post_connect_hook => \&populate_db,
            );
            $schema = $td->connect_dbic_ok();
        },
        {
            ok   => 1,
            name => "the schema ISA Music::Schema",
        },
        "\$td = Test::DBIC::SQLite->new(); \$td->connect_dbic_ok()"
    );

    my $broadway = $schema->resultset('Album')->search(
        { name => 'Broadway the Hard Way' }
    )->first;
    isa_ok($broadway, 'Music::Schema::Result::Album');

    # First check that the function is available via DBI
    my $uc_last = $schema->storage->dbh->selectrow_hashref(
        "SELECT uc_last('uc_last') AS freturn"
    );
    is_deeply(
        $uc_last,
        { freturn => 'uc_lasT' },
        "Successfully implemented a function during PRE-DEPLOY"
    ) or diag(explain($uc_last));

    # Now integrate that function with DBIx::Class
    my $thing = $schema->resultset('AlbumArtist')->search(
        { name => 'Frank Zappa' },
        { columns => [ { ul_name => \'uc_last(name)' } ] }
    )->first;
    is(
        $thing->get_column('ul_name'),
        'frank zappA',
        "SELECT uc_last(name) AS ul_name FROM ...; works!"
    );

    check_test(
        sub { $td->drop_dbic_ok(); },
        {
            ok => 1,
            name => ':memory: DROPPED',
        },
        "\$td->drop_dbic_ok()"
    );
}

{
    my ($fh, $filename) = tempfile();
    my ($schema, $td);
    check_test(
        sub {
            close($fh); unlink($filename); # risquee
            $td = Test::DBIC::SQLite->new(
                schema_class      => 'Music::Schema',
                dbi_connect_info  => $filename,
                post_connect_hook => \&populate_db,
            );
            $schema = $td->connect_dbic_ok();
        },
        {
            ok => 1,
        },
        "Create SQLite in a file"
    );
    my $broadway = $schema->resultset('Album')->search(
        { name => 'Broadway the Hard Way' }
    )->first;
    isa_ok($broadway, 'Music::Schema::Result::Album');

    $schema->storage->disconnect();
    ok(! $schema->storage->connected(), "Disconnected from storage");
    check_test(
        sub { $td->drop_dbic_ok(); },
        {
            ok => 1,
            name => "$filename DROPPED",
        },
        "\$td->drop_dbic_ok()"
    );
    ok(! -e $filename, "File gone...");

    # trigger an error
    my ($premature) = run_tests(
        sub { $td->drop_dbic_ok(); },
        {
            ok => 1,
            name => "$filename DROPPED",
        }
    );
    like(
        $premature,
        qr{^Could not unlink.+?: $!},
        "Cannot drop non existing database"
    )
}

abeltje_done_testing();

sub pre_deploy_hook {
    my $schema = shift;
    my $dbh = $schema->storage->dbh;
    $dbh->sqlite_create_function(
        'uc_last',
        1,
        sub { my ($str) = @_; $str =~ s{(.*)(.)$}{\L$1\U$2}; return $str },
    );
}

sub populate_db {
    my $schema = shift;
    use Music::FromYAML;
    artist_from_yaml($schema, 't/zappa.yml')
}
