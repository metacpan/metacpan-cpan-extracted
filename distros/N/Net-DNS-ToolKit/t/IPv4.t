# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	getIPv4
	putIPv4
	inet_ntoa
	inet_aton
	get1char
	parse_char
);
use Net::DNS::Codes qw(:constants);

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

## test 2	add stuff to buffer
my $buffer = '';
my $IPaddr = '192.168.1.2';
my $naddr = inet_aton($IPaddr);
my $rv = putIPv4(\$buffer,0,$naddr);
print "bad size $rv\nnot "
	unless $rv == NS_INADDRSZ;
&ok;

## test 3	ip addr should be only item in buffer
my $Taddr = inet_ntoa($buffer);
print "got: $Taddr, exp: $IPaddr\nnot "
	unless $Taddr eq $IPaddr;
&ok;

## test 4	recover IPaddr using getIPv4
$Taddr = getIPv4(\$buffer,0);
$Taddr = inet_ntoa($Taddr);
print "got: $Taddr, exp: $IPaddr\nnot "
	unless $Taddr eq $IPaddr;
&ok;

## test 5	recover addr and next pointer
($Taddr,$rv) = getIPv4(\$buffer,0);
$Taddr = inet_ntoa($Taddr);  
print "netaddr got: $Taddr, exp: $IPaddr\nnot "
	unless $Taddr eq $IPaddr;
&ok;

## test 6	check RV
print "bad size $rv\nnot "
	unless $rv == NS_INADDRSZ;
&ok;
