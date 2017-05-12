# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit;
use Socket;

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

# test that C inet_xtoy and perl inet_xtoy work the same way

my $ipa = '1.2.3.4';
my $ipCn = Net::DNS::ToolKit::inet_aton($ipa);
my $ipPn = inet_aton($ipa);

## test 2 - check that conversions are the same
print "don't match\nnot "
	unless $ipCn eq $ipPn;
&ok;

## test 3 - check perl from C
print "$_ ne $ipa\nnot "
	unless ($_ = inet_ntoa($ipCn)) eq $ipa;
&ok;

## test 4 - check perl from perl
print "$_ ne $ipa\nnot "
        unless ($_ = inet_ntoa($ipPn)) eq $ipa;
&ok;

## test 5 - check C from C
print "$_ ne $ipa\nnot "
        unless ($_ =Net::DNS::ToolKit::inet_ntoa($ipCn)) eq $ipa;
&ok;

## test 6 - check C from perl
print "$_ ne $ipa\nnot "
        unless ($_ =Net::DNS::ToolKit::inet_ntoa($ipPn)) eq $ipa;
&ok;
