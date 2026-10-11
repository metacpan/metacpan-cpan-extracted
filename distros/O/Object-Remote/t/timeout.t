use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;
my $timeout_factor = $ENV{PERL_TEST_TIME_OUT_FACTOR} || 1;
$timeout_factor = 1 if $timeout_factor < 1;

use Object::Remote;
use Object::Remote::Connector::Local;

my $connector = Object::Remote::Connector::Local->new(
  timeout => (0.1 * $timeout_factor),
  perl_command => [ 'perl', '-e', "sleep(3*$timeout_factor)" ],
);

ok(!eval { $connector->connect; 1 }, 'Connection failed');

like($@, qr{timed out}, 'Connection failed with time out');

done_testing;
