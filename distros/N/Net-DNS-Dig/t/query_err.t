
# Before ake install' is performed this script should be runnable with
# ake test'. After ake install' it should work as erl test.pl'

#	query_err.t
#
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
	$| = 1; print "1..6\n";
# emulate these for testing
	*CORE::GLOBAL::select = \&select;
	*CORE::GLOBAL::recv = \&recv;
	*CORE::GLOBAL::send = \&send;
}
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

my($rout,$wout,$found);
# rout and wout are flags

sub select {
# rin, win, ein, timeout
  $_[0] = $rout ? $_[0] : '';
  $_[1] = $wout ? $_[1] : '';
  sleep 1;
  $found;
}

my $length;

sub send {
  my($sock,$msg,$flags,$timeout) = @_;
  return $length;
}

my($recvrv);

sub recv {
# sock, msg, length, flags
  $recvrv;
}

# emulation use
#
# select
# will set rout and wout if $rin and $win respectively are set
# returns '$found'
#
#
# send returns value in $length
#
#
# recv returns $recvrv
#


## test 2	create echo server that will do nothing
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

my $shortstring = 'the quick brown fox jumped over the lazy dog';

# don't need alarm wrapper for test _query
sub query {
  my($self,$bp,$srv) = @_;
#  my $rvp = eval {
#	local $SIG{ALRM} = sub {};
#	alarm 3;
	my $rv = $self->_query($bp,$srv);
#	alarm 0;
	return $rv;
#  };
#  return undef if $@;
#  return $rvp;
}

my $self = {
	Timeout	 => 3,		# 3 seconds
	PeerPort => $port
};

bless $self, 'Net::DNS::Dig';

## test 5	send message, should timeout
my $msglen = length($shortstring);
# set up dummy perl commands for timeout
$rout = $wout = '';
$length = $msglen;
$found = 0;

my $rvp = query($self,\$shortstring,INADDR_LOOPBACK);
print "failed to timeout\nnot "
	if defined $rvp || $! != 110;
&ok;

## test	6	connection refused
$recvrv = undef;
$rout = 1;	# replicate rin
$found = 1;

$rvp = query($self,\$shortstring,INADDR_LOOPBACK);
print "failed connection refused\nnot "
	if defined $rvp || $! != 111;
&ok;

## test 7	no data
$recvrv = 0;

$rvp = query($self,\$shortstring,INADDR_LOOPBACK);
print "failed no data\nnot "
	if defined $rvp && $rvp != 0 && $! != 61;
&ok;

close $remotsock if $remotsock;
