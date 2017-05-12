# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::NBsocket qw(
	open_listenNB
	connect_NB
	accept_NB
	AF_INET6
	ipv6_aton
	isupport6
	havesock6
	ipv6_n2x
	in6addr_loopback
);
require Socket;
import Socket qw(
	inet_aton
	inet_ntoa
	INADDR_LOOPBACK
);
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

my ($port,$server,$client,$filenoS,$filenoC);
 
sub open_server {
  my $port;
  foreach (10000..10100) {		# find a port to bind to
    if ($server = open_listenNB($_,inet_aton('127.0.0.1'))) {
      $port = $_;
      last;
    }
  }
  print "could not open a listening port for testing\nnot "
	unless $server;
  &ok;

## next test	open connecton to listening port
  $client = connect_NB($port,INADDR_LOOPBACK());
print "could not connect to server for testing\nnot "
	unless $client;
  &ok;

  $filenoS = fileno($server);
  $filenoC = fileno($client);
}

## test 2 - 3	open a listening TCP socket
&open_server;

my ($rin,$rout,$win,$wout,$clone,$caddr);

my $expire = time + 5;		# timeout in 5 seconds


## test 4	test accept in array context
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
    } elsif ( !($caddr = inet_ntoa($caddr)) ) {
      print "bad connect addr $caddr\nnot ";
    } elsif ( $caddr ne '127.0.0.1' ) {
      print "got: $caddr, exp: 127.0.0.1\nnot ";
    }
  }
  &ok;
  last;
}

## test 5	nb setup complete
unless ($test == 5) {
  close $server;
  print "Bail out!	accept / connection incomplete\n";
  exit;
}
&ok;

close $server;

## test 6 - 7	reopen server
&open_server;

$expire = time + 5;		# timeout in 5 seconds

## test 8	test accept in scalar context
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoS,1) = 1;
  (vec($win,$filenoC,1) = 1) unless $wready;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  if (vec($rout,$filenoS,1)) {		# listner - accept
    $clone = accept_NB($server);
    unless ($clone) {
      print "could not accept connection\nnot ";
    }
  }
  &ok;
  last;
}

## test 9	nb setup complete
print "accept / connection incomplete\nnot " unless $test == 9;
&ok;

close $server;


## test 10	test error return in array context;

my @rv = accept_NB($server);
print "return array is not empty\nnot "
	if @rv;
&ok;

## test 11	test error return in scalar context
print "scalar return value defined\nnot "
	if defined accept_NB($server);
&ok;

close $server if $server;

############################## IPv6

sub open6_server {
  unless (isupport6() && havesock6) {
    print havesock6()
    	? "ok $test	# skipped, Socket6 installed\n"
	: "ok $test	# skipped, Socket6 not installed\n";

    $test++;
    print "ok $test	# skipped, no IPv6 sockets for this OS\n";
    $test++;
    return;
  }
  my $port;
  foreach (10000..10100) {		# find a port to bind to
    if ($server = open_listenNB($_,ipv6_aton(in6addr_loopback()),AF_INET6())) {
      $port = $_;
      last;
    }
  }
  print "could not open a listening port for testing\nnot "
	unless $server;
  &ok;

## next test	open connecton to listening port
  $client = connect_NB($port,in6addr_loopback(),AF_INET6());
print "could not connect to server for testing\nnot "
	unless $client;
  &ok;

  $filenoS = fileno($server);
  $filenoC = fileno($client);
}

## test 12 - 13	open a listening TCP socket

&open6_server;

$expire = time + 5;		# timeout in 5 seconds

## test 14	test accept in array context
my $exp = '0:0:0:0:0:0:0:1';
while(time < $expire) {
  $rin = $win = '';
  vec($rin,$filenoS,1) = 1;
  (vec($win,$filenoC,1) = 1) unless $wready;
  my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
  next unless $nfound > 0;
  if (vec($rout,$filenoS,1)) {		# listner - accept
    ($clone,$caddr) = accept_NB($server);
    unless ($clone) {
      print "could not accept connection\nnot ok $test\n";
    } elsif ( !($caddr = ipv6_n2x($caddr)) ) {
      print "bad connect addr $caddr\nnot ok $test\n";
    } elsif ( $caddr ne $exp ) {
      print "got: $caddr\nexp: $exp\nnot ok $test	# skipped, perl 'accept' bug\n";
    }
    else {
      print "ok $test\n";
    }
  }
  $test++;

  last;
}

## test 15	nb setup complete
my $skip = 0;

sub skipping {
  return 0 unless $skip;
  my $reason = shift;
  $reason = 'no IPv6 localhost' unless $reason;
  print "ok $test	# skipped, $reason\n";
  $test++;
}

unless ($test == 15) {
  $skip++;
  print STDERR "\tIPv6 sockets not configured on this host\n";
  skipping('no IPV6 support');
}
&ok;

close $server;

## test 16 - 17	reopen server
open6_server() unless skipping();

$expire = time + 5;		# timeout in 5 seconds

## test 18	test accept in scalar context
unless (skipping()) {
  while(time < $expire) {
    $rin = $win = '';
    vec($rin,$filenoS,1) = 1;
    (vec($win,$filenoC,1) = 1) unless $wready;
    my $nfound = select($rout=$rin,$wout=$win,undef,0.1);
    next unless $nfound > 0;
    if (vec($rout,$filenoS,1)) {		# listner - accept
      $clone = accept_NB($server);
      unless ($clone) {
        print "could not accept connection\nnot ";
      }
    }
    &ok;
    last;
  }
}
## test 19	nb setup complete
unless (skipping()) {
  print "accept / connection incomplete\nnot " unless $test == 19;
  &ok;
}

close $server unless skipping();


## test 20	test error return in array context;

@rv = accept_NB($server);
print "return array is not empty\nnot "
	if @rv;
&ok;

## test 21	test error return in scalar context
print "scalar return value defined\nnot "
	if defined accept_NB($server);
&ok;
