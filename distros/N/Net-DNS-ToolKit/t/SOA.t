# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	put16
	get1char
	parse_char
	newhead
	dn_comp
	put_qdcount
);
use Net::DNS::ToolKit::Debug qw(
	print_head
	print_buf
);
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit::RR::SOA;

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

## test 2	setup, generate a header for a question

my $buffer = '';
my $off = newhead(\$buffer,
	12345,			# id
	QR | BITS_QUERY | RD | RA,	# query response, query, recursion desired, recursion available
);

print "bad question size $off\nnot "
	unless $off == NS_HFIXEDSZ;
&ok;

sub expect {
  my $x = shift;
  my @exp;
  foreach(split(/\n/,$x)) {
    if ($_ =~ /0x\w+\s+(\d+) /) {
      push @exp,$1;
    }
  }
  return @exp;
}

sub print_ptrs {
  foreach(@_) {
    print "$_ ";
  }
  print "\n";
}

sub chk_exp {
  my($bp,$exp) = @_;
  my @expect = expect($$exp);
  foreach(0..length($$bp) -1) {
    $char = get1char($bp,$_);
    next if $char == $expect[$_];
    print "buffer mismatch $_, got: $char, exp: $expect[$_]\nnot ";
    last;
  }
  &ok;
}

## test 3	setup, append question
# expect this from print_buf
my $exptext = q(
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0001  0x81  129    
  3     :  1000_0000  0x80  128    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0110  0x66  102  f  
  14    :  0110_1111  0x6F  111  o  
  15    :  0110_1111  0x6F  111  o  
  16    :  0000_0011  0x03    3    
  17    :  0110_0010  0x62   98  b  
  18    :  0110_0001  0x61   97  a  
  19    :  0111_0010  0x72  114  r  
  20    :  0000_0011  0x03    3    
  21    :  0110_0011  0x63   99  c  
  22    :  0110_1111  0x6F  111  o  
  23    :  0110_1101  0x6D  109  m  
  24    :  0000_0000  0x00    0    
  25    :  0000_0000  0x00    0    
  26    :  0000_0001  0x01    6    
  27    :  0000_0000  0x00    0    
  28    :  0000_0001  0x01    1    
);

my $name = 'foo.bar.com';
my @dnptrs;
($off,@dnptrs)=dn_comp(\$buffer,$off,\$name);
# push on some stuff that looks like a question
$off = put16(\$buffer,$off,T_SOA);
$off = put16(\$buffer,$off,C_IN);
put_qdcount(\$buffer,1);
#print_head(\$buffer);
#print_buf(\$buffer);
#print_ptrs(@dnptrs);
chk_exp(\$buffer,\$exptext);

#######################################

## test 4	put SOA record
#	This is what we must test

#  ($newoff,$name,$type,$class,$ttl,$rdlength,
#        $rdata,...) = $get->XYZ(\$buffer,$offset);
#
#  ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,   
#        $name,$type,$class,$ttl,$rdlength,$rdata,...);
#
#  $name,$TYPE,$CLASS,$TTL,$rdlength,$IPaddr) 
#    = $parse->XYZ($name,$type,$class,$ttl,$rdlength,
#        $rdata,...);

my $module = 'Net::DNS::ToolKit::RR::SOA';

$exptext = q(
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0001  0x81  129    
  3     :  1000_0000  0x80  128    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0110  0x66  102  f  
  14    :  0110_1111  0x6F  111  o  
  15    :  0110_1111  0x6F  111  o  
  16    :  0000_0011  0x03    3    
  17    :  0110_0010  0x62   98  b  
  18    :  0110_0001  0x61   97  a  
  19    :  0111_0010  0x72  114  r  
  20    :  0000_0011  0x03    3    
  21    :  0110_0011  0x63   99  c  
  22    :  0110_1111  0x6F  111  o  
  23    :  0110_1101  0x6D  109  m  
  24    :  0000_0000  0x00    0    
  25    :  0000_0000  0x00    0    
  26    :  0000_0110  0x06    6    
  27    :  0000_0000  0x00    0    
  28    :  0000_0001  0x01    1    
  29    :  0000_0000  0x00    0    
  30    :  0010_0001  0x21   33    
  31    :  0000_0011  0x03    3    
  32    :  0110_1110  0x6E  110  n  
  33    :  0111_0011  0x73  115  s  
  34    :  0011_0001  0x31   49  1  
  35    :  1100_0000  0xC0  192    
  36    :  0001_0000  0x10   16    
  37    :  0000_0100  0x04    4    
  38    :  0111_0010  0x72  114  r  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_1111  0x6F  111  o  
  41    :  0111_0100  0x74  116  t  
  42    :  1100_0000  0xC0  192    
  43    :  0001_0000  0x10   16    
  44    :  0011_1010  0x3A   58  :  
  45    :  1101_1110  0xDE  222    
  46    :  0110_1000  0x68  104  h  
  47    :  1011_0001  0xB1  177    
  48    :  0000_0000  0x00    0    
  49    :  0000_0001  0x01    1    
  50    :  0101_0001  0x51   81  Q  
  51    :  1000_0000  0x80  128    
  52    :  0000_0000  0x00    0    
  53    :  0000_0001  0x01    1    
  54    :  0000_0000  0x00    0    
  55    :  0000_0001  0x01    1    
  56    :  0000_0000  0x00    0    
  57    :  0000_0001  0x01    1    
  58    :  1000_0010  0x82  130    
  59    :  1011_1000  0xB8  184    
  60    :  0000_0000  0x00    0    
  61    :  0000_0001  0x01    1    
  62    :  0101_0110  0x56   86  V  
  63    :  0110_0110  0x66  102  f  
);
$mname = 'ns1.bar.com';
$rname = 'root.bar.com';
# all 32 bit values
$serial = 987654321;
$refresh = 86400;
$retry	= 65537;
$expire = 99000;
$min	= 87654;
### offset from above = 29
(my $newoff, @dnptrs) = $module->put(\$buffer,$off,\@dnptrs,$mname,$rname,$serial,$refresh,$retry,$expire,$min);
#print_buf(\$buffer);
#print_ptrs(@dnptrs);
chk_exp(\$buffer,\$exptext);      

## test 5	test get

my $start = 29;	# from above
my($getoff,$newmname,$newrname,$newserial,$newrefresh,$newretry,$newexpire,$newmin) = $module->get(\$buffer,$start);
# check offset against PUT operation above
print "bad offset, $getoff, exp: $newoff\nnot "
  unless $getoff == $newoff;
&ok;

## test 6	verify mname
print "bad mname\ngot: $newmname\nexp: $mname\nnot "
	unless $newmname eq $mname;
&ok;

## test 7	verify rname
print "bad rname\ngot: $newrname\nexp: $rname\nnot "
	unless $newrname eq $rname;
&ok;

## test 8	verify serial
print "serial, got: $newserial, exp: $serial\nnot "
	unless $newserial == $serial;
&ok;

## test 9	verify refresh
print "refresh, got: $newrefresh, exp: $refresh\nnot "
	unless $newrefresh == $refresh;
&ok;

## test 10	verify retry
print "retry, got: $newretry, exp: $retry\nnot "
	unless $newretry == $retry;
&ok;

## test 11	verify expire
print "expire, got: $newexpire, exp: $expire\nnot "
	unless $newexpire == $expire;
&ok;

## test 12	verify min
print "min, got: $newmin, exp: $min\nnot "
	unless $newmin == $min;
&ok;

## test 13	check parse
my @in = ('texta','textb',1,2,3,4,5);

## number of elements
my @out = $module->parse(@in);
$in[0] .= '.';
$in[1] .= '.';
print 'wrong number of elements', (scalar @out), 'exp: ',(scalar @in),"\nnot "
	unless @in == @out;
&ok;

## test 14	check data
foreach(0..$#in) {
  if ($in[$_] =~ /\D/) {
    next if $in[$_] eq $out[$_];
  } else {
    next if $in[$_] == $out[$_];
  }
  print "got: $out[$_], exp: $in[$_]\nnot ";
  last;
}
&ok;
