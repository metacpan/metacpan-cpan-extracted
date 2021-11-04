#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::freejname;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $name, %opts ) = @_;

	# set the hard_timeout if needed
	my $lease_time = '';
	if ( defined( $opts{lease_time} ) ) {

		# make sure we have a valid value
		if ( $opts{lease_time} !~ /^[0123456789]+$/ ) {
			die 'lease_time value,"' . $opts{lease_time} . '", is not numeric';
		}

		$lease_time = 'lease_time=' . $opts{lease_time};
	}

	# make sure we have a
	if ( !defined($name) ) {
		die('No VM name defined');
	}

	Rex::Logger::debug( "CBSD VM stop via freejname default_jailname=" . $name . ' ' . $lease_time );

	my $returned = i_run( 'cbsd freejname default_jailname=' . $name . ' ' . $lease_time, fail_ok => 1 );

	# test after no such as that will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running 'cbsd freejname default_jailname='" . $name . " " . $lease_time . "'" );
	}

	# remove colors as needed
	$returned = colorstrip($returned);
	chomp($returned);

	return $returned;
}

1;
