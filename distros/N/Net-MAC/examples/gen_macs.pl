#!/usr/bin/perl 

use strict; 
use warnings; 
use Getopt::Long; 
use Data::Dumper;

my ($count, $base); 
&Getopt::Long::GetOptions( 
	'count=i' => \$count, 
	'base=i' => \$base
); 

my @delimiter = ('.', ':', '-', ' '); 
my $z = 1; # $z == 1 means zero padding 
my %mac; 
for (my $i=0; $i<$count; $i++) { 
	my $mac = ''; 
	my $delimiter = $delimiter[int(rand(4))];
	for (my $j=0; $j<6; $j++) { # 6 octets
		for (my $k=0; $k<2; $k++) { 
			my $random = sprintf('%x', int(rand(16))); 
			if (($k == 0) && ($random eq '0') && ($z == 0)) { 
				next; # Zero padding is turned off
			}
			$mac .= $random; 
		} 
		unless ($j == 5) { # Avoid trailing delimiter
			$mac .= $delimiter; 
		}
	}
	$mac{$mac} = {base => $base, bit_group => 16, delimiter => $delimiter, zero_padding => $z};
	$z = int(rand(2)); 
} 
my $dump = Data::Dumper->new([\%mac], ['mac']); 
print $dump->Dump(); 
