# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::NBsocket qw(
	open_listenNB
	connect_NB
	accept_NB
	havesock6
	isupport6
	in6addr_loopback
	AF_INET6
	ipv6_n2x
);

use POSIX qw(EWOULDBLOCK);
require Socket;
import Socket qw(
	SO_ERROR
	SOL_SOCKET
);
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

my($client,$server);

sub ok {
  my $rv = shift;
  unless ($rv) {
    print "ok $test\n";
    ++$test;
    return;
  }
  elsif ($rv =~ /bug/) {
    print "ok $test	# skipped, $rv\n";
    ++$test;
    return;
  }
  close $client if $client;
  close $server if $server;
  while ($test < 23) {
    print "ok $test     # skipped, $rv\n";
    $rv = 'no IPv6 support';
    $test++;
  }
  exit;
}

ok 'Socket6 not installed'
	unless havesock6();

ok 'no IPv6 support on this host'
	unless isupport6();

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
}

my $dir = `pwd`;
do { chop $dir } while ($dir =~ /\s$/);
$dir .= '/tmp';
mkdir $dir,0755;

my $filename = &{sub{(caller())[1]}};

my $uds;

## test 1 - 2	open a listening TCP socket
my $port;
if ($filename =~ /tcp_/) {		# else internet domain socket
  print STDERR "\tTesting IPv6 Internet Domain Sockets\n";
  foreach (10000..10100) {		# find a port to bind to
    if ($server = open_listenNB($_,undef,AF_INET6())) {
      $port = $_;
      last;
    }
  }
} else {				# internet domain socket with designated address
  print STDERR "\tTesting ::1 Sockets\n";
  foreach (10000..10100) {		# find a port to bind to
    if ($server = open_listenNB($_,in6addr_loopback(),AF_INET6())) {
      $port = $_;
      last;
    }
  }
}

ok $server ? '' : 'could not open a listening port for testing';

## test 3
my $filenoS = fileno($server);
ok $filenoS ? '' : 'could not get fileno for $server';

## test 4	open connecton to listening port
$client = connect_NB($port,in6addr_loopback(),AF_INET6());
ok $client ? '' : 'could not connect to server for testing';

my ($rin,$rout,$win,$wout,$clone,$caddr);

my $expire = time + 5;		# timeout in 5 seconds

## test 5
my $filenoC = fileno($client);
ok $filenoC ? '' : 'could not get file numbers for sockets';

## test 6 - 7
my $exp = '0:0:0:0:0:0:0:1';
my $wready = 0;			# ready to write
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoS,1) = 1;
  (vec($win,$filenoC,1) = 1) unless $wready;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  my $fail = '';
  if (vec($rout,$filenoS,1)) {		# listner - accept
    ($clone,$caddr) = accept_NB($server);
    unless ($clone) {
      $fail = 'could not accept connection';
    } elsif ( ! $uds && !($caddr = ipv6_n2x($caddr)) ) {
      $fail = "bad connect addr $caddr";
    } elsif ( ! $uds && $caddr ne $exp ) {
      $fail = "perl 'accept' bug\ngot: $caddr\nexp: $exp";
    } elsif ($test != 6) {
      $fail = "wrong test number $test != 6";
    }
    ok $fail;
  } elsif (vec($wout,$filenoC,1)) {	# client connected
    my $status = getsockopt($clone,SOL_SOCKET(),SO_ERROR());
    if ($status eq "\0") {
      print "connection incomplete\nnot ";
    } elsif ($test != 7) {
       print "wrong test number $test != 7\nnot ";
    } else {
      $wready = 1;
    }
    print "ok 7\n"; ++$test;
    last;
  }
}

## test 8	nb setup complete
if ($test == 8) {
  &ok;
} else {
ok 'accept / connection incomplete';
}

my $filenoX = fileno($clone);

## test 9
ok $filenoX ? '' : 'could not get fileno for $clone';

## test 10	check for sysread error
my $rbuf;
print "unexpected read\nnot "
	if defined sysread($clone,$rbuf,512);
&ok;

## test 11	check error value
print "error is '$!', expected EWOULDBLOCK\nnot "
	unless $! == EWOULDBLOCK;
&ok;

$expire = time + 5;			# timeout in 5 seconds
my $wbuf = 'hello';
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoX,1) = 1;
  (vec($win,$filenoC,1) = 1) if $wready;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  if (vec($wout,$filenoC,1)) {
## test 12	write to client
    print "client could not write to clone server\nnot "
	unless syswrite($client,$wbuf,length($wbuf));
    print "ok 12\n"; ++$test;
    $wready = 0;
  } elsif (vec($rout,$filenoX,1)) {
## test 13 - 14		check transmitted data
    print "unknown size of data from client = $_\nnot "
	unless ($_ = sysread($clone,$rbuf,512)) == length($wbuf);
    print "ok 13\n"; ++$test;
    print "got: $rbuf, exp: $wbuf\nnot "
	unless $rbuf eq $wbuf;
    print "ok 14\n"; ++$test;
    last;
  }
}

## test 15	nb client to server complete
print "client write incomplete\nnot " unless $test == 15;
&ok;

$expire = time + 5;                     # timeout in 5 seconds
$wbuf = 'goodbye';
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoC,1) = 1;
  (vec($win,$filenoX,1) = 1) unless $wready;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  if (vec($wout,$filenoX,1)) {
## test 16	write back to client
    print "clone could not reply to client\nnot "
	unless syswrite($clone,$wbuf,length($wbuf));
    print "ok 16\n";	++$test;
    $wready = 1;
  } elsif (vec($rout,$filenoC,1)) {
## test 17 - 18	check data from clone
    print "unknown size of data from clone = $_\nnot "
	unless ($_ = sysread($client,$rbuf,512)) == length($wbuf);
    print "ok 17\n";	++$test;
    print "got: $_, exp: $wbuf\nnot "
	unless $rbuf eq $wbuf;
    print "ok 18\n";	++$test;
    last;
  }
}

## test 19	nb clone to client complete
print "clone writeback incomplete\nnot " unless $test == 19;
&ok;

## test 20	check for sysread error
print "unexpected read\nnot "
	if defined sysread($client,$rbuf,512);
&ok;

## test 21	check error value
print "error is '$!', expected EWOULDBLOCK\nnot "
	unless $! == EWOULDBLOCK;
&ok;

close $clone;

## test 22	check for EOF
$wready = 1;
$expire = time + 5;                     # timeout in 5 seconds
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoC,1) = 1;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  unless (vec($rout,$filenoC,1)) {
    print "unknown interrupt\nnot ";
  } elsif ($_ = sysread($client,$rbuf,512)) {
    print "unknown string read: $rbuf\nnot ";
  }
  $wready = 0;
  last;
}
print "EOF detection timed out\nnot "
	if $wready;
&ok;
close $server;
close $client;
