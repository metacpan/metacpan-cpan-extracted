# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(
	get16
	get32
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

## test 2-10 check the test "get" routines
my @packitems = (1234,18124,123456789);
my @ptrs = (0,2,4);
my @exp = (2,4,8);
my $response = pack("n n N",1234, 18124, 123456789);

foreach(0..$#packitems) {
  if ($packitems[$_] < 65536) {
    @_ = get16(\$response,$ptrs[$_]);
  } else {
    @_ = get32(\$response,$ptrs[$_]);
  }
  print "nothing returned\nnot "
	unless @_;
  &ok;

  my ($ans, $size) = @_;
  print "item -> exp: $packitems[$_], got: $ans\nnot "
	unless $packitems[$_] == $ans;
  &ok;

  print "size -> exp: $exp[$_], got: $size\nnot "
	unless $exp[$_] == $size;
  &ok;
}

## test 11 fail, not a reference
print "failed, not a reference\nnot "
	if get32(1,0);
&ok;

## test 12 fail, offset beyond 32 bit end
print "failed, 32 bit offset beyond end of buffer\nnot "
	if get32(\$response,5);
&ok;

## test 12 fail, offset beyond 16 bit end
print "failed, 16 bit offset beyond end of buffer\nnot "
	if get16(\$response,7);
&ok;
