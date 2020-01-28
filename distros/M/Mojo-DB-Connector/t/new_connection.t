use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;
use Mojo::URL;

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

test_new_connection($ENV{TEST_MYSQL}) if $ENV{TEST_MYSQL};
test_new_connection($ENV{TEST_POSTGRESQL}) if $ENV{TEST_POSTGRESQL};

done_testing;

sub test_new_connection {
    my $connection_string = shift;

    $ENV{MOJO_DB_CONNECTOR_URL} = $connection_string;
    my $connector = Mojo::DB::Connector->new;

    my $connection = $connector->new_connection;
    is $connection->db->query('SELECT 42')->array->[0], 42, 'succesfully connected';

    my $scheme = Mojo::URL->new($connection_string)->scheme;
    if (grep { $scheme eq $_ } 'mysql', 'mariadb') {
        $connector->strict_mode(0);

        my $nonstrict_connection = $connector->new_connection;
        is $nonstrict_connection->db->query('SELECT 42')->array->[0], 42, 'succesfully connected';
    }
}
