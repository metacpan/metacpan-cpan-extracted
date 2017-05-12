# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::Bind::rbldnsdAccessor qw(
	RBLF_DLEN
	rblf_strncpy
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

################################################################
################################################################

my $RBLF_DLEN = RBLF_DLEN;

my $string = "the quick brown fox jumped over the lazy dog 1234567890
THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG 0123456789\n";

my $len = length($string);

## test 2	check overrun condition
my($rlen,$rv);
eval {
  ($rlen,$rv) = rblf_strncpy($string,$RBLF_DLEN,'Z');
};
print "failed to detect buffer over-run condition\nnot "
	unless $@ && $@ =~ /$RBLF_DLEN/;
&ok;

## test 3	check for max chars xfered
my $max = int $len/2;
$string =~ /(.+890\n)/;
my $fill = 'Z';
my $exp = $1;
($rlen,$rv) = rblf_strncpy($string,$max,$fill);
print "got: $rlen, exp: $max\nnot "
	unless $rlen == $max;
&ok;

## test 4	check null termination
my($got,$end) = split(/\0/,$rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 5	check end stuff
my $p = "[${fill}]{". ($RBLF_DLEN -$max -1) .',}';
print "got:\n|$end|\nexp: string of '${fill}'s\nnot "
	unless $end =~ /^$p/;
&ok;

## test 6	check that ends match
print "got:\n$end\nexp:\n$&\nnot "
	unless $end eq $&;
&ok;

## test 7	check that end is right size
$exp = $RBLF_DLEN - $max -1;
print "got: $_, exp: $exp\nnot "
	unless ($_ = length($end)) == $exp;
&ok;

###### try with big max, little string

## test 8	test for 'len' chars xfered
($rlen,$rv) = rblf_strncpy($string,$len,$fill);
print "got: $rlen, exp: $len\nnot "
	unless $rlen == $len;
&ok;

## test 9	test for null termination
($got,$end) = split(/\0/,$rv);
print "got: $got\nexp: $string\nnot "
	unless $got eq $string;
&ok;

## test 10	check end stuff
$p = "[${fill}]{". ($RBLF_DLEN -$rlen -1) .',}';
print "got:\n|$end|\nexp: string of '${fill}'s\nnot "
	unless $end =~ /^$p/;
&ok;

## test 11	check that ends match
print "got:\n$end\nexp:\n$&\nnot "
	unless $end eq $&;
&ok;

## test 12	check that end is right size
$exp = $RBLF_DLEN - $len -1;
print "got: $_, exp: $exp\nnot "
	unless ($_ = length($end)) == $exp;
&ok;
