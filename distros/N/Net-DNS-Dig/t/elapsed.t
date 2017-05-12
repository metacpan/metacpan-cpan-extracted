# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#	elapsed.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Dig;
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

my $self = new Net::DNS::Dig();

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

my $benchmark = $self->_elapsed(@time);

@time = gettimeofday;
foreach(0..100000-1) {
  gettimeofday;
}
my $elapsedtime = $self->_elapsed(@time) - $benchmark;

$_ = gettimeofday;
print "failed to get time in seconds, $_\nnot "
	unless $_ && $_ > 1000;	# must be at least this far past epoch, right?
&ok;

print "failed to update object with elapsed time\nnot "
	unless $elapsedtime = $self->{ELAPSED};
&ok;

$_ = scalar localtime($_);
printf STDERR "\t%s, gettimeofday access time = %0.2f usec\n",$_,$elapsedtime/10;
print "ok $test\n";
