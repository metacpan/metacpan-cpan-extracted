#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bdisk_list;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ($class) = @_;

	Rex::Logger::debug(
		"Getting CBSD VM list of disk images via cbsd bhyve-dsk-list display=jname,dsk_controller,dsk_path,dsk_size,dsk_sectorsize,bootable,dsk_zfs_guid header=0"
	);

	my @disks;

	# header=0 is needed to avoid including code to exclude it
	# if display= is changed, the parsing order needs updated
	my $found = i_run(
		'cbsd bhyve-dsk-list display=jname,dsk_controller,dsk_path,dsk_size,dsk_sectorsize,bootable,dsk_zfs_guid header=0',
		fail_ok => 1
	);
	if ( $? != 0 ) {
		die(
			"Error running 'cbsd bhyve-dsk-list display=jname,dsk_controller,dsk_path,dsk_size,dsk_sectorsize,bootable,dsk_zfs_guid header=0'"
		);
	}

	# remove it here so the data can be safely used else where
	$found = colorstrip($found);

	my @found_lines = split( /\n/, $found );

	foreach my $line (@found_lines) {
		my %disk;

		# needs to be updated if display= is ever changed
		(
			$disk{'vm'},         $disk{'controller'}, $disk{'path'}, $disk{'size'},
			$disk{'sectorsize'}, $disk{'bootable'},   $disk{'zfs_guid'}
		) = split( /[\ \t]+/, $line );
		push( @disks, \%disk );
	}

	return \@disks;
}

1;
