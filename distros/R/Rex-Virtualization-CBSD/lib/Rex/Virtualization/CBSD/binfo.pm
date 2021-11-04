#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::binfo;

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

	Rex::Logger::debug( "CBSD VM info via cbsd bget jname=" . $name );

	#
	my $returned = i_run( 'cbsd bget jname=' . $name, fail_ok => 1 );

	# the output is colorized, if there is an error
	$returned = colorstrip($returned);
	if ( $returned =~ /^No\ such/ ) {
		die( '"' . $name . '" does not exist' );
	}

	# check for this second as no VM will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running 'cbsd bget jname=" . $name . "'" );
	}

	my %info;
	my @lines = split( /\n/, $returned );
	foreach my $line (@lines) {
		my ( $vname, $vval ) = split( /\:\ /, $line );
		$info{$vname} = $vval;
	}

	return \%info;
}

1;
