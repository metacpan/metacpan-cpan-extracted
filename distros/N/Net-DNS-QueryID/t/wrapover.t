# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
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

mode(65534);		# set "next" ID to 65534 for testing

## test 2 - 5		generate 4 ID's
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

my @exp = (65534, 65535, 1, 2);

## test 11 - 14		check that overflow ID's were created sequentially
foreach(0..$#qid) {
  print "got: $qid[$_], exp: $exp[$_]\nnot "
	unless $qid[$_] == $exp[$_];
  &ok;
}

print STDERR "\tthis may take a while\n";
## test 15		fill remainder of cache in random fashion
foreach(3..(65534 +2 - $got)) {
  unless (id_get()) {
    print "failed to get/set Query ID\nnot ";
    last;
  }
}
&ok; 

## test 16		check that there are 65534 entries
$idvec = mode(0);
$got = unpack("%32b*",$idvec);
print "got: $got, exp: 65534\nnot "
	unless $got == 65534;
&ok;

## test 17		check that one more space exists
print "failed to get one more Query ID\nnot "
	unless id_get();
&ok;

print STDERR "\tthis may take a while\n";
## test 18		check that cache is full
print "cache was NOT full and should have been\nnot "
	if id_get();
&ok;

## test 19		check busy underflow
print "ID zero present\nnot "
	if id_busy(0);
&ok;

## test 20		check busy overflow
print "ID 65536 present \nnot "
	if id_busy(65536);
&ok;
