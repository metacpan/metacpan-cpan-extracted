
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as perl test.pl'

#	query.t
#
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Dig;
use Socket;
use Net::NBsocket qw(
	dyn_bind
	open_udpNB
);
use Net::DNS::Codes qw(
	PACKETSZ
);
use Sys::Sig;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}
## test 2	create echo server
my $remotsock = open_udpNB();
print "could not open UDP socket for testing\nnot "
	unless $remotsock;
&ok;

## test 3	find a usable port for a test server
my $port = dyn_bind($remotsock,INADDR_LOOPBACK);
unless ($port) {
  close $remotsock;
  print "could not bind test socket to port\nnot ";
}
&ok;

my $parent = $$;

my $kid = fork;
unless ($kid) {
  # I am the kid

  my($run,$client,$cfileno);

  my(@wmsglen, @wmsg, @who);		# write queue
  my $fileno = fileno($remotsock);
  my $rsin;				# sender address
  my $buffer;				# receive accumulator
  my $wlen;				# bytes written
  my $wmsglen;				# write message len accumulator
  my $woff = 0;				# write offset into buffer

  my $then = time;
  my $delta;
  my $timeout = 5;			# always a 5 second timeout;

  $run = 1;

  my($rin,$rout,$win,$wout);

  while ($run && (kill 0, $parent)) {
    $rin = $win = '';
    vec($rin,$fileno,1) = 1;		# listner is always armed
    $win = $rin if @wmsg;		# if output
    my $nbfound = select($rout=$rin,$wout=$win,undef,1);
    if ($nbfound > 0) {			# if there is work
      if ($rout) {
	if ($rsin = recv($remotsock,$buffer,PACKETSZ,0)) {
	  push @wmsglen, length($buffer);
	  push @wmsg, $buffer;
	  push @who, $rsin;
	}
      }
      if ($wout && @wmsg) {			# if there is work
	unless ($woff) {			# if not busy
	  $wmsglen = $wmsglen[0];
	}
	if ($wlen = send($remotsock,$wmsg[0],0,$who[0])) {
	  $wmsglen -= $wlen;
	  $woff += $wlen;
# udp messages should always be sent in one transmission
	  unless ($wmsglen > 0) {		# if buffer empty
	    $woff = 0;
	    shift @wmsglen;
	    shift @wmsg;
	    shift @who;
	  }
	}
      }
    } # end if nbfound
    elsif ($delta = ($_ = time) - $then) {
      $then = $_;
      $timeout -= $delta;
      last if $timeout < 0;
    }
  }
  close $remotsock if $remotsock;
  exit 0;
}

##### PARENT

close $remotsock if $remotsock;		# parent closes remote socket on local side

my $shortstring = 'the quick brown fox jumped over the lazy dog';

# alarm wrapper for test _query
sub  query {
  my($self,$bp,$srv) = @_;
  my $rvp = eval {
	local $SIG{ALRM} = sub {};
	alarm 3;
	my $rv = $self->_query($bp,$srv);
	alarm 0;
	return $rv;
  };
  return undef if $@;
  return $rvp;
}

my $self = {
	Timeout	 => 3,		# 3 seconds
	PeerPort => $port
};

bless $self, 'Net::DNS::Dig';

## test 4	send message, should be echoed

my $msglen = length($shortstring);
my $rvp = query($self,\$shortstring,INADDR_LOOPBACK);

print "failed to send/receive query - error - $!\nnot "
	unless defined $rvp;
&ok;

## test	5	validate message
print "message corrupted\ngot: $$rvp\nexp: $shortstring\nnot "
	unless $rvp && $$rvp eq $shortstring;
&ok;

close $remotsock if $remotsock;

kill Sys::Sig->TERM, $kid;
waitpid($kid,0);
