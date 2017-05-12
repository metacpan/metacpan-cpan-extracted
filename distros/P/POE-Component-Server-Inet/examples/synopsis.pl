use strict;
use warnings;
use POE qw(Component::Server::Inet);

$|=1;

my $inetd = POE::Component::Server::Inet->spawn( options => { trace => 0 } );

my $echo = $inetd->add_tcp( port => 0, program => \&_echo );

print "Started echo server on port: $echo\n";

my $fake = $inetd->add_tcp( port => 0, program => \&_fake );

print "Started a 'fake' server on $fake\n";

my $fake2 = $inetd->add_tcp( port => 0, program => \&_fake2 );

print "Started another 'fake' server on $fake2\n";

$poe_kernel->run();
exit 0;

sub _echo {
  use FileHandle;
  autoflush STDOUT 1;
  while(<STDIN>) {
    print STDOUT $_;
  }
  return;
}

sub _fake {
  return;
}

sub _fake2 {
  sleep 10000000000;
  return;
}
