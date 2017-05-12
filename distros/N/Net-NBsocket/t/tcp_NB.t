# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::NBsocket qw(
	open_listenNB
	connect_NB
	accept_NB
);
use Socket;
use POSIX qw(EWOULDBLOCK);

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

my $uds = ($filename =~ /tcpux_NB/) ? $dir .'/unix_domain_socket' : '';

## test 1 - 2	open a listening TCP socket
my ($port,$server);
if ($uds) {				# if testing unix domain socket
  print  STDERR "\tTesting Unix Domain Sockets\n";
  $server = open_listenNB($uds);
  $port = $uds;
} elsif ($filename =~ /tcp_/) {		# else internet domain socket
  print STDERR "\tTesting Internet Domain Sockets\n";
  foreach (10000..10100) {		# find a port to bind to
    if ($server = open_listenNB($_)) {
      $port = $_;
      last;
    }
  }
} else {				# internet domain socket with designated address
  print STDERR "\tTesting 127.0.0.1 Sockets\n";
  foreach (10000..10100) {		# find a port to bind to
    if ($server = open_listenNB($_,inet_aton('127.0.0.1'))) {
      $port = $_;
      last;
    }
  }
}

print "could not open a listening port for testing\nnot "
	unless $server;
&ok;

## test 3	open connecton to listening port
my $client = connect_NB($port,INADDR_LOOPBACK);
print "could not connect to server for testing\nnot "
	unless $client;
&ok;

my ($rin,$rout,$win,$wout,$clone,$caddr);

my $expire = time + 5;		# timeout in 5 seconds

my $filenoS = fileno($server);
my $filenoC = fileno($client);

## test 4 - 5
my $wready = 0;			# ready to write
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoS,1) = 1;
  (vec($win,$filenoC,1) = 1) unless $wready;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  if (vec($rout,$filenoS,1)) {		# listner - accept
    ($clone,$caddr) = accept_NB($server);
    unless ($clone) {
      print "could not accept connection\nnot ";
    } elsif ( ! $uds && !($caddr = inet_ntoa($caddr)) ) {
      print "bad connect addr $caddr\nnot ";
    } elsif ( ! $uds && $caddr ne '127.0.0.1' ) {
      print "got: $caddr, exp: 127.0.0.1\nnot ";
    } elsif ($test != 4) {
      print "wrong test number $test != 4\nnot ";
    }
    print "ok 4\n"; ++$test;
  } elsif (vec($wout,$filenoC,1)) {	# client connected
    my $status = getsockopt($clone,SOL_SOCKET,SO_ERROR);
    if ($status eq "\0") {
      print "connection incomplete\nnot ";
    } elsif ($test != 5) {
       print "wrong test number $test != 5\nnot ";
    } else {
      $wready = 1;
    }
    print "ok 5\n"; ++$test;
    last;
  }
}

## test 6	nb setup complete
print "accept / connection incomplete\nnot " unless $test == 6;
&ok;

my $filenoX = fileno($clone);

## test 7	check for sysread error
my $rbuf;
print "unexpected read\nnot "
	if defined sysread($clone,$rbuf,512);
&ok;

## test 8	check error value
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
## test 9	write to client
    print "client could not write to clone server\nnot "
	unless syswrite($client,$wbuf,length($wbuf));
    print "ok 9\n"; ++$test;
    $wready = 0;
  } elsif (vec($rout,$filenoX,1)) {
## test 10 - 11		check transmitted data
    print "unknown size of data from client = $_\nnot "
	unless ($_ = sysread($clone,$rbuf,512)) == length($wbuf);
    print "ok 10\n"; ++$test;
    print "got: $rbuf, exp: $wbuf\nnot "
	unless $rbuf eq $wbuf;
    print "ok 11\n"; ++$test;
    last;
  }
}

## test 12	nb client to server complete
print "client write incomplete\nnot " unless $test == 12;
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
## test 13	write back to client
    print "clone could not reply to client\nnot "
	unless syswrite($clone,$wbuf,length($wbuf));
    print "ok 13\n";	++$test;
    $wready = 1;
  } elsif (vec($rout,$filenoC,1)) {
## test 14 - 15	check data from clone
    print "unknown size of data from clone = $_\nnot "
	unless ($_ = sysread($client,$rbuf,512)) == length($wbuf);
    print "ok 14\n";	++$test;
    print "got: $_, exp: $wbuf\nnot "
	unless $rbuf eq $wbuf;
    print "ok 15\n";	++$test;
    last;
  }
}

## test 16	nb clone to client complete
print "clone writeback incomplete\nnot " unless $test == 16;
&ok;

## test 17	check for sysread error
print "unexpected read\nnot "
	if defined sysread($client,$rbuf,512);
&ok;

## test 18	check error value
print "error is '$!', expected EWOULDBLOCK\nnot "
	unless $! == EWOULDBLOCK;
&ok;

close $clone;

## test 19	check for EOF
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
