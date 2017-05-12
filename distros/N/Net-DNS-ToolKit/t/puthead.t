# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:constants :header);
use Net::DNS::ToolKit qw(
	newhead
	gethead
	getflags
	putflags
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

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

## test 4	retrieve flags and update RCODE
my $flags = getflags(\$buffer);
$flags |= SERVFAIL;

# put the flags back
putflags(\$buffer,$flags);

# retrieve header with gethead and retest
($offset,$ID,$QR,$OPCODE,$AA,$TC,$RD,$RA,$Z,$AD,$CD,$RCODE,
	$QDCOUNT,$ANCOUNT,$NSCOUNT,$ARCOUNT) = gethead(\$buffer);
print "failed to retrieve header info\nnot " unless
	$ID == 54321 &&
	$QR == 1 &&
	OpcodeTxt->{$OPCODE} eq 'IQUERY' &&
	!$TC && $RD && !$RA && !$Z && !$AD && !$CD &&
	RcodeTxt->{$RCODE} eq 'SERVFAIL' &&
	$QDCOUNT == 123 &&
	$ANCOUNT == 456 &&
	$NSCOUNT == 789 &&
	$ARCOUNT == 10112;
&ok;

## test 5	retrieve flags and update OPCODE to 
#		NS_UPDATE_OP = BITS_IQUERY | BITS_NS_NOTIFY_OP
#		NOTZONE = SERVFAIL | NXRRSET
$flags |= BITS_NS_NOTIFY_OP;
$flags |= NXRRSET;
putflags(\$buffer,$flags);

# retrieve header with gethead and retest
($offset,$ID,$QR,$OPCODE,$AA,$TC,$RD,$RA,$Z,$AD,$CD,$RCODE,
	$QDCOUNT,$ANCOUNT,$NSCOUNT,$ARCOUNT) = gethead(\$buffer);
print "failed to retrieve header info\nnot " unless
	$ID == 54321 &&
	$QR == 1 &&
	OpcodeTxt->{$OPCODE} eq 'NS_UPDATE_OP' &&
	!$TC && $RD && !$RA && !$Z && !$AD && !$CD &&
	RcodeTxt->{$RCODE} eq 'NOTZONE' &&
	$QDCOUNT == 123 &&
	$ANCOUNT == 456 &&
	$NSCOUNT == 789 &&
	$ARCOUNT == 10112;
&ok;
