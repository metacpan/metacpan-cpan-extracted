# $Id$

# This is a Test::More test script for Net::MAC.  This script should be 
# runnable with `make test'.

use Test::More tests => 401;
#use Test::More qw(no_plan); # FIXME
BEGIN { use_ok('Net::MAC') };

# Bulk testing operator overloading (double quotes, numeric/string equality)
require 't/100_base10_macs.pl'; 
foreach my $mac_key (keys %$mac) { 
	#diag("mac $mac_key"); 
	my $mac_obj = Net::MAC->new(mac => $mac_key, %{$mac->{mac_key}}); 
	ok($mac_key eq "$mac_obj"); 
	ok("$mac_obj" eq $mac_key); 
	ok($mac_obj->get_internal_mac() == $mac_obj); 
	ok($mac_obj == $mac_obj->get_internal_mac()); 
}
