# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..29\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:constants);

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

## test 2-29 check class codes
my %constants = (qw(
	NS_PACKETSZ     512
	NS_MAXDNAME     1025
	NS_MAXCDNAME    255
	NS_MAXLABEL     63
	NS_HFIXEDSZ     12
	NS_QFIXEDSZ     4
	NS_RRFIXEDSZ    10
	NS_INT32SZ      4
	NS_INT16SZ      2
	NS_INT8SZ       1
	NS_INADDRSZ     4
	NS_IN6ADDRSZ    16
	NS_DEFAULTPORT  53
	PACKETSZ     512
	MAXDNAME     1025
	MAXCDNAME    255
	MAXLABEL     63
	HFIXEDSZ     12
	QFIXEDSZ     4
	RRFIXEDSZ    10
	INT32SZ      4
	INT16SZ      2
	INT8SZ       1
	INADDRSZ     4
	IN6ADDRSZ    16
	NAMESERVER_PORT  53
	),
  (	NS_CMPRSFLGS	=> 0xc0,
	INDIR_MASK	=> 0xc0,
  )
);

foreach(sort keys %constants) {
  my $value = eval($_);
  printf("constant %s\ngot: %d\nexp: %d\nnot ",$_,$value,$constants{$_})
	unless $value == $constants{$_};
  &ok;
}

