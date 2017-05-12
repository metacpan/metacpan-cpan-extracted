# Before `make install' is performed this script should be runnable with
# make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 21;
#use diagnostics;

# test 1
BEGIN { use_ok('Net::Interface'); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

*strlcpy = \&Net::Interface::strlcpy;

my $str = 'abcdef';
my $out;
my $size;
my @exp = (
	'[undef]'	=> 0,	# -1
	'[undef]'	=> 0,	#  0
	''		=> 1,	#  1
	a		=> 2,	#  2
	ab		=> 3,	#  3
	abc		=> 4,	#  4
	abcd		=> 5,	#  5
	abcde		=> 6,	#  6
	abcdef		=> 7,	#  7
	abcdef		=> 7,	#  8
);
my $i = 0;
foreach my $v (-1..8) {
  my($len,$show,$exp);
  undef $out;
  $size = strlcpy($out,$str,$v);
  if ($exp[$i] eq '') {
    $exps = $show = '[\0]';
    $len = length($out) + 1;
  } elsif ($exp[$i] eq '[undef]') {
    $exps = $show = '[undef]';
    $len = 0;
  } else {
    if (defined $out) {
      $len = length($out) + 1;
    } else {
      $out = '[undef]';
      $len = 0;
    }
    $show = $out .'\0';
    $exps = $exp[$i];
  }
  $out = '[undef]' unless defined $out;
# print "index=$v\t$out\t=> $size,\n";
  ok($out eq $exp[$i++],"strlcpy $v, got: $len");
  ok($len == $exp[$i++],"copied $len bytes, exp: $show");
# print "\n";
}
