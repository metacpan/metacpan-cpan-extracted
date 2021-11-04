#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::vm_os_types;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);
use Rex::Commands::User;
use Rex::Commands::Fs;

sub execute {
	my ($class) = @_;

	Rex::Logger::debug("Getting a list of VM OS types for CBSD ");

	# get where CBSD is installed to
	my %cbsd;
	eval { %cbsd = get_user('cbsd'); } or do {
		my $error = $@ || 'Unknown failure';
		die( "get_user('cbsd') died with... " . $error );
	};

	my $cbsd_etc_defaults_dir = $cbsd{home} . '/etc/defaults/';

	# get a list of the VM/OS configs
	my @vm_configs = grep { /^vm\-/ } list_files($cbsd_etc_defaults_dir);

	# find what OS we have profiles for
	my %os_types;
	foreach my $config (@vm_configs) {
		my ( $vm, $os, $profile ) = split( /\-/, $config, 3 );
		$os_types{$os} = 1;
	}

	return keys(%os_types);
}

1;
