#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bnic_list;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ($class) = @_;

	Rex::Logger::debug("Getting CBSD NIC list");

	my @nics;

	my $command='cbsd bhyve-nic-list display=nodename,jname,nic_driver,nic_parent,nic_hwaddr,nic_address,nic_mtu,nic_persistent,nic_ratelimit header=0';

	# header=0 is needed to avoid including code to exclude it
	# if display= is changed, the parsing order needs updated
	my $found = i_run( $command, fail_ok => 1 );
	if ( $? != 0 ) {
		die( "Error running '", $command . "'" );
	}

	# remove it here so the data can be safely used else where
	$found = colorstrip($found);

	my @found_lines = split( /\n/, $found );

	foreach my $line (@found_lines) {
		my %nic;

		# needs to be updated if display= is ever changed
		(
			$nic{node},      $nic{'vm'},  $nic{'driver'},     $nic{'parent'}, $nic{'hwaddr'},
			$nic{'address'}, $nic{'mtu'}, $nic{'persistent'}, $nic{'ratelimit'}
		) = split( /[\ \t]+/, $line );

		push( @nics, \%nic );
	}

	return \@nics;
}

1;
