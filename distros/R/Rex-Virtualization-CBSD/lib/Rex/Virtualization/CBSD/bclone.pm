#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bclone;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, %opts ) = @_;

	# make sure we have the required keys
	# and sane
	my @required_keys = ( 'old', 'new' );
	foreach my $key (@required_keys) {
		if ( !defined( $opts{$key} ) ) {
			die( 'Required key "' . $key . '" not defined' );
		}

		# make sure it does not contain any possible characters we don't want
		if ( $opts{$key} =~ /[\t\ \=\\\/\'\"\n\;\&]/ ) {
			die 'The value for "'
				. $key . '", "'
				. $opts{$key}
				. '", matched /[\t\ \=\/\\\'\"\n\;\&]/, meaning it is not a valid value';
		}
	}

	# the command to use
	my $command = 'cbsd bclone old=' . $opts{old} . ' new=' . $opts{new};

	# make sure all the variables are sane
	# and if set and sane add it
	my @bool_vars = ( 'checkstate', 'promote', 'mac_reinit' );
	foreach my $key (@bool_vars) {

		# make sure that the it is either 0 or 1
		if ( defined( $opts{$key} ) && ( $opts{$key} !~ /^[01]$/ ) ) {
			die( 'Key "' . $key . '" defined and is "' . $opts{key} . '", which does not match /^[01]$/' );
		}

		# if we get here it is sane and if defined, set it
		if ( defined( $opts{key} ) ) {
			$command = $command . ' ' . $key . '=' . $opts{$key};
		}

	}

	Rex::Logger::debug( "Cloning CBSD VM via... " . $command );

	my $returned = i_run( $command, fail_ok => 1 );

	# the output is colorized
	$returned = colorstrip($returned);

	# test after no such as that will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running '" . $command . "' returned... " . $returned );
	}

	return 1;
}

1;
