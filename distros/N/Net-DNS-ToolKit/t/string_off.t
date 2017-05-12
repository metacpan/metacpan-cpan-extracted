# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	get1char
	put1char
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
  0     :  0110_1111  0x6F  111  o  
  1     :  0110_1110  0x6E  110  n  
  2     :  0110_0011  0x63   99  c  
  3     :  0110_0101  0x65  101  e  
  4     :  0010_0000  0x20   32     
  5     :  0111_0101  0x75  117  u  
  6     :  0111_0000  0x70  112  p  
  7     :  0110_1111  0x6F  111  o  
  8     :  0110_1110  0x6E  110  n  
  9     :  0010_0000  0x20   32     
  10    :  0110_0001  0x61   97  a  
  11    :  0010_0000  0x20   32     
  12    :  0111_0100  0x74  116  t  
  13    :  0110_1001  0x69  105  i  
  14    :  0110_1101  0x6D  109  m  
  15    :  0110_0101  0x65  101  e  
);
my $buffer = '';
put1char(\$buffer,0,0);
my $string = 'once upon a time';
my $len = putstring(\$buffer,0,\$string);

#print_buf(\$buffer);

chk_exp(\$buffer,\$exptext);

## test 3	check length
$_ = length($string);
print "exp: $_, got: $len\nnot "
	unless $_ == $len;
&ok;

## test 4	append to existing string
$exptext = q(
  0     :  0110_1111  0x6F  111  o  
  1     :  0110_1110  0x6E  110  n  
  2     :  0110_0011  0x63   99  c  
  3     :  0110_0101  0x65  101  e  
  4     :  0010_0000  0x20   32     
  5     :  0111_0101  0x75  117  u  
  6     :  0111_0000  0x70  112  p  
  7     :  0110_1111  0x6F  111  o  
  8     :  0110_1110  0x6E  110  n  
  9     :  0010_0000  0x20   32     
  10    :  0111_0100  0x74  116  t  
  11    :  0110_1000  0x68  104  h  
  12    :  0110_0101  0x65  101  e  
  13    :  0010_0000  0x20   32     
  14    :  0110_1000  0x68  104  h  
  15    :  0110_1111  0x6F  111  o  
  16    :  0111_0010  0x72  114  r  
  17    :  0111_0011  0x73  115  s  
  18    :  0110_0101  0x65  101  e  
  19    :  0010_0000  0x20   32     
  20    :  0110_1000  0x68  104  h  
  21    :  0110_0101  0x65  101  e  
  22    :  0010_0000  0x20   32     
  23    :  0111_0010  0x72  114  r  
  24    :  0110_1111  0x6F  111  o  
  25    :  0110_0100  0x64  100  d  
  26    :  0110_0101  0x65  101  e  
);
$string = 'the horse he rode';
$len = putstring(\$buffer,10,\$string);

#print_buf(\$buffer);

chk_exp(\$buffer,\$exptext);

## test 5	check length
$_ = length($string) + 10;
print "exp: $_, got: $len\nnot "
	unless $_ == $len;
&ok;

