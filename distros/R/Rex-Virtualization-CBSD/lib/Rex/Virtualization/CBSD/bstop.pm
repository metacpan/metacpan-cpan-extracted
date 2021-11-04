#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bstop;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $name, %opts ) = @_;

	# set the hard_timeout if needed
	my $hard_timeout = '';
	if ( defined( $opts{hard_timeout} ) ) {

		# make sure we have a valid value
		if ( $opts{hard_timeout} !~ /^[0123456789]+$/ ) {
			die 'hard_timeout value,"' . $opts{hard_timeout} . '", is not numeric';
		}

		$hard_timeout = 'hard_timeout=' . $opts{hard_timeout};
	}

	# set the noacpi value if needed
	my $noacpi = '';
	if ( defined( $opts{noacpi} ) ) {

		# make sure we have a valid value
		if (   ( $opts{noacpi} ne '0' )
			&& ( $opts{noacpi} ne '1' ) )
		{
			die 'noacpi is set and it is not equal to "0" or "1"';
		}

		$noacpi = 'noacpi=' . $opts{noacpi};
	}

	# make sure we have a
	if ( !defined($name) ) {
		die('No VM name defined');
	}

	Rex::Logger::debug( "CBSD VM stop via cbsd bstop " . $name );

	my $returned = i_run( 'cbsd bstop jname=' . $name . ' ' . $hard_timeout . ' ' . $noacpi, fail_ok => 1 );

	# the output is colorized
	$returned = colorstrip($returned);

	# check for failures caused by it not existing
	if ( $returned =~ /^No\ such/ ) {
		die( '"' . $name . '" does not exist' );
	}

	# test after no such as that will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running 'cbsd bstop " . $name . "'" );
	}

	# this is warning message will be thrown if stop fails.... does not return 0 though
	if ( $returned =~ /unable\ to\ determine\ bhyve\ pid/ ) {
		die( "Either already stopped or other issue determining bhyve PID for '" . $name . "'" );
	}

	return 1;
}

1;
