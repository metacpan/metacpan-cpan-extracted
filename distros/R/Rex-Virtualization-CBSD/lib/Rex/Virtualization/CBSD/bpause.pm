#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bpause;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $name, $mode ) = @_;

	# make sure we have a jname to pass
	if ( !defined($name) ) {
		die('No VM name defined');
	}

	# set the mode to auto if none is set
	if ( !defined($mode) ) {
		$mode = 'auto';
	}

	# make sure mode is something valid
	if (   ( $mode eq 'auto' )
		|| ( $mode eq 'on' )
		|| ( $mode eq 'off' ) )
	{
		die "Mode specified is something other than 'auto', 'on', or 'off'.";
	}

	Rex::Logger::debug( "CBSD VM start via cbsd brebstart " . $name );

	# run it
	my $returned = i_run( 'cbsd bpause ' . $name . ' mode=' . $mode, fail_ok => 1 );

	# the output is colorized
	$returned = colorstrip($returned);

	# check for failures caused by it not existing
	if ( $returned =~ /^No\ such/ ) {
		die( '"' . $name . '" does not exist' );
	}
	if ( $? != 0 ) {
		die( "Error running 'cbsd brestart " . $name . "'" );
	}

	return 1;
}

1;
