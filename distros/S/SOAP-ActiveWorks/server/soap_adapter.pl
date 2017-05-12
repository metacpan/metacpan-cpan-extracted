#!/usr/bin/perl -w


package SOAP::Adapter;
use base qw(Aw::Adapter);

use Aw;
# use Aw 'test_broker@localhost:8849';  # reset as needed
use Aw::Event;

require SOAP::Transport::ActiveWorks::Server;
use SOAP::Transport::ActiveWorks::AutoInvoke::Server;

my ($false, $true) = (0,1);

my $safe_classes ={
      Calculator => \&auto_invoke,
      Time       => \&handle_time_request,
};


my $response_event;


sub startup
{
my $self = shift;

	return $false if ( $self->newSubscription ( "SOAP::Request", 0 ) );
	
	$self->addEvent ( my $et = new Aw::EventType ( "SOAP::Request" ) );

	$self->initStatusSubscriptions;
}



sub init
{
my $self = shift;

	$self->isConnectTest  and die ( "Adapter Connection Failed.  Status = ", $self->connectTest, "\n" );

	$self->createClient   and die ( "Adapter Creation Failed." );

	$self->startup        and die ( "Adapter Startup Failed." );

	$true;
}



sub handle_time_request
{
my ($request_class, $headers, $body, $envelopeMaker) = @_;


	#
	#  This makes a call to the classic demo the "time_adapter".
	#  Make sure it is in fact running.
	#

	use Aw::Client;

	my $client = newEZ Aw::Client ( "devkitClient" );

	my $method_name = $body->{soap_typename};

	$client->newSubscription ( "AdapterDevKit::time" );

	my $event = new Aw::Event ( $client, "AdapterDevKit::timeRequest" );

	if ( $client->publish ( $event ) ) {
		$@ = "Client Publish Failure - is the Time Adapter Running?";
		return;
	}

	$event = $client->getEvent( AW_INFINITE );

	my $date = $event->getField ( "time" );

	#
	#  This only works because I happen to know the client is using AutoInvoke
	#
	$body->{ARG0} = $date->toString;
	$body->{ARGC} = 1;

	$envelopeMaker->set_body(undef, "$method_name.response", 0, $body);

}



sub deliverError
{
my ($self, $message) = @_;


	my $error       = $self->createTypedEvent ( "Adapter::error" );
	my $errorNotify = $self->createTypedEvent ( "Adapter::errorNotify" );

	my %fields        =(
		errorText     => $message,
		errorCategory => "Adapter",
		adapterType   => $self->getAdapterType
	);

	foreach (keys %fields) {
		$error->setField       ( $_, $fields{$_} );
		$errorNotify->setField ( $_, $fields{$_} );
	}

	$self->deliverReplyEvent ( $error );
	$self->publish ( $errorNotify );

}



sub processRequest
{
my ( $self, $requestEvent, $eventDef ) = @_;
my $optional_dispatcher;


	my $request_class = $requestEvent->getStringField ( 'SOAPClass' );

	unless (exists $safe_classes->{$request_class}) {
		$self->deliverError ( "Requested class '$request_class' is not valid on
this server." );
		return;
	}
	if ( $safe_classes->{$request_class}
	     && (ref($safe_classes->{$request_class}) eq "CODE") ) {
	     $optional_dispatcher = $safe_classes->{$request_class};
	}

	$response_event ||= $self->createTypedEvent ( "SOAP::Reply" );

	my $request_header_reader = sub {
		my $key = shift;
		$key =~ s/-/_/g;
		$requestEvent->getField ( $key );
	};
	my $response_header_writer = sub {
		my $key = shift;
		$key =~ s/-/_/g;
		$response_event->setField ( $key => $_[0] );
	};
	my $request_content_reader = sub {
		$_[0] = $requestEvent->getField ( 'envelope' );
	};
	my $response_content_writer = sub {
		$response_event->setField ( 'envelope' => $_[0] );
	};

	my $request_type  = $requestEvent->getTypeName;


	my $s = new SOAP::Transport::ActiveWorks::Server;

	$s->handle_request (
			$request_type,
	                $request_class,
	                $request_header_reader, 
	                $request_content_reader,
	                $response_header_writer,
	                $response_content_writer,
	                $optional_dispatcher
	);

	$self->deliverReplyEvent ( $response_event );
	
	$true;
}



main: {

	my %properties      =(
		clientId        => 'SOAPAdapter',
		broker          => "test_broker\@localhost",
		adapterId       => 0,
		debug           => 1,
		clientGroup     => 'SOAP',
	);


	my $adapter = new SOAP::Adapter ( \%properties );

	$adapter->init;

	print "Adapter has died from condition: ", $adapter->getEvents, "\n";

}
