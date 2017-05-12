# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "could not load Net::Connection::Sniffer\nnot ok 1\n" unless $loaded;}

use Test::Harness;
use Net::Connection::Sniffer qw(:init);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

require './recurse2txt';

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2	check initialization of internal vars
## 	   ($now, $start, $rate, $bw) =
my @in = qw(9876   1098   7654   3210);
p2xs_gvars(@in);
my @out = xs2p_gvars();
my $in = @in;
my $out = @out;
print "Bail out! got: $out args, exp: $in args\nnot "
	unless $in == $out;
&ok;

## test 3 - 6	check return values of internal vars
foreach(0..$#in) {
  print "got: $out[$_], exp: $in[$_]\nnot "
	unless $in[$_] == $out[$_];
  &ok;
}

## test 7	# check hash init and return values


$hp = {};

my $len = 234;
my $exp = 
qq|8	= {
	'B'	=> $len,
	'C'	=> 1,
	'E'	=> $in[0],
	'N'	=> [],
	'R'	=> 0,
	'S'	=> $in[1],
	'T'	=> 0,
	'W'	=> 0,
};
|;

init_hv($hp,$len);
my $got = Dumper($hp);
print "got: |$got|\nexp: |$exp|\nnot "
	unless $got eq $exp;
&ok;
