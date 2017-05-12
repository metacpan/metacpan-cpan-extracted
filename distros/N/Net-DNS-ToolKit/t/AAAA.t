# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	get16
	put16
	getIPv6
	ipv6_aton
	ipv6_n2x
	get1char
	parse_char
);
use Net::DNS::Codes qw(:constants);
use Net::DNS::ToolKit::RR::AAAA;

use Net::DNS::ToolKit::Debug qw(print_buf);

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

##	This is what we must test

#  ($newoff,$name,$type,$class,$ttl,$rdlength,
#        $rdata,...) = $get->XYZ(\$buffer,$offset);
#
#  ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,   
#        $name,$type,$class,$ttl,$rdlength,$rdata,...);
#
#  $name,$TYPE,$CLASS,$TTL,$rdlength,$IPaddr) 
#    = $parse->XYZ($name,$type,$class,$ttl,$rdlength,
#        $rdata,...);

## test 2	add stuff to buffer
my $buffer = '';
my @array = (5,4,3,2,1);

my $module = 'Net::DNS::ToolKit::RR::AAAA';

my $expoff = &NS_IN6ADDRSZ + &NS_INT16SZ;
my $IP6addr = 'AFE:B01:C02:D03:E04:F05:906:807';
my $ipv6addr = ipv6_aton($IP6addr);
my ($rv,@retary) = $module->put(\$buffer,0,\@array,$ipv6addr);
print "offset is: $rv, exp: $expoff\nnot "
	unless $rv == $expoff;
&ok;

## test 3	verify that array came back
print "array is wrong size\nnot "
	unless @array == @retary;
&ok;

## test 4	check that this is really the array we sent
foreach(0..$#array) {
  next if $array[$_] == $retary[$_];
  print "array contents are different\nnot ";
  last;
}
&ok;

## test 5	verify buffer contents the hard way
my @exp = (0,16,0xa,0xfe,0xb,1,0xc,2,0xd,3,0xe,4,0xf,5,9,6,8,7);

#  0     :  0000_0000  0x00    0    16 bit int
#  1     :  0001_0000  0x10   16    rdlength
#  2     :  0000_1010  0x0A   10    ipv6 address, 16 bytes
#  3     :  1111_1110  0xFE  254    
#  4     :  0000_1011  0x0B   11    
#  5     :  0000_0001  0x01    1    
#  6     :  0000_1100  0x0C   12    
#  7     :  0000_0010  0x02    2    
#  8     :  0000_1101  0x0D   13    
#  9     :  0000_0011  0x03    3    
#  10    :  0000_1110  0x0E   14    
#  11    :  0000_0100  0x04    4    
#  12    :  0000_1111  0x0F   15    
#  13    :  0000_0101  0x05    5    
#  14    :  0000_1001  0x09    9    
#  15    :  0000_0110  0x06    6    
#  16    :  0000_1000  0x08    8    
#  17    :  0000_0111  0x07    7    

#print_buf(\$buffer);

foreach(0..$expoff -1) {
  my $char = get1char(\$buffer,$_);
  if ($char != $exp[$_]) {
    printf "exp: %02X, got: %02X\nnot ",$exp[$_],$char;
    last;
  }
}
&ok;

## test 6	get IP6addr back
($rv, my $taddr) = $module->get(\$buffer,0);
my $Taddr = ipv6_n2x($taddr);
print "got: $Taddr, exp: $IP6addr\nnot "
	unless $Taddr eq $IP6addr;
&ok;

## test 7	check offset returned
print "offset got: $rv, exp: $expoff\nnot "
	unless $rv == $expoff;
&ok;

## test 8	check parse
my $prv = $module->parse($taddr);
print "parse failed .. got: $prv, exp: $IP6addr\nnot "
	unless $prv eq $IP6addr;
&ok;

