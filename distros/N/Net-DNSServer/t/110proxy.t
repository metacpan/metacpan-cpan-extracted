# Test if Net::DNSServer::Proxy functions correctly.
# NOTE: Network connectivity is required to pass this test.

use Test;
plan tests => 5;

use strict;
use Net::DNSServer;
use Net::DNSServer::Proxy;

# Everything compiles fine.
ok 1;

my $dig = `which dig 2>/dev/null`;

if (!$dig) {
  die "dig program needed for testing";
}

# Dig program found
chomp $dig;
ok 1;

# Hack to exit after one request
sub Net::DNSServer::post_process_request_hook {
  my $self = shift;
  $self->server_close();
}

# Make sure instantiation is successful
# using default settings.
my $resolver = new Net::DNSServer::Proxy;
ok $resolver;

# Always flush buffers before fork
$| = 1;

my $pid = fork();
if (!defined $pid) {
  die "Fork failed!";
}

my $test_port = 2053;

if (!$pid) {
  # Child starts server.

  # I hope this port isn't being used.
  local @ARGV
    =("--Pidfile" => "test.pid",
      "--port" => $test_port, 
      "--foreground" );
  # Avoid leaving stray servers hanging around.
  alarm(60);
  $SIG{ALRM} = sub {kill "TERM", $$};
  run Net::DNSServer {
    priority => [$resolver],
    port => $test_port,
  };
  # Never reaches here.
  exit;
}

# Make sure that the child server dies
eval q{
  END { kill "TERM", $pid };
};

# Give some time for the server to bind
sleep 2;

my $test = `dig \@127.0.0.1 . ns -p $test_port`;

# Dig actually ran
ok $test;

# Found at least one answer!
if ($test =~ /^\.\s+/m) {
  ok 1;
} else {
  die "dig failed:\n$test";
}
