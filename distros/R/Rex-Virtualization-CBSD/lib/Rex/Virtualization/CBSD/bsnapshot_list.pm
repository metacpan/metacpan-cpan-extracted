#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::bsnapshot_list;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);

sub execute {
	my ( $class ) = @_;

	# put together the command
	my $command
		= 'cbsd bsnapshot mode=list display=jname,snapname,creation,refer header=0';

	Rex::Logger::debug( "Listing VM disk snapshots for CBSD via... " . $command );

	my $returned = i_run( $command, fail_ok => 1 );

	# the output is colorized, if there is an error
	$returned = colorstrip($returned);

	# check for this second as no VM will also exit non-zero
	if ( $? != 0 ) {
		die( "Error running '" . $command . "'" );
	}

	my @snapshots;

	my @returned_split=split(/\n/, $returned);
	foreach my $line (@returned_split) {
		my %snap;
		( $snap{vm}, $snap{name}, $snap{creation}, $snap{refer} )=split(/[\t\ ]+/, $line, 4);
		push( @snapshots, \%snap );
	}

	return @snapshots;
}

1;
