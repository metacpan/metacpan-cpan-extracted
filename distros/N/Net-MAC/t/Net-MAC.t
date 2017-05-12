# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-MAC.t'

#########################

use Test::More tests => 150;
BEGIN { use_ok('Net::MAC') };

# Creating base 16 Net::MAC objects
my @macs = ();	
my $hex_mac = Net::MAC->new('mac' => '08:20:00:AB:CD:EF'); 
ok($hex_mac); 
is($hex_mac->get_mac(), '08:20:00:AB:CD:EF');
is($hex_mac->get_bit_group(), 8); 
is($hex_mac->get_base(), 16); 
is($hex_mac->get_delimiter(), ':'); 
#ok($hex_mac->get_internal_mac() eq '082000ABCDEF'); 
is($hex_mac->get_internal_mac(), '082000abcdef'); 

## check AUTOLOAD as_* methods
## also, check that the sub gets installed properly by running it twice
for my $round (1,2)
{
    is($hex_mac->as_Cisco, '0820.00ab.cdef', "as_Cisco (round $round)");
    is($hex_mac->as_IEEE, '08:20:00:AB:CD:EF', "as_IEEE (round $round)");
    is($hex_mac->as_Microsoft, '08-20-00-AB-CD-EF', "as_Microsoft (round $round)");
    is($hex_mac->as_Sun, '8:20:0:ab:cd:ef', "as_Sun (round $round)");
}

# Converting a base 16 MAC to a base 10 MAC
my $dec_mac = $hex_mac->convert(
	'base' => 10, 
	'bit_group' => 8,
	'delimiter' => '.'
); 
ok($dec_mac); 
is($dec_mac->get_mac(), '8.32.0.171.205.239'); 
is($dec_mac->get_bit_group(), 8); 
is($dec_mac->get_base(), 10); 

# Converting a base 10 MAC to a base 16 MAC
my $hex_mac_2 = $dec_mac->convert(
	'base' => 16, 
	'bit_group' => 16, 
	'delimiter' => ':'
); 
ok($hex_mac_2); 
is($hex_mac_2->get_mac(), '0820:00ab:cdef'); 
is($hex_mac_2->get_bit_group(), 16);
is($hex_mac_2->get_base(), 16);
is($hex_mac_2->get_internal_mac(), '082000abcdef');

# Creating a base 10 Net::MAC object
my $dec_mac_2 = Net::MAC->new(
	'mac' => '0.7.14.6.43.3', 
	'base' => 10
); 
ok($dec_mac_2); 
is($dec_mac_2->get_mac(), '0.7.14.6.43.3'); 
is($dec_mac_2->get_bit_group(), 8); 
is($dec_mac_2->get_base(), 10); 
is($dec_mac_2->get_internal_mac(), '00070e062b03'); 

my $hex_mac_3 = $dec_mac_2->convert(
	'base' => 16, 
	'bit_group' => 16, 
	'delimiter' => '.'
); 
ok($hex_mac_3); 
is($hex_mac_3->get_mac(), '0007.0e06.2b03');
is($hex_mac_3->get_bit_group(), 16); 
is($hex_mac_3->get_base(), 16); 
is($hex_mac_3->get_internal_mac(), '00070e062b03');

# Creating a base 16 dash delimited Net::MAC object
my $hex_mac_4 = Net::MAC->new('mac' => '12-23-34-45-a4-ff'); 
ok($hex_mac_4); 
is($hex_mac_4->get_mac(), '12-23-34-45-a4-ff');
is($hex_mac_4->get_bit_group(), 8);
is($hex_mac_4->get_base(), 16);
is($hex_mac_4->get_internal_mac(),'12233445a4ff'); 


my (%delim_mac) = ( 
	'.' => ['08.00.20.ab.cd.ef', '8.0.20.ab.cd.ef', '08.00.20.AB.CD.EF', '122.255.0.16.1.1'], 
	':' => ['08:00:20:ab:cd:ef', '8:0:20:ab:cd:ef', '08:00:20:AB:CD:EF'], 
	'-' => ['08-00-20-ab-cd-ef', '8-0-20-ab-cd-ef', '08-00-20-AB-CD-EF'], 
	' ' => ['08 00 20 ab cd ef', '8 0 20 ab cd ef', '08 00 20 AB CD EF'],
	'none' => ['080020abcdef', '080020ABCDEF'], 
);
foreach my $delim (keys %delim_mac) { 
	foreach my $test_mac (@{$delim_mac{$delim}}) { 
		my $mac = Net::MAC->new('mac' => $test_mac);
		is($mac, $test_mac, "test with delimiter '$delim'");
		my $test_delim = $mac->get_delimiter(); 
		if ($delim eq 'none') { 
			#diag "null delimiter"; 
			ok(!defined($test_delim), 'delimiter \"none\"'); 
		} 
		else { 
			is($test_delim, $delim, "delimiter '$delim'"); 
		}
	}
}
my (%base_mac) = ( 
	'10' => ['122.255.0.16.1.1', '0.0.90.12.255.255', '8.0.20.55.1.1'], 
	'16' => ['08.00.20.ab.cd.ef', '8:0:20:ab:cd:ef', '8:0:20:AB:CD:EF']
); 
foreach my $base (keys %base_mac) { 
	foreach my $test_mac_2 (@{$base_mac{$base}}) { 
		my $mac = Net::MAC->new(
			'mac' => $test_mac_2, 
			'base' => $base
		); 
		is($mac, $test_mac_2, "mac correct for base '$base'");
		my $mac_base = $mac->get_base(); 
		is($mac_base, $base, "base $base"); 
	} 
}

my (%bit_mac) = ( 
	48 => ['8080abe4c9ff', '8080ABE4C9FF', 'ABCDEFABCDEF', '0123456789ab'], 
	16 => ['8080.abe4.c9ff', '8080.ABE4.C9FF', 'ABCD.EFAB.CDEF', '0123.4567.89ab'], 
	8 => ['80.80.ab.e4.c9.ff', '80:80:ab:e4:c9:ff', '80-80-ab-e4-c9-ff', '80 80 AB E4 C9 FF']
); 
foreach my $bit (keys %bit_mac) { 
	foreach my $test_mac_3 (@{$bit_mac{$bit}}) { 
		my $mac = Net::MAC->new('mac' => $test_mac_3); 
		is($mac, $test_mac_3, "mac correct for grouping '$bit'"); 
		my $mac_bit = $mac->get_bit_group(); 
		is($mac_bit, $bit, "bit grouping correct $bit"); 
	} 
}

# Test against a battery of base 16 MAC addresses 
my @mac = ('08.00.20.ab.cd.ef', '8:0:20:ab:cd:ef', '8:0:20:AB:CD:EF', '8080abe4c9ff', '8080ABE4C9FF', 'ABCDEFABCDEF', '0123456789ab', '8080.abe4.c9ff', '8080.ABE4.C9FF', 'ABCD.EFAB.CDEF', '0123.4567.89ab', '80.80.ab.e4.c9.ff', '80:80:ab:e4:c9:ff', '80-80-ab-e4-c9-ff', '80 80 AB E4 C9 FF'); 

foreach my $test_mac (@mac) {  
	ok(Net::MAC->new('mac' => $test_mac)); 
} 

no warnings; 
my @invalid_mac = (':::::', ' : : : : : ', '..', '\s\s\s\s\s', '-----', '---', ' - - ', ' ', '99.6', '888:76.12', '1', '000000000000000000111111', '256.256.256.256.256.256', '128.123.123.234.345.456', 'abcdefghijkl'); 
foreach my $invalid_mac (@invalid_mac) { 
	my $no_die = Net::MAC->new(mac => $invalid_mac, die => 0); 
	ok($no_die, "testing 'die' attribute for invalid mac '$invalid_mac'"); 
	ok($no_die->get_error(), "testing get_error() method for invalid mac '$invalid_mac'"); 
}
use warnings;

