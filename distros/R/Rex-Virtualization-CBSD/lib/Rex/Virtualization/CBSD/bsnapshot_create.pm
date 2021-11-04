#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bsnapshot_create;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, %opts ) = @_;

	if ( !defined( $opts{vm} ) ) {
		die 'The required variable "vm" is not set';
	}

	if ( !defined( $opts{name} ) ) {
		$opts{name} = 'snapshot';
	}

	# make sure all the keys are sane
	if (   ( $opts{vm} =~ /[\t\ \=\\\/\'\"\n\;\&]/ )
		|| ( $opts{name} =~ /[\t\ \=\\\/\'\"\n\;\&]/ ) )
	{
		die 'The value either for "vm", "'
			. $opts{vm}
			. '" or "name", "'
			. $opts{name}
			. '", matched /[\t\ \=\/\\\'\"\n\;\&]/, meaning it is not a valid value';
	}

	# put together the command
	my $command
		= 'cbsd bsnapshot mode=create jname=' . $opts{vm} . " snapname='" . $opts{name} . "'";

	Rex::Logger::debug( "Creating a snapshot for a CBSD VM via... " . $command );

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
