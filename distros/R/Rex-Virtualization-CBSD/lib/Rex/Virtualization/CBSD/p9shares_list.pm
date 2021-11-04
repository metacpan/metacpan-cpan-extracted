#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::p9shares_list;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ($class) = @_;

	my $command = 'cbsd bhyve-p9shares mode=list header=0 display=jname,p9device,p9path';

	Rex::Logger::debug( "Getting CBSD p9shares info via... " . $command );

	my $returned = i_run( $command, fail_ok => 1 );

	# the output is colorized, if there is an error
	$returned = colorstrip($returned);

	# check for this second as no VM will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running '" . $command . "'" );
	}

	my @shares;
	my @lines = split( /\n/, $returned );
	foreach my $line (@lines) {
		my %share;
		( $share{vm}, $share{device}, $share{path} ) = split( /\:\ /, $line, 3 );

		# make sure we did not get a empty line, which it will return if there is none
		if (   ( $share{vm} !~ /^$/ )
			|| ( !defined( $share{evice} ) )
			|| ( !defined( $share{path} ) ) )
		{
			push( @shares, \%share );
		}
	}

	return @shares;
}

1;
