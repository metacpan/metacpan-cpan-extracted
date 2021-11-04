#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::p9shares_rm;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, %opts ) = @_;

	# make sure all the keys are sane
	my @required_keys = ( 'vm', 'device' );
	foreach my $key (@required_keys) {

		if ( !defined( $opts{$key} ) ) {
			die 'The required variable "' . $key . '" is not set';
		}

		# make sure it does not contain any possible characters we don't want
		if ( $opts{$key} =~ /[\t\ \=\\\/\'\"\n\;\&]/ ) {
			die 'The value for "'
				. $key . '", "'
				. $opts{$key}
				. '", matched /[\t\ \=\/\\\'\"\n\;\&]/, meaning it is not a valid value';
		}
	}

	# put together the command
	my $command = 'cbsd bhyve-p9shares mode=detach jname=' . $opts{vm} . ' device=' . $opts{device};

	Rex::Logger::debug( "Removing CBSD p9share via... " . $command );

	my $returned = i_run( $command, fail_ok => 1 );

	# the output is colorized, if there is an error
	$returned = colorstrip($returned);

	# check for this second as no VM will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running '" . $command . "'" );
	}

	return 1;
}

1;
