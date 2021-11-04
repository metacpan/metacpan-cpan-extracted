#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::vm_os_profiles;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);
use Rex::Commands::User;
use Rex::Commands::Fs;

sub execute {
	my ( $class, $wanted_os, %opts ) = @_;

	# set cloudinit to false by default
	if ( !defined( $opts{cloudinit} ) ) {
		$opts{cloudinit} = 0;
	}

	# the OS we want profiles for
	if ( !defined($wanted_os) ) {
		die 'No OS to list profiles for defined';
	}

	Rex::Logger::debug("Getting a list of VM OS types for CBSD ");

	# get where CBSD is installed to
	my %cbsd;
	eval { %cbsd = get_user('cbsd'); } or do {
		my $error = $@ || 'Unknown failure';
		die( "get_user('cbsd') died with... " . $error );
	};

	my $cbsd_etc_defaults_dir = $cbsd{home} . '/etc/defaults/';

	# get the VM OS/profile config lists
	my @vm_configs = grep { /^vm\-/ } list_files($cbsd_etc_defaults_dir);

	# find the requested ones
	my %profiles;
	foreach my $config (@vm_configs) {
		my ( $vm, $os, $profile ) = split( /\-/, $config, 3 );

		my $add_profile = 1;

		# if cloudinit is defined, only add cloudinit images
		if ( $opts{cloudinit} ) {

			# since we are default adding, make sure it is not a cloudinit
			# profile and don't add it if it is not
			if ( $profile !~ /^cloud\-/ ) {
				$add_profile = 0;
			}
		}

		# add the profile if needed
		if ($add_profile) {
			if ( $os eq $wanted_os ) {
				$profile =~ s/\.conf$//;
				$profiles{$profile} = 1;
			}
		}
	}

	return keys(%profiles);
}

1;
