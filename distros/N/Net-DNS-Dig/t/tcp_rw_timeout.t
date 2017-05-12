# Before make install' is performed this script should be runnable with
# make test'. After make install' it should work as perl test.pl'

#	tcp_rw_timeout.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
	$| = 1; print "1..4\n";
	*CORE::GLOBAL::select = \&select;
}
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;
use Net::DNS::Dig;

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

my $selected = 0;

sub select {
  $selected++;
  sleep 1;
  return 0;
}

*tcp_write = \&Net::DNS::Dig::_tcp_write;
*tcp_read = \&Net::DNS::Dig::_tcp_read;

## test 2       open TCP socket
local *Sock;
my $sock = \*Sock;
print "could not open test socket\nnot "
        unless socket($sock,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
&ok;

## test 3	check tcp write timeout

my $buf = 'xxx';

my $rv = undef;
my $err = 0;

eval {
	$! = 0;
	local $SIG{ALRM} = sub {};
	alarm 2;
	$rv = tcp_write($sock,\$buf,3,0);
	$err = $!;
	alarm 0;
};

print "write socket timeout failed\nnot "
	unless $selected && $err && $err == 110 && ! defined $rv;
&ok;

## test 4	check tcp read timeout
$err = $buf = '';
undef $rv;

eval {
	$! = 0;
	local $SIG{ALRM} = sub {};
	alarm 2;
	$rv = tcp_read($sock,\$buf,3,0);
	$err = $!;
	alarm 0;
};
print "read socket timeout failed\nnot "
	unless $selected && $err && $err == 110 && ! defined $rv;
&ok;

close $sock;
