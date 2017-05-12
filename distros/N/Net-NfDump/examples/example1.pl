#!/usr/bin/perl 

use strict; 
use ExtUtils::testlib;
use Net::NfDump;

my (%h, $flow);

if (@ARGV == 0) {
	printf "Usage:\n $0 <nfdump_file> <nfdump_file> ... \n\n";
	exit 1;
}

# create and display progressbar 
local $SIG{ALRM} = sub { 
	my $i = $flow->info();
	printf STDERR "%sprocessed: %3.0f%%, remaining time: %ds    ", "\b" x 50, 
			$i->{'percent'},
			$i->{'remaining_time'} ; 
	alarm(1); 
};

# create nfdump instance
$flow = new Net::NfDump(
        InputFiles => [ @ARGV ], 
		Filter => 'any', 
        Fields => 'proto, bytes' ); 

$flow->query();
alarm(1);

# traverse all records
while (my ($proto, $bytes) = $flow->fetchrow_array() )  {
	$h{$proto} = 0 if ( !defined($h{$proto}) );
	$h{$proto} += $bytes;  
}
$flow->finish();

# print stattistics  
# protocol : bytes
printf "\n";
printf "proto ID    bytes [kB]\n";
printf "======================\n";
foreach ( sort { $h{$b} <=> $h{$a} } keys %h ) {
	printf "%-5s %15d\n", $_, $h{$_}/1000;
}

