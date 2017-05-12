# Before `make install' is performed this script should be runnable with
# make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 2;
#use diagnostics;

# test 1
BEGIN { use_ok( 'Net::Interface',qw(
	:iffs
)); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

my @all = Net::Interface->interfaces();

my $loopif;
eval {
	foreach (0..$#all) {
	    my $flags = $all[$_]->flags();
	    next unless defined $flags &&
	    	$flags & IFF_LOOPBACK() &&
	    	$flags & IFF_UP();
	  $loopif = $all[$_];
	  last;
	}
};

my $why = "loopback interface not found, possible jailed environment";
my $mtu;

SKIP: {
	skip $why, 1, unless $loopif && 
		($why = "apparently no permission") &&
		eval { $mtu = $loopif->mtu(576); } &&
		eval { $mtu = $loopif->mtu($mtu); } &&
		(! $@) && $mtu == 576;
	ok($mtu == 576,"can update mtu on $loopif");
};
