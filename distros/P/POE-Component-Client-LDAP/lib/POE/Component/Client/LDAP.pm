package POE::Component::Client::LDAP;

=head1 NAME

POE::Component::Client::LDAP - subclass of Net::LDAP which uses POE to speak via sockets in async mode.

=head1 SYNOPSIS

 use POE;
 use POE::Component::Client::LDAP;
 
 POE::Session->create(
 	inline_states => {
 		_start => sub {
 			my ($heap, $session) = @_[HEAP, SESSION];
 			$heap->{ldap} = POE::Component::Client::LDAP->new(
 				'localhost',
 				callback => $session->postback( 'connect' ),
 			);
 		},
 		connect => sub {
 			my ($heap, $session, $callback_args) = @_[HEAP, SESSION, ARG1];
			if ( $callback_args->[0] ) {
 				$heap->{ldap}->bind(
 					callback => $session->postback( 'bind' ),
 				);
			}
			else {
 				delete $heap->{ldap};
				print "Connection Failed\n";
			}
 		},
 		bind => sub {
 			my ($heap, $session) = @_[HEAP, SESSION];
 			$heap->{ldap}->search(
 				base => "ou=People,dc=domain,dc=net",
 				filter => "(objectClass=person)",
 				callback => $session->postback( 'search' ),
 			);
 		},
 		search => sub {
 			my ($heap, $ldap_return) = @_[HEAP, ARG1];
 			my $ldap_search = shift @$ldap_return;
 
 			foreach (@$ldap_return) {
 				print $_->dump;
 			}
 
 			delete $heap->{ldap} if $ldap_search->done;
 		},
 	},
 );
 
 POE::Kernel->run();

=head1 DESCRIPTION

POE::Component::Client::LDAP->new() starts up a new POE::Session and POE::Wheel to manage socket communications for an underlying Net::LDAP object, allowing it to be used in async mode properly within a POE program.

=cut

use base 'Net::LDAP';

use 5.006;

use strict;
use warnings;

use Net::LDAP::ASN qw(LDAPResponse);
use Net::LDAP::Constant qw(LDAP_SERVER_DOWN);
use POE qw(Filter::Stream Filter::ASN1 Wheel::SocketFactory Wheel::Null Wheel::ReadWrite Driver::SysRW);
use Carp;

BEGIN {
	eval "sub DEBUGGING () { " . (exists( $ENV{LDAP_DEBUG} ) ? $ENV{LDAP_DEBUG} : 0) . " }"
		unless defined &DEBUGGING;
}

sub DEBUG {
	map { $_ = '' unless defined( $_ ) } my @stuff = @_;
	warn "[$$] @stuff\n";
}

our $VERSION = '0.04';

my $poe_states = {
	_start => sub {
		my ($kernel, $session, $heap, $ldap_object, $host, $arg) = @_[KERNEL, SESSION, HEAP, ARG0..ARG2];

		DEBUG( "LDAP management session startup." ) if DEBUGGING;

		$heap->{ldap_object} = $ldap_object;
		
		$ldap_object->{_heap} = $heap;
		$ldap_object->{_shutdown_callback} = $session->callback( 'shutdown' );
		$ldap_object->{_connect_callback} = $session->callback( 'connect' );
	},
	connect => sub {
		my ($heap, $callback_args) = @_[HEAP, ARG1];

		my $host = $heap->{host};
		my $port = $heap->{port};

		DEBUG( "Attempting conenction to host: $host" ) if DEBUGGING;
		$heap->{ldap_object}->{_send_callback} = sub {
			confess( "LDAP send attempted before connection set up" );
		};

		$heap->{wheel} = POE::Wheel::SocketFactory->new(
			RemoteAddress	=> $host,
			RemotePort	=> $port,
			# No way to do LocalAddr, Proto, MultiHomed, or Timeout yet
			SuccessEvent	=> 'sf_success',
			FailureEvent	=> 'sf_failure',
		);
	},
	_stop => sub {
		DEBUG( "LDAP management session shutdown" ) if DEBUGGING;
	},
	sf_success => sub {
		my ($heap, $session, $sock, $addr, $port) = @_[HEAP, SESSION, ARG0..ARG2];
		$heap->{wheel} = POE::Wheel::ReadWrite->new(
			Handle => $sock,
			Driver => POE::Driver::SysRW->new(),
			InputFilter => POE::Filter::ASN1->new(),
			OutputFilter => POE::Filter::Stream->new(),
			InputEvent => 'readwrite_input',
			FlushedEvent => 'readwrite_flushed',
			ErrorEvent => 'readwrite_error',
		);
		$heap->{ldap_object}->{_send_callback} = $session->callback( 'send_message' );
		$heap->{connection_callback}->( 1, $heap->{host}, $addr, $port); # Decide what the hell to pass here
	},
	sf_failure => sub {
		my ($kernel, $heap, $operation, $errnum, $errstr) = @_[KERNEL, HEAP, ARG0..ARG2];
		
		DEBUG( "LDAP sf_failure: ", @_ ) if DEBUGGING;
		
		$heap->{connection_callback}->( 0, $heap->{host}, $operation, $errnum, $errstr ); # Decide what the hell to pass here
		$heap->{ldap_object}->{_send_callback} = sub {
			confess( "Send attempted after connection failure" );
		};
	},
	shutdown => sub {
		my $heap = $_[HEAP];

		my $ldap_object =  $heap->{ldap_object};
		delete $ldap_object->{_shutdown_callback};
		delete $ldap_object->{_send_callback};

		delete $heap->{ldap_object};
		delete $heap->{connection_callback};
		$heap->{wheel} = POE::Wheel::Null->new();
	},
	readwrite_input => sub {
		my ($heap, $input) = @_[HEAP, ARG0];
		my $result = $LDAPResponse->decode($input);

		my $ldap = $heap->{ldap_object}->inner;

		my $mid = $result->{messageID};
		my $mesg = $ldap->{net_ldap_mesg}->{$mid};

		if ($mesg) {
			$mesg->decode( $result );
		}
		else {
			if (my $ext = $result->{protocolOp}{extendedResp}) {
				if (exists( $ext->{responseName} ) and defined( $ext->{responseName} )) {
					my $responseName = $ext->{responseName};
					if ($responseName eq '1.3.6.1.4.1.1466.20036') {
						DEBUG( "Notice of Disconnection" ) if DEBUGGING;
						$heap->{connection_callback}->( -1, LDAP_SERVER_DOWN, "Notice of Disconnection" );
						$heap->{wheel} = POE::Wheel::Null->new();
						
						if (my $msgs = $ldap->{net_ldap_mesg}) {
							foreach my $mesg (values %$msgs) {
								$mesg->set_error( LDAP_SERVER_DOWN, "Notice of Disconnection" );
							}
						}
						
						$ldap->{net_ldap_mesg} = {};
					} else {
						DEBUG( "Unexpected PDU: '$responseName', ignored" ) if DEBUGGING;
					}
				}
				else {
					DEBUG( "Unnamed PDU, ignored\n" );
				}
			}
			else {
				DEBUG( "Input without message or extended response, ignored\n" ) if DEBUGGING;
				# TODO: handle this, maybe
			}
		}
	},
	readwrite_flushed => sub {
		DEBUG( "ReadWrite Flushed: ", @_ ) if DEBUGGING;
	},
	readwrite_error => sub {
		DEBUG( "ReadWrite Error: ", @_ ) if DEBUGGING;
	},
	send_message => sub {
		my ($heap, $response_args) = @_[HEAP, ARG1];
		$heap->{wheel}->put( $response_args->[0] );
	},
};

=head1 INTERFACE DIFFERENCES

With regards to Net::LDAP, all interfaces are to be used as documented, with the following exceptions.

=over 2

=item POE::Component::Client::LDAP->new( hostname, OPTIONS )
=item POE::Component::Client::LDAP->new( OPTIONS )
=item POE::Component::Client::LDAP->new()

A call to new() is non-blocking, always returning an object.

If a hostname is supplied, new() also acts as though you have called connect(). Please read the docs for connect() to see how the arguments work.

=cut

sub new {
	my $class = shift;
	my $self = bless {}, (ref $class || $class);

	my $host = shift if @_ % 2;
	my $arg = &Net::LDAP::_options;

	if (ref( $host ) eq 'ARRAY') {
		die( "POE::Component::Client::LDAP doesn't support a list of hostnames.\n" );
	}
	
	POE::Session->create(
		inline_states => $poe_states,
		args => [ $self ],
	);

	$self->{_send_callback} = sub {
		confess( "LDAP send attempted while no connection open" );
	};

	$self->{net_ldap_resp} = {};
	$self->{net_ldap_async} = 1;
	
	$self->{net_ldap_version} = (exists( $arg->{version} ) ? $arg->{version} : $Net::LDAP::LDAP_VERSION);
	
	$self->debug( exists( $arg->{debug} ) ? $arg->{debug} : 0 );

	my $heap = $self->{_heap};

	$heap->{connection_callback} = $arg->{callback}
		if (exists( $arg->{callback} ));

	$heap->{port} = exists( $arg->{port} ) ? $arg->{port} : 389;

	if (defined( $host )) {
		$heap->{host} = $host;
		$self->{_connect_callback}->(); # Try to connect
	}

	return $self->outer();
}

=item $object->connect( hostname, OPTIONS )
=item $object->connect( OPTIONS )
=item $object->connect()

The 'callback' argument has been added and should always be supplied to notify your code when a connection is established.

Only LDAP connections are supported at this time, LDAPS and LDAPI will be in a future release.

Connection errors are not handled at this time, again in a future release.

The 'async' option is always turned on, and whatever value you pass in will be ignored.

=cut

sub connect {
	my $self = shift;

	my $host = shift if @_ % 2;
	
	my $arg = &Net::LDAP::_options;

	$self->{net_ldap_resp} = {};
	$self->{net_ldap_version} = $arg->{version}
		if (exists( $arg->{version} ));

	my $heap = $self->{_heap};

	$heap->{connection_callback} = $arg->{callback}
		if (exists( $arg->{callback} ));

	$heap->{port} = exists( $arg->{port} ) ? $arg->{port} : 389;

	$heap->{host} = $arg->{host}
		if (defined( $host ));

	$self->{_connect_callback}->(); # Try to connect
}

=item $object->async()

Async mode is always turned on and so this call will always return true, if you pass it a value to set it a fatal exception will be raised, even if value is true.

=cut

sub async {
	my $self = shift;
	if (@_) {
		die( "Setting async() under POE::Component::Client::LDAP is not something you want to do.\n" );
	}
	else {
		return $self->inner->{net_ldap_async}; 
	}
}

=item $object->sync()

Async mode is required, this call will cause a fatal exception.

=cut

sub sync {
	die( "Setting sync() under POE::Component::Client::LDAP is not something you want to do.\n" );
}

=item $object->sock()

This call will throw a fatal exception.

Because POE is being used to handle socket communications I have chosen to not expose the raw socket at this time.

=back

=cut

sub socket {
	die( "socket() as a method call is not supported under PoCo::Client::LDAP\n" );
}

sub disconnect {
	my $self = shift;
	$self->inner->_drop_conn()
}

sub _drop_conn {
  # Called as inner
  my $self = shift;
  DEBUG( "_drop_conn" ) if DEBUGGING;  
  $self->{_shutdown_callback}->();
}

sub _sendmesg {
  my $self = shift;
  my $mesg = shift;

  $self->{_send_callback}->( $mesg->pdu );

  my $mid = $mesg->mesg_id;

  $self->inner->{net_ldap_mesg}->{$mid} = $mesg;

  DEBUG( "Message $mid queued for sending" ) if DEBUGGING;
}

sub _recvresp {
	die( "POE::Component::Client::LDAP internal issue, _recvresp called.\n" );
}

sub DESTROY {
	my $self = shift;
	$self->inner->_drop_conn()
		unless --$self->inner->{net_ldap_refcnt};
		
	DEBUG( "Net::LDAP Refcount: " . $self->inner->{net_ldap_refcnt} ) if DEBUGGING;
}

=head1 CALLBACK SEMANTICS

The callback semantics documented here are for reference, the callbacks are handled by Net::LDAP and I've only documented them for reference here. The exception to this is the callback for new() which does not exist in Net::LDAP, and thus I have defined myself.

=over 2

=item new
=item connect

No arguments are passed to indicate that an existing connection has been closed.

The first argument is a boolean indicator of whether a connection has succeeded or failed. The second argument contains the host spec used to attempt the connection.

In the case of a success the third and fourth arguments contain the address and port connected to respectively.

In the case of a failure the third argument contains the name of the operation that failed, and the fourth and fifth arguments hold numeric and string values of $! respectively.

=item search

The first argument is always the Net::LDAP::Search object presiding over this search run. The 'done' method on this object may be consulted to know when all the possible replies have been received.

The second and following arguments are Net::LDAP::Entry objects returned from the search.

=item others

Forthcoming

=back

=head1 BUGS

Failures of many kinds are not very well handled at this time, also canceling running connection requests is not implemented.

=head1 AUTHOR

Jonathan Steinert
hachi@cpan.org

=head1 LICENSE

Copyright 2004 Jonathan Steinert (hachi@cpan.org)

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

