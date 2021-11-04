#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bstart;

use strict;
use warnings;

our $VERSION = '0.1.0';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $vm, %opts ) = @_;

	if ( !defined($vm) ) {
		die('No VM name defined');
	}

	# make sure all the VM is sane
	if (   $opts{vn} =~ /[\t\ \=\\\/\'\"\n\;\&]/ )
	{
		die 'The value either for "vm", "'
			. $opts{vm}
			. '", matched /[\t\ \=\/\\\'\"\n\;\&]/, meaning it is not a valid value';
	}

	my $command='cbsd bstart jname=' . $vm;

	if (defined($opts{checkpoint})) {
		# make sure all the VM is sane
		if (   $opts{checkpoint} =~ /[\t\ \=\\\/\'\"\n\;\&]/ )
		{
			die 'The value either for "checkpoint", "'
			. $opts{checkpoint}
			. '", matched /[\t\ \=\/\\\'\"\n\;\&]/, meaning it is not a valid value';
		}

		$command=$command." checkpoint='".$opts{checkpoint}."'";
	}

	Rex::Logger::debug( "CBSD VM start via... ".$command );

	my $returned = i_run( 'cbsd bstart jname=' . $vm, fail_ok => 1 );

	# the output is colorized
	$returned = colorstrip($returned);

	# check for failures caused by it not existing
	if ( $returned =~ /^No\ such/ ) {
		die( '"' . $vm . '" does not exist' );
	}

	# check for failures caused by it already running
	if ( $returned =~ /already\ running/ ) {
		die( '"' . $vm . '" is already running' );
	}

	# test after no such as that will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running 'cbsd bstart " . $vm . "'" );
	}

	return 1;
}

1;
