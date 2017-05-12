use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Data::Dumper;
use DBI;

use_ok('Pgtools::Config_diff');
use Pgtools::Config_diff;

my @args = ("192.168.33.21:5432:postgres::", "192.168.33.22:5432:postgres::");
my $s = Pgtools::Config_diff->new({"argv" => \@ARGV});

ok $s;
isa_ok($s, "Pgtools::Config_diff");


# ///////////////
# get_db_config
# ///////////////

# DB mock
subtest 'DB mock' => sub {
    my @data_conf = (
        ['name', 'setting'],
        ['max_connections', 50],
        ['shared_buffers', 32276],
        ['tcp_keepalives_idle', 3],
        ['wal_buffers', 1024]
    );
    my $dbh = DBI->connect('DBI:Mock:', '', '');
    $dbh->{mock_add_resultset} = \@data_conf;

    my $mock_db = Test::MockObject->new;
    $mock_db->set_always('dbh', $dbh);

    my $ret = $s->get_db_config($mock_db);

    is($ret->{max_connections}, 50);
    is($ret->{shared_buffers}, 32276);
    is($ret->{tcp_keepalives_idle}, 3);
    is($ret->{wal_buffers}, 1024);
    done_testing;
};

# ///////////////
# get_different_key
# ///////////////

# DB mock
subtest 'version' => sub {
    my @data_version = (
        ['version'],
        ['PostgreSQL 9.3.9 on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 4.4.7 20120313 (Red Hat 4.4.7-4), 64-bit']
    );

    my $dbh = DBI->connect('DBI:Mock:', '', '');
    $dbh->{mock_add_resultset} = \@data_version;

    my $mock_db = Test::MockObject->new;
    $mock_db->set_always('dbh', $dbh);
    my $ret = $s->get_db_version($mock_db);

    is($ret, '9.3.9');
    done_testing;
};



done_testing;

