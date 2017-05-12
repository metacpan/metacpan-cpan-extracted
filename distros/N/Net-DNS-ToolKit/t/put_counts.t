# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:constants :header);
use Net::DNS::ToolKit qw(
	newhead
	gethead
	get16
	get1char
	parse_char
	get_qdcount
	get_ancount
	get_arcount
	get_nscount
	put_qdcount
	put_ancount
	put_nscount
	put_arcount
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

## test 2	create basic header

#	 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
#	+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#	|QR|   Opcode  |AA|TC|RD|RA| Z|AD|CD|   Rcode   |
#	+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#	  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

## test 2	stuff buffer with a header
my $buffer = '';
print "bad offset $_\nnot "
    unless ($_ = newhead(\$buffer,
	54321,			# id
	QR | BITS_IQUERY | RD,	# flags
	123,			# question count
	456,			# answer count
	789,			# ns count
	10112,			# arcount
    ));
  
&ok;

## test 3	retrieve header with gethead
my($offset,$ID,$QR,$OPCODE,$AA,$TC,$RD,$RA,$Z,$AD,$CD,$RCODE,
	$QDCOUNT,$ANCOUNT,$NSCOUNT,$ARCOUNT) = gethead(\$buffer);
print "failed to retrieve header info\nnot " unless 
	$ID == 54321 &&
	$QR == 1 &&
	OpcodeTxt->{$OPCODE} eq 'IQUERY' &&
	!$TC && $RD && !$RA && !$Z && !$AD && !$CD &&
	RcodeTxt->{$RCODE} eq 'NOERROR' &&
	$QDCOUNT == 123 &&
	$ANCOUNT == 456 &&
	$NSCOUNT == 789 &&
	$ARCOUNT == 10112;
&ok;

## test 4	get qdcount
$_ = get_qdcount(\$buffer);
print "qdcount, got: $_, exp: 123\nnot "
	unless $_ == 123;
&ok;

## test 5	get ancount
$_ = get_ancount(\$buffer);
print "ancount, got: $_, exp: 456\nnot "
	unless $_ == 456;
&ok;

## test 6	get nscount
$_ = get_nscount(\$buffer);
print "nscount, got: $_, exp: 789\nnot "
	unless $_ == 789;
&ok;

## test 7	get arcount
$_ = get_arcount(\$buffer);
print "arcount, got: $_, exp: 10112\nnot "
	unless $_ == 10112;
&ok;

## test 8	put qdcount
print "offset is: $_, exp: 6\nnot "
	unless ($_ = put_qdcount(\$buffer,9999)) == 6;
&ok;

## test 9	check qd value
print "qdcount, got: $_, exp: 9999\nnot "
        unless (($_ = get_qdcount(\$buffer)) == 9999);
&ok;

## test 10	put ancount
print "offset is: $_, exp: 8\nnot "
	unless ($_ = put_ancount(\$buffer,8686)) == 8;
&ok;

## test 11	check an value
print "ancount, got: $_, exp: 8686\nnot "
        unless (($_ = get_ancount(\$buffer)) == 8686);
&ok;

## test 12	put nscount
print "offset is: $_, exp: 10\nnot "
	unless ($_ = put_nscount(\$buffer,7321)) == 10;
&ok;

## test 13	check ns value
print "nscount, got: $_, exp: 7321\nnot "
        unless (($_ = get_nscount(\$buffer)) == 7321);
&ok;

## test 14	put arcount
print "offset is: $_, exp: 12\nnot "
	unless ($_ = put_arcount(\$buffer,54321)) == 12;
&ok;

## test 15	check ar value
print "arcount, got: $_, exp: 54321\nnot "
        unless (($_ = get_arcount(\$buffer)) == 54321);
&ok;

#foreach (0..HFIXEDSZ -1) {
#  my $off = $_;
#  my $char = get1char(\$buffer,$off);
#  @x = parse_char($char);
#  print "$_\t:  ";
#  foreach(@x) {
#    print "$_  ";
#  }
#  print "\n";
#}
