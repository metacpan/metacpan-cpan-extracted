#!/usr/bin/perl -I. -w

package CalcAdapter;
use base qw(Aw::Adapter);

use Aw 'SOAP@active:7449';
use Aw::Event;
require Aw::Adapter;

my ($false, $true) = (0, 1);


sub startup {

	my $self = shift;

	return $false if ( $self->newSubscription ( "AdapterDevKit::calcRequest", 0 ) );

	$self->addEvent( new Aw::EventType ( "AdapterDevKit::calcRequest" ) );

	$self->initStatusSubscriptions;
    
}


#
# callback to process a request:  Adapter DK 6-45
#
sub processRequest {

	my ( $self, $reqEvent, $eventDef ) = @_;

	my %data = $reqEvent->toHash;

	my $sum = 0;
	foreach ( @{$data{numbers}} ) {
		$sum += $_;	
	}
	my $reply = $self->createTypedEvent (
		"AdapterDevKit::calcReply",
		{ result => $sum  }
	);


	$self->deliverReplyEvent ( $reply ) if ( $reply );
	
	$true;
}


package main;


	my %properties = (
	        clientId	=> 'CalcAdapter',
	        broker		=> "SOAP\@active:7449",
	        adapterId	=> 0,
	        debug		=> 1,
	        clientGroup	=> 'devkitAdapter',
	        adapterType	=> 'The Calculator',
	);

	chdir '/opt/active40';  # get message catalogs under your belly

	my $adapter = new CalcAdapter ( \%properties );

	$adapter->isConnectTest  and die ( "Adapter Connection Failed.  Status = ", $adapter->connectTest, "\n" );

	$adapter->createClient   and die ( "Adapter Creation Failed." );

	$adapter->startup        and die ( "Adapter Startup Failed. $!" );

	print "Adapter has died from condition: ", $adapter->getEvents, "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script is an ActiveWorks adapter that subscribes to and handles
'AdapterDevekit::calcRequest' events.  The summation of all digits
passed in the 'numbers' integer array field is returned in an
'AdapterDevkit::calcReply'.  B<No> SOAP components are employed.

=cut
