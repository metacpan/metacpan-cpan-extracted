# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:header);

$loaded = 1;
print "ok 1\n";

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $opcodemask = '1000011111111111';
my $ocm = sprintf("%b",&BITS_OPCODE_MASK);
print "BITS_OPCODE_MASK\n$ocm !=\n$opcodemask\nnot "
	unless $opcodemask eq $ocm;
&ok;

my $rcodemask = '1111111111110000';
my $rcm = sprintf("%b",&RCODE_MASK);
print "RCODE_MASK\n$rcm !=\n$rcodemask\nnot "
	unless $rcodemask eq $rcm;
&ok;
