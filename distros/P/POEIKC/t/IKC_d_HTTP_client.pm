package IKC_d_HTTP_client;

use strict;
use warnings;
#use Scalar::Util;
use Data::Dumper;
use Class::Inspector;
use HTTP::Request::Common qw(GET);
use POE qw(
	Sugar::Args 
	Loop::IO_Poll 
	Component::Client::HTTP
	Component::Client::Keepalive
);
use base qw(Class::Accessor::Fast);

use POEIKC::Daemon::Utility;

#############################################################################

sub main::test {
	my $self = __PACKAGE__->new();
	$self->spawn;
	$self->poe_run();
}

sub poe_run {
	POE::Kernel->run();
}



#############################################################################

sub session_id {
	my $poe = sweet_args;
	return $poe->session->ID;
}


sub enqueue {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($url_orList) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log($url_orList);
	$poe->kernel->yield('enqueue_request', $url_orList);
	return 1;
}

sub dequeue {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my @list = splice @{$poe->object->{response_queue}}, 
				0, scalar(@{$poe->object->{response_queue}});
	POEIKC::Daemon::Utility::_DEBUG_log(@list);
	return \@list;
}

sub test_ikc {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	my ($args, $rsvp) = @{$request};
	POEIKC::Daemon::Utility::_DEBUG_log($request);
	$kernel->post( IKC => post => $rsvp, join "\t"=>__PACKAGE__ , @$args);
}

sub enqueue_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log($request);
	my ($url_orList, $rsvp) = @{$request};
	$kernel->post( IKC => post => $rsvp, 1 );
	$poe->kernel->yield('enqueue_request', $url_orList);
}

sub dequeue_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	my (undef, $rsvp) = @{$request};

	my @list = splice @{$poe->object->{response_queue}}, 
				0, scalar(@{$poe->object->{response_queue}});

	$kernel->post( IKC => post => $rsvp, \@list );
}


#############################################################################

sub spawn
{
	my $class = shift;
	my $self  = $class->new();

	my $pool = POE::Component::Client::Keepalive->new(
		keep_alive    => 10, 
		max_open      => 200,
		max_per_host  => 20, 
		timeout       => 10, 
	);

	POE::Component::Client::HTTP->spawn( 
		Agent   => 'IKC_d_HTTP',
		Alias   => 'PoCo_Client_HTTP' ,
		ConnectionManager => $pool,
		FollowRedirects => 0,
		MaxSize => 50000,
		Timeout => 3,
	);

	my $session = POE::Session->create(
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ]
	);
	return $session->ID;
}

sub _start {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	
	my $alias = 'IKC_d_HTTP';
	$kernel->alias_set($alias);

	$kernel->sig( HUP  => '_stop' );
	$kernel->sig( INT  => '_stop' );
	$kernel->sig( TERM => '_stop' );
	$kernel->sig( KILL => '_stop' );

	#$kernel->delay( loop => 2 );
}

sub _stop {
	my $poe = sweet_args;
}

#sub loop {
#	my $poe = sweet_args;
#	my $kernel = $poe->kernel;
#	$kernel->yield('enqueue' => 'http://search.cpan.org/~suzuki/');
#	$kernel->delay( loop => 1 );
#}

sub enqueue_request {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($url_orList) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log($url_orList);
	if (ref $url_orList eq 'ARRAY') {
		for (@{$url_orList}) {
			#POEIKC::Daemon::Utility::_DEBUG_log(URL=>$_);
			$poe->kernel->post( 'PoCo_Client_HTTP' => 'request', 'response_event', GET($_) );
		}
	}else{
		#POEIKC::Daemon::Utility::_DEBUG_log($url_orList);
		$poe->kernel->post( 'PoCo_Client_HTTP' => 'request', 'response_event', GET($url_orList) );
	}
}

sub response_event {

	my $poe 	= sweet_args;
	my ( $request_packet, $response_packet ) = @{$poe->args} ;

	my $http_request  = $request_packet->[0];
	my $http_response = $response_packet->[0];

	my $res_code = $http_response->code;

	my ($res_message) = $http_response->message ? 
		($http_response->message) : grep {/^\w+/} split /\n/, $http_response->content;

	my $res = {
		http_request=>$http_request,
		http_response=>$http_response,
		res_code=>$res_code,
		res_message=>$res_message,
	};
	POEIKC::Daemon::Utility::_DEBUG_log($res);
	$poe->kernel->yield('enqueue_response', $res);
}

sub enqueue_response {
	my $poe 	= sweet_args;
	my ($res) = @{$poe->args};
	push @{$poe->object->{response_queue}}, $res;
}

1;
