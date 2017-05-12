# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::QueryID qw(
	id_get
	id_clr
	id_busy
);

$loaded = 1;

print "ok 1\n";

*mode = \&Net::DNS::QueryID::_mode;

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

mode(86);		# set "next" ID to 86 for testing

## test 2 - 5		generate 4 ID's, 86, 87, 88, 89
my $exp = 4;
my @qid;
foreach (1..$exp) {
  my $try = id_get();
  print "failed to get Query ID\nnot "
    unless $try;
  push @qid, $try;
  &ok;
}

## test 6		check that 4 were generated
my $idvec = mode(0);	# retrieve vector		set RANDOM mode
my $got = unpack("%32b*",$idvec);
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

## test 7 - 10		check that ID's are in cache
foreach(@qid) {
  unless (id_busy($_)) {
    print "$_ not found in Query ID cache\nnot "
  }
  &ok;
}

my @exp = (86,87,88,89);

## test 11 - 14		check that overflow ID's were created sequentially
foreach(0..$#qid) {
  print "got: $qid[$_], exp: $exp[$_]\nnot "
	unless $qid[$_] == $exp[$_];
  &ok;
}

## test 15		check that leading ID' sre not in the cache
foreach (1..85) {
  if (id_busy($_)) {
    print "unexpected ID $_ in cache\nnot ";
    last;
  }
}
&ok;

## test 16
foreach (90..65535) {
  if (id_busy($_)) {
    print "unexpected ID $_ in cache\nnot ";
    last;
  }
}
&ok;
