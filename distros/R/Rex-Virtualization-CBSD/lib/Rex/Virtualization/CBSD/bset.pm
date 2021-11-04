#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bset;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class, $name, %opts ) = @_;

	# make sure we have a
	if ( !defined($name) ) {
		die('No VM name defined');
	}

	# puts together the string of what to set etc
	my $to_set = '';
	foreach my $key ( keys(%opts) ) {

		# make sure it does not contain any spaces
		if ( $key =~ /[\t\ \=\\\/\'\"\n]/ ) {
			die 'The variable "' . $key . '" matched /[\t\ \=\/\\\'\"\n]/, meaning it is not a valid variable name';
		}

		# make sure we don't have any quotes
		if ( $opts{$key} =~ /[\'\"]/ ) {
			die "The value '" . $opts{$key} . "' for key '" . $key . "' contains a single or double quote";
		}

		$to_set = $to_set . ' ' . $key . "='" . $opts{$key} . "'";
	}

	my $command = 'cbsd bset jname=' . $name . $to_set;

	Rex::Logger::debug( "Setting config value for a CBSD VM via... " . $command );

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
