# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(
	get1char
	getstring
	putstring
);
use Net::DNS::ToolKit::Debug qw(
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

## test 2	check for return of first character
my $exptext = q(
  0     :  0101_0100  0x54   84  T  
  1     :  0110_1000  0x68  104  h  
  2     :  0110_0101  0x65  101  e  
  3     :  0010_0000  0x20   32     
  4     :  0111_0001  0x71  113  q  
  5     :  0111_0101  0x75  117  u  
  6     :  0110_1001  0x69  105  i  
  7     :  0110_0011  0x63   99  c  
  8     :  0110_1011  0x6B  107  k  
  9     :  0010_0000  0x20   32     
  10    :  0110_0010  0x62   98  b  
  11    :  0111_0010  0x72  114  r  
  12    :  0110_1111  0x6F  111  o  
  13    :  0111_0111  0x77  119  w  
  14    :  0110_1110  0x6E  110  n  
  15    :  0010_0000  0x20   32     
  16    :  0110_0110  0x66  102  f  
  17    :  0110_1111  0x6F  111  o  
  18    :  0111_1000  0x78  120  x  
  19    :  0010_0000  0x20   32     
  20    :  0110_1010  0x6A  106  j  
  21    :  0111_0101  0x75  117  u  
  22    :  0110_1101  0x6D  109  m  
  23    :  0111_0000  0x70  112  p  
  24    :  0110_0101  0x65  101  e  
  25    :  0110_0100  0x64  100  d  
  26    :  0010_0000  0x20   32     
  27    :  0110_1111  0x6F  111  o  
  28    :  0111_0110  0x76  118  v  
  29    :  0110_0101  0x65  101  e  
  30    :  0111_0010  0x72  114  r
  31    :  0010_0000  0x20   32     
  32    :  0111_0100  0x74  116  t  
  33    :  0110_1000  0x68  104  h  
  34    :  0110_0101  0x65  101  e  
  35    :  0010_0000  0x20   32     
  36    :  0110_1100  0x6C  108  l  
  37    :  0110_0001  0x61   97  a  
  38    :  0111_1010  0x7A  122  z  
  39    :  0111_1001  0x79  121  y  
  40    :  0010_0000  0x20   32     
  41    :  0110_0100  0x64  100  d  
  42    :  0110_1111  0x6F  111  o  
  43    :  0110_0111  0x67  103  g  
);
my $buffer = 'The quick brown fox ';
my $string = 'jumped over the lazy dog';
my $rv = putstring(\$buffer,length($buffer),\$string);
#print_buf(\$buffer);
chk_exp(\$buffer,\$exptext);

## test 3	check offset
print "bad offset, $rv, exp: 44\nnot "
	unless $rv == 44;
&ok;

## test 4	get string
my $expect = 'fox jumped over';
($string,my $newoff) = getstring(\$buffer,16,length($expect));
print "got: $string\nexp: $expect\nnot "
	unless $string eq $expect;
&ok;

## test 5	check offset
print "bad offset, $newoff, exp: 31\nnot "
	unless $newoff == 31;
&ok;
