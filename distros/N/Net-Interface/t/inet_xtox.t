# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::Interface qw(
	inet_pton
	inet_ntop
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

my @num = #	exp			    phex
qw(
		::			0:0:0:0:0:0:0:0
		43::			43:0:0:0:0:0:0:0
		::21			0:0:0:0:0:0:0:21
	0:1:2:3:4:5:6:7			0:1:2:3:4:5:6:7
	1:2:3:4:5:6:7:0			1:2:3:4:5:6:7:0
		1::8			1:0:0:0:0:0:0:8
	FF00::FFFF			Ff00:0:0:0:0:0:0:FFFF
	FFFF::FFFF:FFFF			FffF:0:0:0:0:0:FFFF:FFFF
);

for (my $i=0;$i<@num;$i+=2) {
  my $bits = inet_pton($num[$i+1]);
  my $len = length($bits);
  print "bad len = $len, exp: 32\nnot "
	unless $len == 16;		# 16 bytes x 8 bits
  &ok;
  my $ipv6x = inet_ntop($bits);
  print "got: $ipv6x\nexp: $num[$i]\nnot "
	unless $ipv6x eq $num[$i];
  &ok;
}

## test 26	check bad length n2x
my $try = '1234';
my $notempty = eval {
	inet_ntop($try);
};
