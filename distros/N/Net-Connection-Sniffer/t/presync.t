# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "could not load Net::Connection::Sniffer::Report\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer::Report qw(
	chkcache
	presync
);

my $future;
{
  local $^W = 0;
  *Net::Connection::Sniffer::Report::_ctime = sub {return $future};
}

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp)) {
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

my $path = './tmp';
mkdir $path,0755;

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

## test 2	create test file
my $file = $path .'/testfile';
my $now = next_sec();
$future = $now + 100;
open(F,'>'. $file) or
	print "could not open '$file' for testing\nnot ";
&ok;

close F;

## test 3	check that override of _ctime works OK and no warnings
my $got = chkcache($file);
print "got: $got, exp: $future\nnot "
	unless $got == $future;
&ok;

## test 4	check failure on future timestamp
print "unexpected success with future timestamp\nnot "
	if ($got = presync($file));
&ok;

## test 5	check for next second
$now = next_sec();
$future = $now;
$got = presync($file);
$now = time;
print "got: undef, exp: $future\nnot "
	unless $got;
&ok;

## test 6	check for correct delay
print "got: $got, exp: $future\nnot "
	unless $got == $future;
&ok;

## test 7	check for correct now
print "got now: $now, exp: ", ($future +1), "\nnot "
	unless $now == $future +1;
&ok;

## test 8	check for old ctime
$future = $now -10;
$got = presync($file);
print "got: $got, exp: $future\nnot "
	unless $got == $future;		# really the past
&ok;

## test 9	check file missing
unlink $file;
print "got: $got, exp: undefined\nnot "
	if ($got = presync($file));
&ok;
