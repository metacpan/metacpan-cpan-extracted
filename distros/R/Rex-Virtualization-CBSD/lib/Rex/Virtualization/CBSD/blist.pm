#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::blist;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ($class) = @_;

	Rex::Logger::debug(
		"Getting CBSD VM list via cbsd bls display=nodename,jname,jid,vm_ram,vm_curmem,vm_cpus,pcpu,vm_os_type,ip4_addr,status,vnc,path header=0"
	);

	my %VMs;

	# header=0 is needed to avoid including code to exclude it
	# if display= is changed, the parsing order needs updated
	my $found = i_run(
		'cbsd bls display=nodename,jname,jid,vm_ram,vm_curmem,vm_cpus,pcpu,vm_os_type,ip4_addr,status,vnc,path header=0',
		fail_ok => 1
	);
	if ( $? != 0 ) {
		die(
			"Error running 'cbsd bls display=nodename,jname,jid,vm_ram,vm_curmem,vm_cpus,pcpu,vm_os_type,ip4_addr,status,vnc,path header=0'"
		);
	}

	# cbsd bls is colorized with no off mode for the color
	# remove it here so the data can be safely used else where
	$found = colorstrip($found);

	my @found_lines = split( /\n/, $found );

	foreach my $line (@found_lines) {
		my %VM;

		# needs to be updated if display= is ever changed
		(
			$VM{'node'}, $VM{'name'}, $VM{'pid'}, $VM{'ram'},    $VM{'curmem'}, $VM{'cpus'},
			$VM{'pcpu'}, $VM{'os'}, $VM{'ip4'}, $VM{'status'}, $VM{'vnc'},    $VM{'path'}
		) = split( /[\ \t]+/, $line );
		$VMs{ $VM{'name'} } = \%VM;
	}

	return %VMs;
}

1;
