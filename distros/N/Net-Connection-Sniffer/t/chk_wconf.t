# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}

use Socket;
use Net::Connection::Sniffer::Report qw(
	chk_wconf
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp tmpc)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
     /.+/;              # allow for testing with -T switch
      unlink "$dir/$&";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
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

## test 2	# check stats file
my $conf = {};
my $exp = 'required statistics file specification missing';
print "got: $_\nexp: $exp\nnot "
	unless ($_ = chk_wconf($conf)) eq $exp;
&ok;
	
## test 3	# stats directory missing
my $path = './tmp';
my $sfile = $path .'/stats';
$conf->{stats} = $sfile;
$exp = "stats directory missing or not readable: './tmp/'";
print "got: $_\nexp: $exp\nnot "
	unless ($_ = chk_wconf($conf)) eq $exp;
&ok;

mkdir $path,0755;

## test 4	# check cache directory
$conf->{cache} = './tmpc/cachefile';
$exp = "cache directory not writable: './tmpc/'";
print "got: $_\nexp: $exp\nnot "
	unless ($_ = chk_wconf($conf)) eq $exp;
&ok;

mkdir './tmpc',0755;

## test 5	# invalid update timeout
$conf->{updto} = '1234x';
$exp = "invalid characters in update timeout: '1234x'";
print "got: $_\nexp: $exp\nnot "
	unless ($_ = chk_wconf($conf)) eq $exp;
&ok;

## test 6	# invalid refresh timer
$conf->{updto} = 25;
$conf->{refresh} = '1234z';
$exp = "invalid characters in refresh: '1234z'";
print "got: $_\nexp: $exp\nnot "
	unless ($_ = chk_wconf($conf)) eq $exp;
&ok;

##test 7	# verify updto
$exp = 25;
print "got: $conf->{updto}, exp: $exp\nnot "
	unless $conf->{updto} == $exp;
&ok;

##test 8	# invalid host specification
$conf->{refresh} = 12345;
delete $conf->{updto};		# should set to default
$conf->{update} = 'somefunnystring';
$exp = "invalid update specification 'somefunnystring'";
print "got: $_\nexp: $exp\nnot "
	unless ($_ = chk_wconf($conf)) eq $exp;
&ok;

## test 9	# verify default 'updto'
$exp = 15;
print "got: $conf->{updto}, exp: $exp\nnot "
	unless $conf->{updto} == $exp;
&ok;

## test 10	# verify unchanged refresh
$exp = 12345;
print "got: $conf->{refresh}, exp: $exp\nnot "
	unless $conf->{refresh} == $exp;
&ok;

## test 11	# verify sockaddr_in
delete $conf->{refresh};	# should get set to 300
my $ip = '192.168.0.99';
my $port = '54321';
$conf->{update} = $ip .':'. $port;
print "unexpected error: $_\nnot "
	if ($_ = chk_wconf($conf));
&ok;

## test 12	# check sin values
my($p,$i);
eval {
	($p,$i) = sockaddr_in($conf->{update});
};
if ($@) {
  print $@,"\nnot ";
}
elsif ($p != $port) {
  print "got port: $p, exp: $port\nnot "
}
elsif (($i = eval {inet_ntoa($i)}) ne $ip) {
  print "got IP: $i, exp: $ip\nnot "
}
&ok;

## test 13	# check default refresh, preset default sockaddr_in check
$exp = 300;
$conf->{update} = $port;
$ip = '127.0.0.1';
print "unexpected error: $_\nnot "
	if ($_ = chk_wconf($conf));
&ok;

## test 14	# check sin values
eval {
	($p,$i) = sockaddr_in($conf->{update});
};
if ($@) {
  print $@,"\nnot ";
}
elsif ($p != $port) {
  print "got port: $p, exp: $port\nnot "
}
elsif (($i = eval {inet_ntoa($i)}) ne $ip) {
  print "got IP: $i, exp: $ip\nnot "
}
&ok;

