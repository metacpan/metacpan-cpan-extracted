use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote;
use Object::Remote::Connector::Local;

my $connector = Object::Remote::Connector::Local->new(
  timeout => 0.1,
  perl_command => [ 'perl', '-e', 'sleep 3' ],
);

ok(!eval { $connector->connect; 1 }, 'Connection failed');

like($@, qr{timed out}, 'Connection failed with time out');

done_testing;
