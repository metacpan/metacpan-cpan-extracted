package t::sock;
use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);
use base qw(Exporter);
use File::Path qw(mkpath rmtree);
use Time::HiRes qw(sleep);
use IO::Socket::INET;

our @EXPORT_OK    = qw(setup teardown);
our $SOCK_TIMEOUT = 5;
our $TEST_TIMEOUT = 30;

sub setup {
  my $port = 56987;
  my $path = "/tmp/memcacheq_test_$PID";
  mkpath($path);
  $ENV{TEST_NMQ_PATH} = $path;

  if(my $pid = fork) {
    $ENV{TEST_NMQ_PID} = $pid;
    #########
    # parent
    #
    my $time = time;
    my $sock;
    while($time < time+$SOCK_TIMEOUT &&
	  !defined $sock) {
      $sock = IO::Socket::INET->new(
				    PeerAddr => 'localhost',
				    PeerPort => $port,
				    Proto    => 'tcp',
				   );
      sleep 0.5;
    }
  } else {
    #########
    # child
    #
    exec(qw(memcacheq -u nobody -p), $port, qw(-H), $path);

    # FIN
  }

  #########
  # attempt to trap any runaway children
  #
  $SIG{ALRM} = \&teardown;
  $SIG{INT}  = \&teardown;
  $SIG{TERM} = \&teardown;
  $SIG{KILL} = \&teardown;
  alarm $TEST_TIMEOUT;

  return $port;
}

sub teardown {
  if($ENV{TEST_NMQ_PID}) {
    kill 9, $ENV{TEST_NMQ_PID};
    wait;
  }
  rmtree($ENV{TEST_NMQ_PATH});
  return 1;
}

1;
