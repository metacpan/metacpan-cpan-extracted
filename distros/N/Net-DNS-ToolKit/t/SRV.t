# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
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
use Net::DNS::ToolKit::RR::SRV;

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
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0001  0x81  129    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0000  0x00    0    
  8	:  0000_0000  0x00    0    
  9	:  0000_0000  0x00    0    
  10	:  0000_0000  0x00    0    
  11	:  0000_0000  0x00    0    
  12	:  0000_1001  0x09    9    
  13	:  0101_1111  0x5F   95  _  
  14	:  0111_0100  0x74  116  t  
  15	:  0110_0101  0x65  101  e  
  16	:  0111_0011  0x73  115  s  
  17	:  0111_0100  0x74  116  t  
  18	:  0110_0011  0x63   99  c  
  19	:  0110_1111  0x6F  111  o  
  20	:  0110_0100  0x64  100  d  
  21	:  0110_0101  0x65  101  e  
  22	:  0000_0100  0x04    4    
  23	:  0101_1111  0x5F   95  _  
  24	:  0111_0100  0x74  116  t  
  25	:  0110_0011  0x63   99  c  
  26	:  0111_0000  0x70  112  p  
  27	:  0000_1001  0x09    9    
  28	:  0111_0100  0x74  116  t  
  29	:  0110_0101  0x65  101  e  
  30	:  0111_0011  0x73  115  s  
  31	:  0111_0100  0x74  116  t  
  32	:  0110_0110  0x66  102  f  
  33	:  0110_1111  0x6F  111  o  
  34	:  0111_0010  0x72  114  r  
  35	:  0110_1101  0x6D  109  m  
  36	:  0110_0101  0x65  101  e  
  37	:  0000_0011  0x03    3    
  38	:  0110_0011  0x63   99  c  
  39	:  0110_1111  0x6F  111  o  
  40	:  0110_1101  0x6D  109  m  
  41	:  0000_0000  0x00    0    
  42	:  0000_0000  0x00    0    
  43	:  0010_0001  0x21   33  !  
  44	:  0000_0000  0x00    0    
  45	:  0000_0001  0x01    1    
);

my $name = '_testcode._tcp.testforme.com';
my @dnptrs;
($off,@dnptrs)=dn_comp(\$buffer,$off,\$name);
# push on some stuff that looks like a question
$off = put16(\$buffer,$off,T_SRV);
$off = put16(\$buffer,$off,C_IN);
put_qdcount(\$buffer,1);
#print_head(\$buffer);
#print_buf(\$buffer);
#print_ptrs(@dnptrs);
chk_exp(\$buffer,\$exptext);

#######################################

## test 4	put SRV record
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

my $module = 'Net::DNS::ToolKit::RR::SRV';

$exptext = q(
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0001  0x81  129    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0000  0x00    0    
  8	:  0000_0000  0x00    0    
  9	:  0000_0000  0x00    0    
  10	:  0000_0000  0x00    0    
  11	:  0000_0000  0x00    0    
  12	:  0000_1001  0x09    9    
  13	:  0101_1111  0x5F   95  _  
  14	:  0111_0100  0x74  116  t  
  15	:  0110_0101  0x65  101  e  
  16	:  0111_0011  0x73  115  s  
  17	:  0111_0100  0x74  116  t  
  18	:  0110_0011  0x63   99  c  
  19	:  0110_1111  0x6F  111  o  
  20	:  0110_0100  0x64  100  d  
  21	:  0110_0101  0x65  101  e  
  22	:  0000_0100  0x04    4    
  23	:  0101_1111  0x5F   95  _  
  24	:  0111_0100  0x74  116  t  
  25	:  0110_0011  0x63   99  c  
  26	:  0111_0000  0x70  112  p  
  27	:  0000_1001  0x09    9    
  28	:  0111_0100  0x74  116  t  
  29	:  0110_0101  0x65  101  e  
  30	:  0111_0011  0x73  115  s  
  31	:  0111_0100  0x74  116  t  
  32	:  0110_0110  0x66  102  f  
  33	:  0110_1111  0x6F  111  o  
  34	:  0111_0010  0x72  114  r  
  35	:  0110_1101  0x6D  109  m  
  36	:  0110_0101  0x65  101  e  
  37	:  0000_0011  0x03    3    
  38	:  0110_0011  0x63   99  c  
  39	:  0110_1111  0x6F  111  o  
  40	:  0110_1101  0x6D  109  m  
  41	:  0000_0000  0x00    0    
  42	:  0000_0000  0x00    0    
  43	:  0010_0001  0x21   33  !  
  44	:  0000_0000  0x00    0    
  45	:  0000_0001  0x01    1    
  46	:  0000_0000  0x00    0    
  47	:  0001_0100  0x14   20    
  48	:  1101_0100  0xD4  212    
  49	:  0011_0001  0x31   49  1  
  50	:  0001_1010  0x1A   26    
  51	:  0101_0110  0x56   86  V  
  52	:  0010_1011  0x2B   43  +  
  53	:  1101_0111  0xD7  215    
  54	:  0000_0100  0x04    4    
  55	:  0110_1101  0x6D  109  m  
  56	:  0111_1000  0x78  120  x  
  57	:  0011_1001  0x39   57  9  
  58	:  0011_1001  0x39   57  9  
  59	:  0000_0011  0x03    3    
  60	:  0110_0010  0x62   98  b  
  61	:  0110_0001  0x61   97  a  
  62	:  0111_0010  0x72  114  r  
  63	:  0000_0011  0x03    3    
  64	:  0110_0011  0x63   99  c  
  65	:  0110_1111  0x6F  111  o  
  66	:  0110_1101  0x6D  109  m  
  67	:  0000_0000  0x00    0    
);
my $target = 'mx99.bar.com';
my $priority	= 54321;
my $weight	= 6742;
my $port	= 11223;
### offset from above = 46
(my $newoff, @dnptrs) = $module->put(\$buffer,$off,\@dnptrs,$priority,$weight,$port,$target);
#print_buf(\$buffer);
#print_ptrs(@dnptrs);
chk_exp(\$buffer,\$exptext);      

$off = $newoff;

## test 5	test get

my $start = 46;	# from above
($newoff,$npriority,$nweight,$nport,$ntarget) = $module->get(\$buffer,$start);
# check offset against PUT operation above
print "bad offset, $newoff, exp: $off\nnot "
  unless $newoff == $off;
&ok;

## test 6	verify priority
print "bad priority, $npriority, exp: $priority\nnot "
	unless $npriority == $priority;
&ok;

## test 7	verify weight
print "bad weight\ngot: $nweight\nexp: $weight\nnot "
	unless $nweight == $weight;
&ok;

## test 8	verify port
print "bad port, $nport, exp: $port\nnot "
	unless $nport == $port;
&ok;

## test 9	verify target
print "bad target\ngot: $ntarget\nexp: $target\nnot "
	unless $ntarget eq $target;
&ok;

## test 10-13	check parse
($npriority,$nweight,$nport,$ntarget) = $module->parse($priority,$weight,$port,$target);

## test 10	verify priority
print "bad priority, $npriority, exp: $priority\nnot "
	unless $npriority == $priority;
&ok;

## test 11	verify weight
print "bad weight\ngot: $nweight\nexp: $weight\nnot "
	unless $nweight == $weight;
&ok;

## test 12	verify port
print "bad port, $nport, exp: $port\nnot "
	unless $nport == $port;
&ok;

## test 13	verify target
$target .= '.';
print "bad target\ngot: $ntarget\nexp: $target\nnot "
	unless $ntarget eq $target;
&ok;
