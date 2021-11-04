#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bpci_list;

use strict;
use warnings;

our $VERSION = '0.0.1'; # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $vm ) = @_;

	if (!defined($vm)) {
		die 'No VM specified';
	}

	Rex::Logger::debug("Getting list of PCI devices for '".$vm."' in CBSD");

	my @pci;

	# header=0 is needed to avoid including code to exclude it
	# if display= is changed, the parsing order needs updated
	my $found=i_run ('cbsd bpcibus jname='.$vm.' mode=list header=0 display=pcislot_name,pcislot_bus,pcislot_pcislot,pcislot_function,pcislot_desc' , fail_ok => 1);
	if ( $? != 0 ) {
		die("Error running 'cbsd bpcibus jname=".$vm." mode=list header=0 display=pcislot_name,pcislot_bus,pcislot_pcislot,pcislot_function,pcislot_desc'");
	}

	# remove it here so the data can be safely used else where
	$found=colorstrip($found);

	my @found_lines=split(/\n/, $found);

	foreach my $line (@found_lines) {
		my %device;
		# needs to be updated if display= is ever changed
		( $device{'name'}, $device{'bus'}, $device{'slot'}, $device{'function'}, $device{'desc'} ) = split(/[\ \t]+/, $line);
		push( @pci, \%device );
	}

	return \@pci;
}

1;
