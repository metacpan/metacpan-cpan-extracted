# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "could not load Net::Connection::Sniffer\nnot ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	newhead
	put1char
	inet_aton
);
use Net::DNS::Codes qw(
	C_IN
	T_PTR
	T_SOA
	QR
	NXDOMAIN
);
use Net::DNS::ToolKit::RR;

#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);

use Net::Connection::Sniffer;
*dns_rcv = \&Net::Connection::Sniffer::dns_rcv;
*_ptrs = \&Net::Connection::Sniffer::_ptrs;

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

my($stats,$dns) = &_ptrs;

my $id = 9464;
my $ip = inet_aton('66.33.20.76');

$dns->{$id} = {
	IP	=> $ip,
};
$stats->{$ip} = {
	N	=> [],
};

my($get,$put,$parse) = new Net::DNS::ToolKit::RR(C_IN);
my $buffer = '';
my @dnptrs;
my $off = 0;
my $exp  = ':test.dummy.com';
if (0) {
  $off = newhead(\$buffer,$id,QR|NXDOMAIN,1,0,1,0);

  ($off,@dnptrs) = $put->Question(\$buffer,$off,'dummy.com',T_PTR,C_IN);
  ($off,@dnptrs) = $put->SOA(\$buffer,$off,\@dnptrs,'dummy.com',2345,'test.dummy.com','root.dummy.com',765432,5000,500,200,100);
} else {
  $exp = ':ns.dialtoneinternet.net';
  my $data = q|
  0     :  0010_0100  0x24   36  $  
  1     :  1111_1000  0xF8  248    
  2     :  1000_0001  0x81  129    
  3     :  1000_0011  0x83  131    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0010  0x02    2    
  13    :  0011_0111  0x37   55  7  
  14    :  0011_0110  0x36   54  6  
  15    :  0000_0010  0x02    2    
  16    :  0011_0010  0x32   50  2  
  17    :  0011_0000  0x30   48  0  
  18    :  0000_0010  0x02    2    
  19    :  0011_0011  0x33   51  3  
  20    :  0011_0011  0x33   51  3  
  21    :  0000_0010  0x02    2    
  22    :  0011_0110  0x36   54  6  
  23    :  0011_0110  0x36   54  6  
  24    :  0000_0111  0x07    7    
  25    :  0110_1001  0x69  105  i  
  26    :  0110_1110  0x6E  110  n  
  27    :  0010_1101  0x2D   45  -  
  28    :  0110_0001  0x61   97  a  
  29    :  0110_0100  0x64  100  d  
  30    :  0110_0100  0x64  100  d  
  31    :  0111_0010  0x72  114  r  
  32    :  0000_0100  0x04    4    
  33    :  0110_0001  0x61   97  a  
  34    :  0111_0010  0x72  114  r  
  35    :  0111_0000  0x70  112  p  
  36    :  0110_0001  0x61   97  a  
  37    :  0000_0000  0x00    0    
  38    :  0000_0000  0x00    0    
  39    :  0000_1100  0x0C   12    
  40    :  0000_0000  0x00    0    
  41    :  0000_0001  0x01    1    
  42    :  1100_0000  0xC0  192    
  43    :  0000_1111  0x0F   15    
  44    :  0000_0000  0x00    0    
  45    :  0000_0110  0x06    6    
  46    :  0000_0000  0x00    0    
  47    :  0000_0001  0x01    1    
  48    :  0000_0000  0x00    0    
  49    :  0000_0000  0x00    0    
  50    :  0000_0000  0x00    0    
  51    :  0010_1101  0x2D   45  -  
  52    :  0000_0000  0x00    0    
  53    :  0011_0011  0x33   51  3  
  54    :  0000_0010  0x02    2    
  55    :  0110_1110  0x6E  110  n  
  56    :  0111_0011  0x73  115  s  
  57    :  0001_0000  0x10   16    
  58    :  0110_0100  0x64  100  d  
  59    :  0110_1001  0x69  105  i  
  60    :  0110_0001  0x61   97  a  
  61    :  0110_1100  0x6C  108  l  
  62    :  0111_0100  0x74  116  t  
  63    :  0110_1111  0x6F  111  o  
  64    :  0110_1110  0x6E  110  n  
  65    :  0110_0101  0x65  101  e  
  66    :  0110_1001  0x69  105  i  
  67    :  0110_1110  0x6E  110  n  
  68    :  0111_0100  0x74  116  t  
  69    :  0110_0101  0x65  101  e  
  70    :  0111_0010  0x72  114  r  
  71    :  0110_1110  0x6E  110  n  
  72    :  0110_0101  0x65  101  e  
  73    :  0111_0100  0x74  116  t  
  74    :  0000_0011  0x03    3    
  75    :  0110_1110  0x6E  110  n  
  76    :  0110_0101  0x65  101  e  
  77    :  0111_0100  0x74  116  t  
  78    :  0000_0000  0x00    0    
  79    :  0000_0011  0x03    3    
  80    :  0110_0100  0x64  100  d  
  81    :  0110_1110  0x6E  110  n  
  82    :  0111_0011  0x73  115  s  
  83    :  1100_0000  0xC0  192    
  84    :  0011_1001  0x39   57  9  
  85    :  0111_0111  0x77  119  w  
  86    :  1010_0001  0xA1  161    
  87    :  0000_0000  0x00    0    
  88    :  1100_1001  0xC9  201    
  89    :  0000_0000  0x00    0    
  90    :  0000_0000  0x00    0    
  91    :  0010_1010  0x2A   42  *  
  92    :  0011_0000  0x30   48  0  
  93    :  0000_0000  0x00    0    
  94    :  0000_0000  0x00    0    
  95    :  0000_1110  0x0E   14    
  96    :  0001_0000  0x10   16    
  97    :  0000_0000  0x00    0    
  98    :  0000_1001  0x09    9    
  99    :  0011_1010  0x3A   58  :  
  100   :  1000_0000  0x80  128    
  101   :  0000_0000  0x00    0    
  102   :  0000_0000  0x00    0    
  103   :  0000_1110  0x0E   14    
  104   :  0001_0000  0x10   16    
|;
  foreach (split("\n",$data)) {
    next unless $_ =~ /0x[^\s]+/;
    my $n = eval "$&";
    $off = put1char(\$buffer,$off,$n);
  }
}

#print_head(\$buffer);
#print_buf(\$buffer);

dns_rcv($off,$buffer);
print 'got: ',$stats->{$ip}->{N}->[0], "\nexp: $exp\nnot "
	unless $stats->{$ip}->{N}->[0] eq $exp;
&ok;



