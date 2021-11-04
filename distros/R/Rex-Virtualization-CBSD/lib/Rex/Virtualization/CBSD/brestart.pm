#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::brestart;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $name, %opt ) = @_;

	if ( !defined($name) ) {
		die('No VM name defined');
	}

	Rex::Logger::debug( "CBSD VM start via cbsd brebstart " . $name );

	my $returned = i_run( 'cbsd brestart ' . $name, fail_ok => 1 );

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
