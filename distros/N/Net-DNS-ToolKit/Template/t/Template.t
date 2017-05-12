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
	getIPv4
	inet_ntoa
	inet_aton
	get1char
	parse_char
);
use Net::DNS::Codes qw(:constants);
use Net::DNS::ToolKit::RR::Template;

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

my $module = 'Net::DNS::ToolKit::RR::Template';

my $expoff = &NS_INADDRSZ + &NS_INT16SZ;
my $IPaddr = '172.16.54.32';
my $netaddr = inet_aton($IPaddr);
my ($rv,@retary) = $module->put(\$buffer,0,\@array,$netaddr);
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
my @exp = (0,4,172,16,54,32);

# 00 0000_0000  0x00    0 	16 bit int
# 01 0000_0100  0x04    4 	rdlength
# 02 1010_1100  0xAC  172 
# 03 0001_0000  0x10   16 	32 bit netaddr
# 04 0011_0110  0x36   54 6	172.16.54.32
# 05 0010_0000  0x20   32  

foreach(0..$expoff -1) {
  my $char = get1char(\$buffer,$_);
#  @_ = parse_char($char); printf "%02d %s  %s  %s %s\n",$_,$_[0],$_[1],$_[2],$_[3];
  if ($char != $exp[$_]) {
    printf "exp: %02X, got: %02X\nnot ",$exp[$_],$char;
    last;
  }
}
&ok;

## test 6	get IPaddr back
($rv, my $taddr) = $module->get(\$buffer,0);
my $Taddr = inet_ntoa($taddr);
print "got: $Taddr, exp: $IPaddr\nnot "
	unless $Taddr eq $IPaddr;
&ok;

## test 7	check offset returned
print "offset got: $rv, exp: $expoff\nnot "
	unless $rv == $expoff;
&ok;

## test 8	check parse
my $prv = $module->parse($taddr);
print "parse failed .. got: $prv, exp: $IPaddr\nnot "
	unless $prv eq $IPaddr;
&ok
