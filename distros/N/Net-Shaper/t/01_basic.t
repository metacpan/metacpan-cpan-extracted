use Test;
BEGIN { plan tests => 5 };
use Net::Shaper;
ok(1);

use IO::Socket;

# we need three processes; an echo server, a tunnel and a client.
# this process will be the client.  we first spawn off the server.
my $PORT = 15157;
my($serverPid, $tunnelPid);
unless ($serverPid = fork()) {
  my $server = IO::Socket::INET->new(LocalPort => $PORT, Proto => 'tcp', Listen => 1, Reuse => 1);
  my $client = $server->accept();
  while (<$client>) {
    print $client $_;
  }
  exit;
}

sleep 1;

# now spawn off the tunnel
unless ($tunnelPid = fork()) {
  my $shaper = Net::Shaper->new(LocalPort => $PORT + 1, PeerAddr => "localhost:$PORT", Bps => 5);
  $shaper->run();
  exit;
}

sleep 1;

# now we can try to talk to the server through the tunnel
my $client = IO::Socket::INET->new(PeerAddr => 'localhost:' . ($PORT + 1), Proto => 'tcp');

my $start = time;

# send 10 bytes to server
print $client "123456789\n";

# now receive that data
my $data = <$client>;

ok($data, "123456789\n");

# make sure it took long enough
my $now = time;
ok($now - $start > 3);

# now stop the tunnel and server
kill("TERM" => $serverPid, $tunnelPid);

my $pid = waitpid($serverPid, 0);
ok($pid, $serverPid);

$pid = waitpid($tunnelPid, 0);
ok($pid, $tunnelPid);
