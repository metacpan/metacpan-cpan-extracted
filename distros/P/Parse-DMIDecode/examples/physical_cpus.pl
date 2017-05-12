#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use Parse::DMIDecode qw();

my $dmi = Parse::DMIDecode->new( nowarnings => 1 );
$dmi->probe;

my $physical_cpus = 0;
for my $handle ($dmi->get_handles(group => "processor")) {
	my $type = ($handle->keyword("processor-type") or "");
	next unless $type =~ /Central Processor/i;

	# Check the status of the cpu
	my $status = ($handle->keyword("processor-status") or "");
	if ($status !~ /Unpopulated/i) {
		$physical_cpus++;
	}
}

printf("There %s %d physical %s in this machine.\n",
		($physical_cpus == 1 ? "is" : "are"),
		$physical_cpus,
		($physical_cpus == 1 ? "CPU" : "CPUs"),
	);

exit;

__END__


