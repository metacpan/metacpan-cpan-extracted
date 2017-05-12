# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNSBL::Utilities qw(
	not_found
);

use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	newhead
	get1char
);
use Net::DNS::ToolKit::Debug qw(
        print_head
        print_buf
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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

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
  my $todo = '';
  my @expect = expect($$exp);
  foreach(0..length($$bp) -1) {
    $char = get1char($bp,$_);
    next if $char == $expect[$_];
    print "buffer mismatch $_, got: $char, exp: $expect[$_]\nnot ";
    $todo = 'fix test for marginal dn_comp resolver implementations';
    last;
  }
  &ok($todo);
}

my $now = time;
my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
my $SOAptr = [        # set up bogus SOA
        'blacklisted.com',
        T_SOA,
        C_IN,
        0,              # ttl of SOA record
        'localhost',
        'root.localhost',
        12345678,
        86401,
        86402,
        86403,
        86404,
];
my $buf;

not_found($put,'somename.com',T_ANY,'23456',\$buf,$SOAptr);

my $expected = q|
  0     :  0101_1011  0x5B   91  [  
  1     :  1010_0000  0xA0  160    
  2     :  1000_0000  0x80  128    
  3     :  0000_0011  0x03    3    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_1000  0x08    8    
  13    :  0111_0011  0x73  115  s  
  14    :  0110_1111  0x6F  111  o  
  15    :  0110_1101  0x6D  109  m  
  16    :  0110_0101  0x65  101  e  
  17    :  0110_1110  0x6E  110  n  
  18    :  0110_0001  0x61   97  a  
  19    :  0110_1101  0x6D  109  m  
  20    :  0110_0101  0x65  101  e  
  21    :  0000_0011  0x03    3    
  22    :  0110_0011  0x63   99  c  
  23    :  0110_1111  0x6F  111  o  
  24    :  0110_1101  0x6D  109  m  
  25    :  0000_0000  0x00    0    
  26    :  0000_0000  0x00    0    
  27    :  1111_1111  0xFF  255    
  28    :  0000_0000  0x00    0    
  29    :  0000_0001  0x01    1    
  30    :  0000_1011  0x0B   11    
  31    :  0110_0010  0x62   98  b  
  32    :  0110_1100  0x6C  108  l  
  33    :  0110_0001  0x61   97  a  
  34    :  0110_0011  0x63   99  c  
  35    :  0110_1011  0x6B  107  k  
  36    :  0110_1100  0x6C  108  l  
  37    :  0110_1001  0x69  105  i  
  38    :  0111_0011  0x73  115  s  
  39    :  0111_0100  0x74  116  t  
  40    :  0110_0101  0x65  101  e  
  41    :  0110_0100  0x64  100  d  
  42    :  1100_0000  0xC0  192    
  43    :  0001_0101  0x15   21    
  44    :  0000_0000  0x00    0    
  45    :  0000_0110  0x06    6    
  46    :  0000_0000  0x00    0    
  47    :  0000_0001  0x01    1    
  48    :  0000_0000  0x00    0    
  49    :  0000_0000  0x00    0    
  50    :  0000_0000  0x00    0    
  51    :  0000_0000  0x00    0    
  52    :  0000_0000  0x00    0    
  53    :  0010_0110  0x26   38  &  
  54    :  0000_1001  0x09    9    
  55    :  0110_1100  0x6C  108  l  
  56    :  0110_1111  0x6F  111  o  
  57    :  0110_0011  0x63   99  c  
  58    :  0110_0001  0x61   97  a  
  59    :  0110_1100  0x6C  108  l  
  60    :  0110_1000  0x68  104  h  
  61    :  0110_1111  0x6F  111  o  
  62    :  0111_0011  0x73  115  s  
  63    :  0111_0100  0x74  116  t  
  64    :  0000_0000  0x00    0    
  65    :  0000_0100  0x04    4    
  66    :  0111_0010  0x72  114  r  
  67    :  0110_1111  0x6F  111  o  
  68    :  0110_1111  0x6F  111  o  
  69    :  0111_0100  0x74  116  t  
  70    :  1100_0000  0xC0  192    
  71    :  0011_0110  0x36   54  6  
  72    :  0000_0000  0x00    0    
  73    :  1011_1100  0xBC  188    
  74    :  0110_0001  0x61   97  a  
  75    :  0100_1110  0x4E   78  N  
  76    :  0000_0000  0x00    0    
  77    :  0000_0001  0x01    1    
  78    :  0101_0001  0x51   81  Q  
  79    :  1000_0001  0x81  129    
  80    :  0000_0000  0x00    0    
  81    :  0000_0001  0x01    1    
  82    :  0101_0001  0x51   81  Q  
  83    :  1000_0010  0x82  130    
  84    :  0000_0000  0x00    0    
  85    :  0000_0001  0x01    1    
  86    :  0101_0001  0x51   81  Q  
  87    :  1000_0011  0x83  131    
  88    :  0000_0000  0x00    0    
  89    :  0000_0001  0x01    1    
  90    :  0101_0001  0x51   81  Q  
  91    :  1000_0100  0x84  132    
|;

#print_head(\$buf);
#print_buf(\$buf);

chk_exp(\$buf,\$expected);
