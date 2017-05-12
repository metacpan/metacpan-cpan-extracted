
use Test::More tests => 3;
use Test::Exception;
use Opsview::StatusAPI;

my $api;

dies_ok(sub {
  $api = Opsview::StatusAPI->new();
}, 'Passing no host dies');

$api = Opsview::StatusAPI->new('host' => '127.0.0.1');

dies_ok(sub {
  $api->hostgroup(1);
}, 'Request with no user or pass');

$api = Opsview::StatusAPI->new('user' => 'user', 'password' => 'password', 'host' => '127.0.0.1');

throws_ok(sub {
  $api->host
}, qr/must specify host/);

