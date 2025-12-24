use Mojo::Base -strict;

use Test::More;
use Mojo::Hakkefuin::Test::Backend;
use Mojo::Home;
use IO::Socket::INET;
use Mojo::URL;

my ($btest, $db, $backend);

my $home = Mojo::Home->new();
my $path = $home->child(qw(t backend migrations));

$btest = Mojo::Hakkefuin::Test::Backend->new(via => 'sqlite', dir => $path);
unless (-d $btest->dir) { mkdir $btest->dir }

$backend = $btest->backend;
$db      = $backend->sqlite->db;

ok $db->ping, 'SQLite connected';

SKIP: {
  skip 'set TEST_ONLINE_mariadb to enable this test', 1
    unless $ENV{TEST_ONLINE_mariadb};

  my $murl  = Mojo::URL->new($ENV{TEST_ONLINE_mariadb});
  my $probe = IO::Socket::INET->new(
    PeerAddr => $murl->host,
    PeerPort => $murl->port || 3306,
    Proto    => 'tcp',
    Timeout  => 2
  );
  skip 'mariadb socket not reachable', 1 unless $probe;
  $probe->close;

  $btest->via('mariadb');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'MariaDB connected';
}

SKIP: {
  skip 'set TEST_ONLINE_mariadb to enable this test', 1
    unless $ENV{TEST_ONLINE_mariadb};

  my $murl  = Mojo::URL->new($ENV{TEST_ONLINE_mariadb});
  my $probe = IO::Socket::INET->new(
    PeerAddr => $murl->host,
    PeerPort => $murl->port || 3306,
    Proto    => 'tcp',
    Timeout  => 2
  );
  skip 'mariadb socket not reachable', 1 unless $probe;
  $probe->close;

  $btest->via('mysql');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'Use the keyword "mysql" to connect to MariaDB';
}

SKIP: {
  skip 'set TEST_ONLINE_pg to enable this test', 1 unless $ENV{TEST_ONLINE_pg};

  my $pgurl = Mojo::URL->new($ENV{TEST_ONLINE_pg});
  my $probe = IO::Socket::INET->new(
    PeerAddr => $pgurl->host,
    PeerPort => $pgurl->port || 5432,
    Proto    => 'tcp',
    Timeout  => 2
  );
  skip 'postgres socket not reachable', 1 unless $probe;
  $probe->close;

  $btest->via('pg');
  $btest->dsn($ENV{TEST_ONLINE_pg});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->pg->db;

  ok $db->ping, 'PostgreSQL connected';
}

SKIP: {
  skip 'set TEST_ONLINE_mariadb and TEST_ONLINE_pg to enable this test', 1
    unless $ENV{TEST_ONLINE_mariadb} && $ENV{TEST_ONLINE_pg};

  note 'Test multiple switch backend';

  $btest->via('sqlite');
  unless (-d $btest->dir) { mkdir $btest->dir }
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->sqlite->db;

  ok $db->ping, 'SQLite connected';

  $btest->via('mariadb');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'Switch to MariaDB';

  $btest->via('mysql');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'Switch to MariaDB by "mysql" keyword';

  $btest->via('pg');
  $btest->dsn($ENV{TEST_ONLINE_pg});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->pg->db;

  ok $db->ping, 'Switch to PostgreSQL';
}

# Clean
$path->remove_tree;

done_testing();
