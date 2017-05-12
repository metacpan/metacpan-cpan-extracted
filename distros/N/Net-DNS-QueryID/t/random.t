# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..34\n"; }
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

## test 2 - 11		generate 10 ID's
my $exp = 10;
my @qid;
foreach (1..$exp) {
  my $try = id_get();
  print "failed to get Query ID\nnot "
    unless $try;
  push @qid, $try;
  &ok;
}

## test 12		check that 10 were generated
my $idvec = mode(0);	# retrieve vector

my $got = unpack("%32b*",$idvec);

print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

## test 13 - 22		check that ID's are in cache
foreach(@qid) {
  unless (id_busy($_)) {
    print "$_ not found in Query ID cache\nnot "
  }
  &ok;
}

## test 23 - 27		clear half the ID's from cache

while ($_ = pop @qid) {
  print "failed to clear Query ID '$_'\nnot "
	unless id_clr($_);
  &ok;
  last unless @qid > 5;
}

## test 28		check that 5 items remain in cache
$idvec = mode(0);
$got = unpack("%32b*",$idvec);
print "got: $got, exp: 5\nnot "
	unless $got == 5;
&ok;

## test 29 - 33		clear the rest of the items
while ($_ = pop @qid) {
  print "failed to clear Query ID '$_'\nnot "
	unless id_clr($_);
  &ok;
}

## test 34		check that cache is empty
$idvec = mode(0);
$got = unpack("%32b*",$idvec);
print "got: $got, exp: 0\nnot "
	if $got;
&ok;
