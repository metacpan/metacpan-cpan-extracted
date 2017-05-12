# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNSBL::Utilities qw(
	s_response
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

my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
my $buf;

## test 2	generate initial buffer
my $off = newhead(\$buf,
	12345,
	BITS_QUERY,
	1,0,0,0);
$put->Question(\$buf,$off,'somedomain.com',T_A,C_IN);

my $expected = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  0000_0000  0x00    0    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_1010  0x0A   10    
  13    :  0111_0011  0x73  115  s  
  14    :  0110_1111  0x6F  111  o  
  15    :  0110_1101  0x6D  109  m  
  16    :  0110_0101  0x65  101  e  
  17    :  0110_0100  0x64  100  d  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0110_0001  0x61   97  a  
  21    :  0110_1001  0x69  105  i  
  22    :  0110_1110  0x6E  110  n  
  23    :  0000_0011  0x03    3    
  24    :  0110_0011  0x63   99  c  
  25    :  0110_1111  0x6F  111  o  
  26    :  0110_1101  0x6D  109  m  
  27    :  0000_0000  0x00    0    
  28    :  0000_0000  0x00    0    
  29    :  0000_0001  0x01    1    
  30    :  0000_0000  0x00    0    
  31    :  0000_0001  0x01    1    
|;

#print_head(\$buf);
#print_buf(\$buf);

chk_exp(\$buf,\$expected);

## test 3	generate response
s_response(\$buf,REFUSED,54321,1,0,0,0);

$expected = q|
  0     :  1101_0100  0xD4  212    
  1     :  0011_0001  0x31   49  1  
  2     :  1000_0000  0x80  128    
  3     :  0000_0101  0x05    5    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_1010  0x0A   10    
  13    :  0111_0011  0x73  115  s  
  14    :  0110_1111  0x6F  111  o  
  15    :  0110_1101  0x6D  109  m  
  16    :  0110_0101  0x65  101  e  
  17    :  0110_0100  0x64  100  d  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0110_0001  0x61   97  a  
  21    :  0110_1001  0x69  105  i  
  22    :  0110_1110  0x6E  110  n  
  23    :  0000_0011  0x03    3    
  24    :  0110_0011  0x63   99  c  
  25    :  0110_1111  0x6F  111  o  
  26    :  0110_1101  0x6D  109  m  
  27    :  0000_0000  0x00    0    
  28    :  0000_0000  0x00    0    
  29    :  0000_0001  0x01    1    
  30    :  0000_0000  0x00    0    
  31    :  0000_0001  0x01    1    
|;
#print_head(\$buf);
#print_buf(\$buf);

chk_exp(\$buf,\$expected);
