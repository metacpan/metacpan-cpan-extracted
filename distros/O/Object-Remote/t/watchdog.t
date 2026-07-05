use strictures 1;
use Test::More;
use Errno qw(EPIPE);

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::Connection;
use Object::Remote::FromData;

$SIG{ALRM} = sub {  fail("Watchdog killed remote process in time"); die "test failed" };

my $conn = Object::Remote->connect("-", watchdog_timeout => 1);

my $remote = HangClass->new::on($conn);

isa_ok($remote, 'Object::Remote::Proxy');
is($remote->alive, 1, "Hanging test object is running");

alarm(3);

eval { $remote->hang };

my $pipe_error = do {
  local $! = EPIPE;
  "$!";
};

like($@, qr/^Object::Remote connection lost: (?:eof|.*\Q$pipe_error\E)/, "Correct error message");

done_testing;

__DATA__

package HangClass;

use Moo;

sub alive {
  return 1;
}

sub hang {
  while(1) {
    sleep(1);
  }
}
