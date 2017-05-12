# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#	proc_head.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	newhead
);
use Net::DNS::ToolKit::RR;
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);
use Net::DNS::Dig;

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

require './recurse2txt';

*proc_head = \&Net::DNS::Dig::_proc_head;

# test 2	parse buffer with no object, no answer
my $buf = '';
newhead(\$buf,
	1234,
	QR | BITS_QUERY | RD | TC | AD | YXDOMAIN,
	1, 0, 3, 4				# answer count 0
);

my($offset,$rcode,$qdcount,$ancount,$nscount,$arcount)
	= proc_head(\$buf);
print "offset is defined\nnot "
	if defined $offset;
&ok;

## test 3	validate defined counts
print "undefined counts\nnot "
	if ! defined $qdcount || ! defined $ancount || ! defined $nscount || ! defined $arcount;
&ok;

## test 4	validate zero counts
print "non zero counts\nnot "
	if $qdcount || $ancount || $nscount || $arcount;
&ok;

## test 5	validate YXDOMAIN
print "bad response code\ngot: $rcode - exp: 6\nnot "	# expected YXDOMAIN => 6
	unless $rcode == 6;
&ok;

## test 6	parse buffer with no object, with answer
$buf = '';
newhead(\$buf,
	1234,
	QR | BITS_QUERY | RD | TC | AD | NXDOMAIN,
	1, 2, 3, 4				# answer count non-zero
);

($offset,$rcode,$qdcount,$ancount,$nscount,$arcount)
	= proc_head(\$buf);
print "offset is not defined\nnot "
	unless defined $offset && $offset == &HFIXEDSZ;
&ok;

## test 7	validate defined counts
print "undefined counts\nnot "
	if ! defined $qdcount || ! defined $ancount || ! defined $nscount || ! defined $arcount;
&ok;

## test 8	validate non zero counts
print "non zero counts\nnot "
	if !$qdcount || !$ancount || !$nscount || !$arcount;
&ok;

## test 9	validate NXDOMAIN
print "bad response code\ngot: $rcode - exp: 6\nnot "	# expected NXDOMAIN => 3
	unless $rcode == 3;
&ok;

## test 10	build response object, must do so even with zero answers
$buf = '';
newhead(\$buf,
	1234,
	QR | BITS_NS_UPDATE_OP | RD | TC | AD | FORMERR,
	1, 0, 3, 4				# answer count 0
);

my $obj = {};

($offset,$rcode,$qdcount,$ancount,$nscount,$arcount)
	= proc_head(\$buf,$obj);
print "offset is not defined\nnot "
	unless defined $offset && $offset == &HFIXEDSZ;
&ok;

## test 11	validate defined counts
print "undefined counts\nnot "
	if ! defined $qdcount || ! defined $ancount || ! defined $nscount || ! defined $arcount;
&ok;

## test 12	validate non zero counts except ancount
print "non zero counts\nnot "
	if !$qdcount || $ancount || !$nscount || !$arcount;
&ok;

## test 13	validate count values
print "bad count values\nnot "
	unless $qdcount == 1 && $ancount == 0 && $nscount == 3 && $arcount == 4;
&ok;

## test 14	validate NXDOMAIN
print "bad response code\ngot: $rcode - exp: 1\nnot "	# expected FORMERR => 1
	unless $rcode == 1;
&ok;

## test 15	check response array
my $exp = q|16	= {
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 1,
		'ANCOUNT'	=> 0,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 1234,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 3,
		'OPCODE'	=> 5,
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 0,
		'RCODE'	=> 1,
		'RD'	=> 1,
		'TC'	=> 1,
	},
};
|;
my $got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;
