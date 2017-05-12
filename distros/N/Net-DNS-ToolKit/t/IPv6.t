# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	getIPv6
	putIPv6
	ipv6_n2x
	ipv6_n2d
	ipv6_aton
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
my $IP6addr = '::FE:192.168.1.2';
my $naddr = ipv6_aton($IP6addr);
my $rv = putIPv6(\$buffer,0,$naddr);
print "bad size $rv\nnot "
	unless $rv == NS_IN6ADDRSZ;
&ok;

## test 3	ip addr should be only item in buffer
$IP6addr =~ s/::/:0:/;
my $Taddr = ipv6_n2d($buffer);
print "got: $Taddr, exp: $IP6addr\nnot "
	unless $Taddr =~ /$IP6addr$/;
&ok;

## test 4	recover IP6addr using getIPv6
$Taddr = getIPv6(\$buffer,0);
$Taddr = ipv6_n2d($Taddr);
print "got: $Taddr, exp: $IP6addr\nnot "
	unless $Taddr =~ /$IP6addr$/;
&ok;

$IP6addr = ':0:FE:C0A8:102';		# convert expected to all hex

## test 5	recover addr and next pointer
($Taddr,$rv) = getIPv6(\$buffer,0);
$Taddr = ipv6_n2x($Taddr);  
print "ipv6addr got: $Taddr, exp: $IP6addr\nnot "
	unless $Taddr =~ /$IP6addr$/;
&ok;

## test 6	check RV
print "bad size $rv\nnot "
	unless $rv == NS_IN6ADDRSZ;
&ok;

## test 7	check leading :: conversion on long value
$IP6addr = '::1111:2222:3333:4444:5555:6666:7777';
my $exp = '0:1111:2222:3333:4444:5555:6666:7777';
$Taddr = ipv6_aton($IP6addr);
$Taddr = ipv6_n2x($Taddr);
print "got: $Taddr\nexp: $exp\nnot "
	unless $Taddr eq $exp;
&ok;

## test 8	check trailing :: conversion on long value
$IP6addr = '1111:2222:3333:4444:5555:6666:7777::';
$exp = '1111:2222:3333:4444:5555:6666:7777:0';
$Taddr = ipv6_aton($IP6addr);
$Taddr = ipv6_n2x($Taddr);   
print "got: $Taddr\nexp: $exp\nnot "
	unless $Taddr eq $exp;
&ok;
