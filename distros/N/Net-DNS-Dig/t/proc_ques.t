# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#	proc_ques.t
#
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	get1char
);
use Net::DNS::ToolKit::RR;
use Net::DNS::ToolKit::Utilities qw(
	question
	id
);
use Net::DNS::ToolKit::Debug qw(
	print_head
	print_buf
);
use Net::DNS::Dig;

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

require './recurse2txt';

*proc_ques = \&Net::DNS::Dig::_proc_ques;

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

# test 2	parse buffer with no object, no answer
id(1);		# seed ID for repeating ID numbers

my $question = question('bizsystems.net',T_A);
my $exp = q|
|;

#print_buf(\$question);
my $got = q|
  0     :  0000_0000  0x00    0    
  1     :  0000_0011  0x03    3    
  2     :  0000_0001  0x01    1    
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
  13    :  0110_0010  0x62   98  b  
  14    :  0110_1001  0x69  105  i  
  15    :  0111_1010  0x7A  122  z  
  16    :  0111_0011  0x73  115  s  
  17    :  0111_1001  0x79  121  y  
  18    :  0111_0011  0x73  115  s  
  19    :  0111_0100  0x74  116  t  
  20    :  0110_0101  0x65  101  e  
  21    :  0110_1101  0x6D  109  m  
  22    :  0111_0011  0x73  115  s  
  23    :  0000_0011  0x03    3    
  24    :  0110_1110  0x6E  110  n  
  25    :  0110_0101  0x65  101  e  
  26    :  0111_0100  0x74  116  t  
  27    :  0000_0000  0x00    0    
  28    :  0000_0000  0x00    0    
  29    :  0000_0001  0x01    1    
  30    :  0000_0000  0x00    0    
  31    :  0000_0001  0x01    1    
|;
chk_exp(\$question,\$got);

## test 3	check question return offset
my($get,$put,$parse) = new Net::DNS::ToolKit::RR;

my $off = proc_ques($get,HFIXEDSZ,\$question);
my $len = length($question);
print "bad question length, got: $off, exp: $len\nnot "
	unless $len eq $off;
&ok;

## test 4	check question and fill response object
my $self = {};

$off = proc_ques($get,HFIXEDSZ,\$question,$self);
$len = length($question);
print "bad question length, got: $off, exp: $len\nnot "
        unless $len eq $off;
&ok;

#print Dumper($self);
$exp = q|5	= {
	'QUESTION'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'TYPE'	=> 1,
	},
],
};
|;

## test 5	check object structure
$got = Dumper($self);
print "faulty object\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;
