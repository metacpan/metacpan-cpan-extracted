#!/usr/bin/perl

use strict;

package SOAP::Adapter;
use base qw(Aw::Adapter);

use Aw;
use Aw::Event;

require SOAP::Lite;

my ($false, $true) = (0,1);

my %safe_events                  =(
	Time                         => \&handle_time_request,
	'AdapterDevKit::timeRequest' => 'activeworks://test_broker:devkitClient@my.other.active.host:8849', # map to uri
	'AdapterDevKit::calcRequest' => 'activeworks://SOAP:devkitClient@my.active.host:7449'  # map to uri
);


my ( $response_event, $s );


sub startup
{
my $self = shift;

	return $false if ( $self->newSubscription ( "SOAP::Request", 0 ) );
	
	$self->addEvent ( new Aw::EventType ( "SOAP::Request" ) );

	$self->initStatusSubscriptions;
}



sub init
{
my $self = shift;

	$self->isConnectTest  and die ( "Adapter Connection Failed.  Status = ", $self->connectTest, "\n" );

	$self->createClient   and die ( "Adapter Creation Failed." );

	$self->startup        and die ( "Adapter Startup Failed." );

	$s = new SOAP::Server;

	$s->dispatch_to('/my/path/to/Deployed/Modules');

	$true;
}



sub handle_time_request
{
my ( $method_name, $requestEvent, $eventDef ) = @_;

	#
	#  This makes a call to the classic demo the "time_adapter".
	#  Make sure it is in fact running.  Use with the
	#  http-pseudo-aw-aw-time.pl client.

	use Aw::Client;

	my $client = new Aw::Client ( "myshkin.mrf.va.noc.rcn.net:8849", "test_broker", "", "devkitClient", "Time Client" );

	$client->newSubscription ( "AdapterDevKit::time" );

	my $event = new Aw::Event ( $client, "AdapterDevKit::timeRequest" );

	if ( $client->publish ( $event ) ) {
		$@ = "Client Publish Failure - is the Time Adapter Running?";
		return;
	}

	$event = $client->getEvent( AW_INFINITE );

	$event->getField ( "time" )->toString;

}



sub processRequest
{
my ( $self, $requestEvent, $eventDef ) = @_;

	my $request_class = my $action = $requestEvent->getStringField ( 'SOAPAction' );


	my $u = new URI ( $request_class );

	$request_class = $u->path;
	$request_class =~ s|^/||;
	$request_class =~ s|/|::|g;

	my ( $broker, $group, $host, $port );
	if ( $u->scheme eq "activeworks" ) {
		my $authority = $u->authority;
	 	( $broker, $group, $host, $port ) = $authority =~ m|(\w+):?(\w+)?@(\w+):?(\d+)?|;

		# printf "[$broker] [$group] [$host] [$port]\n";
		#
		# At this stage we could do some error checking on these
		# values, but we're skipping it for now.
	}



	my $response;

	if ( $safe_events{$request_class}
	     && (ref($safe_events{$request_class}) eq "CODE") )
	{
		my $method_name = $action;
		$method_name    =~ s/^(.*?)#//;
		$response = SOAP::Serializer
			-> prefix('s')
			-> uri($action)
			-> envelope (
				method => $method_name . 'Response',
				$safe_events{$request_class}->( $method_name, $requestEvent, $eventDef )
			);
	}
	elsif ( my $alt_uri = $safe_events{$request_class} ) {
		use SOAP::Transport::ACTIVEWORKS;
		my $c = new SOAP::Transport::ACTIVEWORKS::Client;

		$response = $c->send_receive (
			envelope => $requestEvent->getStringField ( 'envelope' ),
			endpoint => undef,
			action   => $action,
			alt_uri  => $alt_uri
		);
	}
	elsif ( $action =~ m|http://| ) {
		use SOAP::Transport::HTTP;
		my $c = new SOAP::Transport::HTTP::Client;
		my $newact   = $action;
		my $endpoint = $action;
		$newact   =~ s|\+(\w+)/|/|;
		$endpoint =~ s/(\w+)#(\w+)//;
		$endpoint =~ s|(\w+)\+(\w+)/|$1/$2/|;

		my $envelope = $requestEvent->getStringField ( 'envelope' );
		$envelope =~ s/$action/$newact/;

		$response = $c->send_receive (
			envelope => $envelope,
			endpoint => $endpoint,
			action   => $action
		);
	}
	else {
		$s->action ( $action );

		$response = $s->handle ( $requestEvent->getStringField ( 'envelope' ) );
	}


	$response_event ||= $self->createTypedEvent ( "SOAP::Reply" );


	$response_event->setField ( {
		Content_Type    => "text/xml",
		Content_Length  => length ( $response ),
		envelope        => $response
	} );

	$self->deliverReplyEvent ( $response_event );
	
	$true;
}



main:
{

	my %properties  =(
		clientId    => 'SOAPAdapter',
		broker      => "SOAP\@my.broker.host:7449",
		adapterId   => 0,
		debug       => 0,
		clientGroup => 'SOAP',
	);


	chdir ( '/opt/active40' );

	my $adapter = new SOAP::Adapter ( \%properties );

	$adapter->init;

	print "Adapter has died from condition: ", $adapter->getEvents, "\n";

}


__END__


=head1 NAME

 soap-lite-adapter.pl - SOAP Adapter for ActiveWorks Brokers


=head1 SYNOPSIS

 % ./soap-lite-adapter.pl &


=head1 DESCRIPTION

This script acts as a SOAP server for ActiveWorks brokers and is part of the
SOAP-Lite-ActiveWorks distribution.  This adapter can facilitate SOAP
structured requests published by an ActiveWorks client application or forwarded
from an HTTP server.  The SOAP request may contain a URI for a Perl class
and method to instantiate and invoke or may contain a URI for an ActiveWorks
request to publish.

This adapter subscribes to the SOAP::Request event type and always replies
with a SOAP::Reply event type.  The event type and client group configuration
needed is provided in the B<server/broker-config/soap.data> file which should
be imported and saved in your target broker using the ActiveWorks
'evtype_editor'.  See the "README" file included with this package.


=head2 Traditional SOAP

To use the adapter as a SOAP server in the classic SOAP-Lite paradigm,
install  modules that you want accessible to the server in some
'U<SafeModules>' directory.  The simple 'server/SafeModules/Calculator'
module has been provided for demonstration purposes.

With the adapter running you may access the 'Calculator' class with
the native ActiveWorks Perl script B<client/aw-soap-aw-calculator.pl>
which uses a ActiveWorks broker as a proxy server (be sure to modify
the 'proxy' autodispatcher parameter for your site).

The same 'Calculator' class may be accessed through an HTTP server
when an ActiveWorks URI is used.  The B<http-aw-soap-aw-calculator.pl>
script provides an example (again be sure to update the proxy server
and uri hosts for your installation).

Finally, with the 'Calculator' class installed under an HTTP server,
the B<aw-soap-aw-http-calculator.pl> script demonstrates using an
ActiveWorks proxy broker with an HTTP class URI.


=head2 Events as SOAP Accessible Classes

With a SOAP structured request the adapter may be used as a gateway
broker to access events on a broker that may be unaccessible
to the requesting client.  The B<aw-soap-aw-aw-time.pl> script
demonstrates this when both an ActiveWorks 'proxy' and 'uri'
parameters are used with the autodispatcher.  This demonstration
requires also the B<time_adapter.pl> script that comes with the
B<Aw> module.  Note that in this example we are treating ActiveWorks
events as if they were deployed modules.

A 'I<%safe_events>' hash exists at the top of this the adapter.
You may set in this hash the 'I<SafeEvents>' that you want to grant
access to.  The hash is a table of event type names mapped to their
respective URIs or a specified subroutine (see C<Callback Handlers>
next).

'I<Pseudo Classes>' are similar in that they are ActiveWorks events
treated as SOAP accessible classes on the client side.  An ActiveWorks
URI is specified for the class, but, the proxy server will publish
a specified native ActiveWorks event type and B<not> a SOAP::Request
event type that would be received by this adapter.  See the
B<http-pseudo-aw-aw-calculator.pl> and
B<http-pseudo-aw-aw-time.pl> for examples.


=head2 Callback Handlers

You may find it necessary to perform special operations for a given
request or decide not to use the 'I<SafeModules>' approach for some
reason.  The '%safe_events' hash will accept a mapping of an class
or event type name to a code reference.

The B<http-callback-aw-aw-time.pl> script demonstrates this usage,
the request is handled in the 'handle_time_request' subroutine.


=head1 DEPENDENCIES

 The Aw package for Perl interfaces to ActiveWorks libraries.
 The SOAP-Lite package.
 The SOAP-Lite-ActiveWorks package. 


=cut
