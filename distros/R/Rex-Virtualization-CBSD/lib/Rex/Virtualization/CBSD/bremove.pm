#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bremove;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $name ) = @_;

	if ( !defined($name) ) {
		die('No VM name defined');
	}

	Rex::Logger::debug( "CBSD VM remove via cbsd bremove " . $name );

	my %VMs;

	# note
	my $returned = i_run( 'cbsd bdestroy ' . $name, fail_ok => 1 );
	if ( $? != 0 ) {
		die( "Error running 'cbsd remove " . $name . "'" );
	}

	# the output is colorized
	$returned = colorstrip($returned);

	# as of CBSD 12.1.7, it won't exit non-zero for this, so check here
	if ( $returned =~ /^No\ such/ ) {
		die( '"' . $name . '" does not exist' );
	}

	return 1;
}

1;
