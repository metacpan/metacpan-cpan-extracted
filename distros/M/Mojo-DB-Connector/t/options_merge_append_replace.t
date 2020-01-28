use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

test_options($ENV{TEST_MYSQL}) if $ENV{TEST_MYSQL};
test_options($ENV{TEST_POSTGRESQL}) if $ENV{TEST_POSTGRESQL};

done_testing;

sub test_options {
    my $connection_string = shift;

    $ENV{MOJO_DB_CONNECTOR_URL} = $connection_string;
    test_default_options();
    test_append_options();
    test_merge_options();
    test_replace_options();
}

sub test_default_options {
    my $connector = Mojo::DB::Connector->new;
    my $connection = $connector->new_connection;
    my $db = $connection->db;
    ok !$db->dbh->{PrintError}, 'PrintError not set';

    $connector = Mojo::DB::Connector->new(
        options => [PrintError => 1],
    );
    $connection = $connector->new_connection;
    $db = $connection->db;
    is $db->dbh->{PrintError}, 1, 'PrintError overrode';

    $connector = Mojo::DB::Connector->new(
        options => [PrintError => 0],
    );
    $connection = $connector->new_connection;
    $db = $connection->db;
    ok !$db->dbh->{PrintError}, 'PrintError not set';

    $connection = $connector->new_connection(options => [PrintError => 1]);
    $db = $connection->db;
    is $db->dbh->{PrintError}, 1, 'PrintError overrode';
}

sub test_append_options {
    my $connector = Mojo::DB::Connector->new;
    my $connection = $connector->new_connection;
    my $db = $connection->db;
    ok !$db->dbh->{PrintError}, 'PrintError not set';
    is $db->dbh->{RaiseError}, 1, 'RaiseError is 1';

    $connector = Mojo::DB::Connector->new(
        options => [PrintError => 1],
    );
    $connection = $connector->new_connection(options => [RaiseError => 0]);
    $db = $connection->db;
    is $db->dbh->{PrintError}, 1, 'PrintError used';
    ok !$db->dbh->{RaiseError}, 'RaiseError appended';
}

sub test_merge_options {
    my $connector = Mojo::DB::Connector->new;
    my $connection = $connector->new_connection;
    my $db = $connection->db;
    ok !$db->dbh->{PrintError}, 'PrintError not set';
    is $db->dbh->{RaiseError}, 1, 'RaiseError is 1';

    $connector = Mojo::DB::Connector->new(
        options => [PrintError => 0, RaiseError => 1],
    );
    $connection = $connector->new_connection(options => {PrintError => 1, RaiseError => 0});
    $db = $connection->db;
    is $db->dbh->{PrintError}, 1, 'PrintError merged';
    ok !$db->dbh->{RaiseError}, 'RaiseError merged';
}

sub test_replace_options {
    my $connector = Mojo::DB::Connector->new;
    my $connection = $connector->new_connection;
    my $db = $connection->db;
    ok !$db->dbh->{PrintError}, 'PrintError not set';
    is $db->dbh->{RaiseError}, 1, 'RaiseError is 1';

    $connector = Mojo::DB::Connector->new(
        options => [PrintError => 1],
    );
    $connection = $connector->new_connection(options => [RaiseError => 0], replace_options => 1);
    $db = $connection->db;
    ok !$db->dbh->{PrintError}, 'PrintError not set';
    ok !$db->dbh->{RaiseError}, 'RaiseError not set';
}
