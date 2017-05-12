
# Before ake install' is performed this script should be runnable with
# ake test'. After ake install' it should work as erl test.pl'

#	tcp_rw_stream.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
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

*tcp_write = \&Net::DNS::Dig::_tcp_write;
*tcp_read = \&Net::DNS::Dig::_tcp_read;

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
my $longstring = '';
my $count = int(65535 / length($shortstring));  # make a long string, bigger than IP_MAXPACKET
  
foreach (1..$count) {
  $longstring .= sprintf("%s %04d\n",$shortstring,$_);       
}

## test 5       open TCP socket

my $localsock = connect_NB($port,INADDR_LOOPBACK);
print "could not connect to server\nnot "
	unless $localsock;
&ok;

# alarm wrapper for tcp_write
sub write_tcp {
  my($sock,$bp,$len) = @_;
  my $wrote = eval {
	local $SIG{ALRM} = sub {};
	alarm 3;
	my $rv = tcp_write($sock,$bp,$len,3);	# write with 3 second timeout
	alarm 0;
	$rv;
  };
  return undef if $@;
  return $wrote;
}

# alarm wrapper for tcp_read
sub read_tcp {
  my($sock,$bp,$len) = @_;
  my $rcvd = eval {
	local $SIG{ALRM} = sub {};
	alarm 3;
	my $rv = tcp_read($sock,$bp,$len,3);
	alarm 0;
	$rv;
  };
  return undef if $@;
  return $rcvd;
}

## test 6	write the short string length

my $msglen = length($shortstring);
my $wrote;

print "failed to write short message\nnot "
	unless ($wrote = write_tcp($localsock,\$shortstring,$msglen)) && $wrote == $msglen;
&ok;

$wrote = 0 unless $wrote;

# message should be in the receive queue

## test 7	read short string
$msglen = length($shortstring);
my $buffer = '';
my $rcvd = read_tcp($localsock,\$buffer,$msglen);
print "failed to receive short string\nnot "
	unless $buffer && $rcvd && $rcvd == $msglen;
&ok;

## test 8	compare strings
print "got: $buffer\nexp: $shortstring\nnot "
	unless $buffer eq $shortstring;
&ok;

## test 9	write the long string
$msglen = length $longstring;
print "failed to write long message\nnot "
	unless ($wrote = write_tcp($localsock,\$longstring,$msglen)) && $wrote == $msglen;
&ok;

# message should be in the receive queue

## test 10	read long string

$buffer = '';
$rcvd = read_tcp($localsock,\$buffer,$msglen,3);
print "failed to receive long string\nnot "
	unless $buffer && $rcvd && $rcvd == $msglen;
&ok;

## test 11	compare strings
print 'got: ', length($buffer), " long string\nexp: ", length($longstring), " long string\nnot "
	unless $buffer eq $longstring;
&ok;

## test 12	check read timeout return undef
$rcvd = eval {
	$SIG{ALRM} = sub {};
	alarm 4;
	my $rv = tcp_read($localsock,\$buffer,$msglen,2);	# attempt read where there is not data
	alarm 0;
	$rv;
};

print "received unknown data\nnot "
	if defined $rcvd;
&ok;

## test 13	check read time out return error 110
$rcvd = eval {
	$SIG{ALRM} = sub {};
	alarm 4;
	my $rv = tcp_read($localsock,\$buffer,$msglen,2);	# attempt read where there is not data
	alarm 0;
	return $rv ? undef : $!;	# return undefined if not timeout
};

print "expected time out error, got data\nnot "
	unless defined $rcvd;
&ok;

$rcvd -= 0 if $rcvd;

## test 14	
if ($rcvd == 110) {
  &ok;
} else {
  print "ok $test #skipped: odd error code - got: $rcvd, exp: 110 - really not ok\n";
  $test++;
}

# test 15	create null socket
local *NULLSOCK;
my $nullsock = \*NULLSOCK;

print "could not create tcp socket\nnot "
	unless socket($nullsock,PF_INET,SOCK_STREAM,$proto);
&ok;

## test 16	check for return from broken read pipe without blowing off Dig
undef $!;
$rcvd = eval {
	$SIG{ALRM} = sub {};
	alarm 4;
	my $rv = tcp_read($nullsock,\$buffer,$msglen,2);
	alarm 0;
	$rv;
};
print "received unknown data from null socket\nnot "
	if defined $rcvd;
&ok;

## test 17	should be some kind of error
print "no read pipe error found\nnot "
	unless $!;
&ok;

## test 18	check for return from broken write pipe
undef $!;
$wrote = eval {
	$SIG{ALRM} = sub {};
	alarm 4;
	my $rv = tcp_write($nullsock,\$shortstring,length($shortstring),2);
	alarm 0;
	$rv;
};
print "wrote something on broken pipe\nnot "
	if $wrote;
&ok;

## test 19	should be error present
print "no write pipe error found\nnot "
	unless $!;
&ok;

close $nullsock;
close $remotsock if $remotsock;
close $localsock if $localsock;

# kill the echo server
kill Sys::Sig->TERM, $kid;
waitpid($kid,0);
