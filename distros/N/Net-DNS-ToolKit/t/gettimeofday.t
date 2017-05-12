# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	gettimeofday
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

sub elapsed {
  my ($startsec,$startusec,$endsec,$endusec) = @_;
  if ($endusec < $startusec) {
    $endusec += 1000000;
    $endsec -= 1;
  }
  my $msec = ($endusec - $startusec)/1000;
  $msec += ($endsec - $startsec) * 1000;
}

# time is an array of the form
# start seconds, start microseconds, end seconds, end microseconds

## test 2	access clock in array mode
my @time = gettimeofday;
print "gettimeofday failed\nnot "
	unless @time;
&ok;

foreach(0..100000-1) {
  # deadloop, waste some time in a known fashion
}

@time[2,3] = gettimeofday;

my $benchmark = elapsed(@time);

@time = gettimeofday;
foreach(0..100000-1) {
  gettimeofday;
}
@time[2,3] = gettimeofday;

my $elapsedtime = elapsed(@time) - $benchmark;

$_ = gettimeofday;
print "failed to get time in seconds, $_\nnot "
	unless $_ && $_ > 1000;	# must be at least this far past epoch, right?
&ok;

$_ = scalar localtime($_);
printf STDERR "\n\t$_, gettimeofday access time = %0.2f usec\n",$elapsedtime/10;
