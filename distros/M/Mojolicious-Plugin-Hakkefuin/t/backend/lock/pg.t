use Mojo::Base -strict;

use Test::More;
use Mojo::Hakkefuin::Test::Backend;
use Mojo::Home;
use IO::Socket::INET;
use Mojo::URL;

plan skip_all => 'set TEST_ONLINE_pg to enable this test'
  unless $ENV{TEST_ONLINE_pg};

my $dsn   = $ENV{TEST_ONLINE_pg};
my $url   = Mojo::URL->new($dsn);
my $probe = IO::Socket::INET->new(
  PeerAddr => $url->host,
  PeerPort => $url->port || 5432,
  Proto    => 'tcp',
  Timeout  => 2
);
plan skip_all => 'postgres socket not reachable' unless $probe;
$probe->close;

my $expires = 3600;
my ($btest, $backend, $data, $data_create, $data_read, $result, $r_update);

my $home = Mojo::Home->new();
my $path = $home->child(qw(t backend migrations lock-pg));
$path->make_path unless -d $path;

$btest
  = Mojo::Hakkefuin::Test::Backend->new(dsn => $dsn, dir => $path, via => 'pg');
$btest->load_backend;

$backend = $btest->backend;
$data    = 'lock-test';

note 'prepare table and data';
$backend->create_table;
$data_create = $btest->example_data($data);
$backend->create($data, $data_create->[1], $data_create->[2], $expires);
$data_read = $backend->read($data, $data_create->[1])->{data};

note 'set lock cookie and state';
my $lock_cookie = 'lock_cookie_test';
$r_update = $backend->upd_coolock($data_read->{$backend->id}, $lock_cookie);
$result   = {result => 1, code => 200, data => $lock_cookie};
is_deeply $r_update, $result, 'update lock cookie success';

$r_update = $backend->upd_lckstate($data_read->{$backend->id}, 1);
$result   = {result => 1, code => 200, data => 1};
is_deeply $r_update, $result, 'update lock state success';

$data_read = $backend->read($data, $data_create->[1])->{data};
is $data_read->{$backend->lock},        1,            'lock state stored';
is $data_read->{$backend->cookie_lock}, $lock_cookie, 'lock cookie stored';

note 'unset lock cookie and state';
$r_update = $backend->upd_coolock($data_read->{$backend->id}, 'no_lock');
$result   = {result => 1, code => 200, data => 'no_lock'};
is_deeply $r_update, $result, 'reset lock cookie success';

$r_update = $backend->upd_lckstate($data_read->{$backend->id}, 0);
$result   = {result => 1, code => 200, data => 0};
is_deeply $r_update, $result, 'reset lock state success';

$data_read = $backend->read($data, $data_create->[1])->{data};
is $data_read->{$backend->lock},        0,         'lock state cleared';
is $data_read->{$backend->cookie_lock}, 'no_lock', 'lock cookie cleared';

# Clean
$backend->drop_table if $backend->check_table->{result};
$path->remove_tree   if -d $path;

done_testing();
