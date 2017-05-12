# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::NBsocket qw(
	open_udpNB
	AF_INET6
	havesock6
	isupport6
	in6addr_loopback
	in6addr_any
	pack_sockaddr_in6
);
use POSIX qw(EWOULDBLOCK);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

my($L,$R);

sub ok {
  my $rv = shift;
  unless ($rv) {
    print "ok $test\n";
    ++$test;
    return;
  }
  close $R if $R;
  close $L if $L;
  while ($test < 15) {
    print "ok $test	# skipped, $rv\n";
    $rv = 'no IPv6 support';
    $test++;
  }
  exit;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

ok "Socket6 not installed"
	unless havesock6();

ok "host has no IPv6 support"
	unless isupport6();

## test 2	open a listening socket
$L = open_udpNB(AF_INET6());;
ok $L ? '' : 'could not open local unbound socket';

## test 3	bind a listner for testing
my $port;
foreach(10000..10100) {		# find a port to bind to
  if (bind($L,pack_sockaddr_in6($_,in6addr_any()))) {
    $port = $_;
    last;
  } else {
    $port = 0;
  }
}

ok $port ? '' : 'could not bind a port for testing';

## test 4	open a sending socket
$R = open_udpNB(AF_INET6());
ok $R ? '' : 'could not open unbound send socket';

## test 5	check non-blocking status
my $inbuf;
my $err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 2;
	if (recv $L,$inbuf,512,0) {
	  die "received something";
	} else {
	  alarm 0;
	  $!;
	}
};
ok $@ ? $@ : '';

## test 6	show any unexpected errors
if ($err && $err != EWOULDBLOCK()) {
  ok "unexpected error $err"
} else {
  &ok;
}

## test 7	send message, should not block
my $R_sin = pack_sockaddr_in6($port,in6addr_loopback());
my $message = 'expected message';
my $now = &next_sec;	# sync actions
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if (($rv = send($R,$message,0,$R_sin)) && $rv == length($message)) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
};
ok $@ ? $@ : '';

## test 8	read message back on listner
$now = &next_sec($now);
my $L_sin;
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 2;
	$L_sin = recv $L,$inbuf,512,0;
	alarm 0;
	$!;
};
ok $@ ? $@ : '';

## test 9	report unexpected errors
ok $L_sin ? '' : "unexpected error $err";

#### ok so IPv6 transport works or we've already failed

## test 10	check message value
print "got: $inbuf, exp: $message\nnot "
	unless $inbuf && $inbuf eq $message;
&ok;

## test 11	send reply
$message = 'reply message';
$now = &next_sec;	# sync actions
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if (($rv = send($L,$message,0,$L_sin)) && $rv == length($message)) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
};
print $@, "\nnot "
	if $@;
&ok;

## test 12	read message back on listner
$now = &next_sec($now);
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 2;
	$R_sin = recv $R,$inbuf,512,0;
	alarm 0;
	$!;
};
print $@, "\nnot "
	if $@;
&ok;

## test 13	report unexpected errors
print "unexpected error $err\nnot "
	unless $R_sin;
&ok;

## test 14	check message value
print "got: $inbuf, exp: $message\nnot "
	unless $inbuf && $inbuf eq $message;
&ok;

close $L;
close $R;
