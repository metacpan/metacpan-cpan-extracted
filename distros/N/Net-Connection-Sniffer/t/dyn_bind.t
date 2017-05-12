# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;
use Net::NBsocket qw(open_udpNB);
use Net::Connection::Sniffer::Report qw(
	dyn_bind
);

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

################################################################
################################################################

## test 2	test sock open

my ($buf,$rin,$rout,$win,$wout,$bytes);
my $sock = open_udpNB();
print "could not open socket\nnot "
	unless $sock;
&ok;

## test 3	test bind
my $port = dyn_bind($sock,&INADDR_LOOPBACK);
print "could not bind socket to $port\nnot "
	unless $port;
&ok;

## test 4 - 15
my $saddr = sockaddr_in($port,&INADDR_LOOPBACK);
my $pid = fork;

die "could not fork\nnot " unless defined $pid;

$| = 1;

if ($pid) {			# parent
  close $sock;			# close server
  sleep 2;
  $sock = open_udpNB();
  my @lines = split(/\n/,q|The quick brown fox
jumped over the lazy dog
1234567890
tHE QUICK BROWN FOX JUMPED OVER THE LAZY DOG
|);
  foreach(@lines) {
    $rin = '';
    vec($rin,fileno($sock),1) = 1;
    $win = $rin;
    eval {
	local $SIG{ALRM} = sub {die "parent timed out";};
	alarm 2;
	select(undef,$wout=$win,undef,undef);	# block here
	$bytes = send($sock,$_,0,$saddr);
	select($rout=$rin,undef,undef,undef);	# block here
	recv($sock,$buf,1000,0);
	alarm 0;
    };
## test 4,7,10,13
    print "Bail out! socket error: $@\nnot "
	if $@;
    &ok;
## test 5,8,11,14
    print "got: ". length($buf) .", exp: ". length($_) ." lines\nnot "
	unless length($buf) == length($_);
    &ok;
## test 6,9,12,15
    print "got: $buf, exp: $_\nnot "
	unless $buf eq $_;
    &ok;
  }
  sleep 2;
  close $sock;

} else {			# child

  local $SIG{ALRM} = sub {
	close $sock;
	exit 0;
  };
  local $SIG{INT} = sub {
#	print "CAUGHT 'INT'\n";
	close $sock;
	exit 0;
  };
  alarm 10;
  while (1) {
    $rin = '';
    vec($rin,fileno($sock),1) = 1;
    $win = $rin;
    my $nfound =  select($rout=$rin,undef,undef,undef);
    $saddr = recv($sock,$buf,1000,0);
    my $len = length($buf);
    select(undef,$wout=$win,undef,undef);
    $bytes = send($sock,$buf,0,$saddr);
  }
}

# print "$$ waiting for $pid\n";
kill 'INT', $pid;
eval {
# print "waiting...\n";
	local $SIG{ALRM} = sub {die "timed out";};
	alarm 10;
	waitpid($pid,0);
	alarm 0;
};

## test 16
print "waitpid $@\nnot "
	if $@;
&ok;
