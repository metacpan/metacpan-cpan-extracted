# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit::Utilities qw(
	id
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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

my $now = next_sec();

## test 2	check return of time + 1 mod 65536
$exp = $now % 65536;
$exp++;
$exp++ unless $exp;
print "got: $_, exp: $exp\nnot "
	unless ($_ = id($now)) eq $exp;
&ok;

## test 3	in 1, out 2
print "got: $_, exp: 2\nnot "
	unless ($_ = id(1)) eq 2;
&ok;

## test 4	in 65534, out 65535
print "got: $_, exp: 65535\nnot "
	unless ($_ = id(65534)) eq 65535;
&ok;

## test 5	in 65535, out 1
print "got: $_, exp: 1\nnot "
	unless ($_ = id(65535)) eq 1;
&ok;
