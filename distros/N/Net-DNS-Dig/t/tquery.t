
# Before ake install' is performed this script should be runnable with
# ake test'. After ake install' it should work as erl test.pl'

#	tquery.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Dig;
use Socket;
use Net::DNS::ToolKit qw(
	get16
	put16
);
use Net::NBsocket qw(
	dyn_bind
	connect_NB
	accept_NB
	set_NB
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

local *RemoteSock;
my $remotsock = \*RemoteSock;
my $proto = getprotobyname('tcp');

print "could not create tcp socket\nnot "
	unless socket($remotsock,PF_INET,SOCK_STREAM,$proto) &&
	setsockopt($remotsock,SOL_SOCKET,SO_REUSEADDR,pack("l", 1));
&ok;

## test 3	find a usable port for a test server

my $port = dyn_bind($remotsock,INADDR_LOOPBACK);
unless ($port) {
  close $remotsock;
  print "could not bind test socket to port\nnot ";
}
&ok;

## test 4	make socket listen
print "failed to listen\nnot "
	unless listen($remotsock,SOMAXCONN);
&ok;

my $parent = $$;

my $kid = fork;
unless ($kid) {
  # I am the kid

  my($run,$client,$cfileno);

  my $fileno = fileno($remotsock);
  my(@wmsglen, @wmsg);			# write queue
  my $rlen;				# received bytes
  my $buffer;				# receive accumulator
  my $wlen;				# bytes written
  my $wmsglen;				# write message len accumulator
  my $woff = 0;				# write offset into buffer

  my $then = time;
  my $delta;
  my $timeout = 5;			# always a 5 second timeout;

  $run = 1;

  set_NB($remotsock);

  my($rin,$rout,$win,$wout);

  while ($run && (kill 0, $parent)) {
    $rin = $win = '';
    if ($client) {
      vec($rin,$cfileno,1) = 1;
      $win = $rin if @wmsg;		# if write pending
    }
    vec($rin,$fileno,1) = 1;		# listner is always armed
    my $nbfound = select($rout=$rin,$wout=$win,undef,1);
    if ($nbfound > 0) {			# if there is work
      if ($rout && vec($rout,$fileno,1)) {
	close $client if $client;	# close old client if present
	$client = accept_NB($remotsock);
	if ($client) {
	  $cfileno = fileno($client);
	} else {
	  $client = $cfileno = undef;
	}
      }
      if ($rout && $client && vec($rout,$cfileno,1)) {
	if ($rlen = sysread($client,$buffer,65535,0)) {
	  push @wmsglen, $rlen;
	  push @wmsg, $buffer;
	}
      }
      if ($wout && @wmsg) {			# if there is work
	unless ($woff) {			# if not busy
	  $wmsglen = $wmsglen[0];
	}
	if ($wlen = syswrite($client,$wmsg[0],$wmsglen,$woff)) {
	  $wmsglen -= $wlen;
	  $woff += $wlen;

	  unless ($wmsglen > 0) {		# if buffer empty
	    $woff = 0;
	    shift @wmsglen;
	    shift @wmsg;
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
  close $client if $client;
  exit 0;
}

##### PARENT

close $remotsock if $remotsock;		# parent closes remote socket on local side

my $shortstring = 'the quick brown fox jumped over the lazy dog';

# alarm wrapper for tquery
sub tquery {
  my($self,$bp,$server) = @_;
  my $wrote = eval {
	local $SIG{ALRM} = sub {};
	alarm 3;
	my $rv = $self->_tquery($bp,$server);
	alarm 0;
	$rv;
  };
  return undef if $@;
  return $wrote;
}

my $self = {
	Timeout  => 3,          # 3 seconds
	PeerPort => $port
};

bless $self, 'Net::DNS::Dig';

## test 5	echo the short string length

my $msglen = length($shortstring);
my $rp = tquery($self,\$shortstring,INADDR_LOOPBACK);
print "failed to receive short string\nnot "
	unless $rp && $$rp eq $shortstring;
&ok;

close $remotsock if $remotsock;

# kill the echo server
kill Sys::Sig->TERM, $kid;
waitpid($kid,0);
