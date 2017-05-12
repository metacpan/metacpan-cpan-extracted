# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:constants);
use Net::DNS::ToolKit qw(
	get16
	get32
	put16
	put32
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

my $buffer = '';
my $rv;
## test 2	put and retrieve offset
my $off = put16(\$buffer,0,1234);
print "bad offset: $off, exp: 2\nnot "
	unless $off == NS_INT16SZ;
&ok;

## test 3	get value as scalar
$rv = get16(\$buffer,0);
print "bad value: $rv, exp: 1234\nnot "
	unless $rv == 1234;
&ok;

## test 4	get value and offset in array
($rv,$off) = get16(\$buffer,0);
print "got: rv=$rv, off=$off, exp: 1234, 2\nnot "
	unless $rv == 1234 && $off == NS_INT16SZ;
&ok;

## test 5	test bad reference
$buffer = '';
print "not bad ref\nnot "
	if defined put16($buffer,0,1234);
&ok;

## test 6	push beyond end of buffer
print "failed to detect buffer overrun\nnot "
	if defined put16(\$buffer,1,1234);
&ok;

## test 7	try to save a long
print "should not save longs\nnot "
	if defined put16(\$buffer,0,65536);
&ok;

########## long tests ####################
$buffer = '';
## test 8	put and retrieve offset -- LONG
$off = put32(\$buffer,0,71234);
print "bad offset: $off, exp: NS_INT32SZ\nnot "
	unless $off == NS_INT32SZ;
&ok;

## test 9	get value as scalar
$rv = get32(\$buffer,0);
print "bad value: $rv, exp: 71234\nnot "
	unless $rv == 71234;
&ok;

## test 10	get value and offset in array
($rv,$off) = get32(\$buffer,0);
print "got: rv=$rv, off=$off, exp: 71234, 4\nnot "
	unless $rv == 71234 && $off == NS_INT32SZ;
&ok;

## test 11	add a second item to buffer
put32(\$buffer,$off,88376);
($rv,$off) = get32(\$buffer,$off);
print "got: rv=$rv, off=$off, exp: 88376, 8\nnot "
	unless $rv == 88376 && $off == &NS_INT32SZ * 2;
&ok;

## test 12	push beyond end of buffer
print "failed to detect buffer overrun\nnot "
	if defined put32(\$buffer,++$off,1234);   
&ok;
