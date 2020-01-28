use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;
use Mojo::URL;

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

test_new_connection_overrides($ENV{TEST_MYSQL}) if $ENV{TEST_MYSQL};
test_new_connection_overrides($ENV{TEST_POSTGRESQL}) if $ENV{TEST_POSTGRESQL};

done_testing;

sub test_new_connection_overrides {
    my $connection_string = shift;

    my $connector = Mojo::DB::Connector->new(
        scheme => 'bogus',
        userinfo => 'user:pass',
        host => 'myhost.com',
        port => 9999,
        database => 'mydb',
        options => [PrintError => 0],
    );
    is $connector->scheme, 'bogus', 'bogus is default scheme';
    is $connector->userinfo, 'user:pass', 'user:pass string is default userinfo';
    is $connector->host, 'myhost.com', 'myhost.com is default host';
    is $connector->port, 9999, '9999 is default port';
    is $connector->database, 'mydb', 'mydb is default database';
    is_deeply $connector->options, [PrintError => 0], q{[PrintError => 0] is default options};
    is $connector->url, undef, 'undef is default url';
    is $connector->strict_mode, 1, '1 is default strict_mode';

    my $url = Mojo::URL->new($connection_string);
    $url->path->leading_slash(undef);
    my $connection = $connector->new_connection(
        (map { $_ => $url->$_ } qw(scheme userinfo host port)),
        database => $url->path,
        options => [PrintError => 1],
        strict_mode => 0,
        replace_options => 1,
    );
    my $db = $connection->db;
    is $db->query('SELECT 42')->array->[0], 42, 'succesfully connected';
    is $db->dbh->{PrintError}, 1, 'PrintError overrode';

    if (grep { $url->scheme eq $_ } 'mysql', 'mariadb') {
        ok !$connection->{strict_mode}, q{connection isn't strict};
    }
}
