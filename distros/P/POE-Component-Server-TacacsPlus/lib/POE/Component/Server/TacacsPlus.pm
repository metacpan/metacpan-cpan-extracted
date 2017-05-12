package POE::Component::Server::TacacsPlus;

=head1 NAME

POE::Component::Server::TacacsPlus - POE Tacacs+ server component

=head1 SYNOPSIS

	use POE::Component::Server::TacacsPlus;
	use Net::TacacsPlus::Constants;
	
	POE::Component::Server::TacacsPlus->spawn(
		'server_port' => 4949,
		'key'         => 'secret',
		'handler_for' => {
			TAC_PLUS_AUTHEN() => {
				TAC_PLUS_AUTHEN_TYPE_PAP() => \&check_pap_authentication,
			},
		},
	);
	
	POE::Kernel->run();
	
	sub check_pap_authentication {
		my $username = shift;
		my $password = shift;
		
		return 1 if $password = $username.'123';
		return 0;
	}

=head1 DESCRIPTION

This component will listen on $server_port for Tacacs+ client reqests and
dispatch them to the local functions handlers.

Currently only PAP requests can be dispatched as this is HIGHLY experimental
and more like idea then functional code even that the pap is working fine.

I'm looking forward to you comments and suggestions until i'll invest more time
on it.

=cut

use strict;
use warnings;

use Socket qw(inet_ntoa);
use POE qw{
	Wheel::SocketFactory
	Wheel::ReadWrite
	Filter::TacacsPlus
	Driver::SysRW
};
use Log::Log4perl qw(:nowarn :easy :no_extra_logdie_message);
use Net::TacacsPlus::Constants;
use Carp::Clan;

our $VERSION     = '1.11';
our $SERVER_PORT = 49;


=head1 FUNCTIONS

=head2 spawn

Accepts following parameters:

	key         : tacacs secret key
	server_port : port on which to listen (optional) - default 49
	handler_for : hash ref of handlers. keies are one of TAC_PLUS_AUTHEN, TAC_PLUS_AUTHOR and TAC_PLUS_ACCT

=cut

sub spawn {
	my $class = shift;
	my $heap  = { @_ };
	
	croak 'pass at least one type handler' if not exists $heap->{'handler_for'}; 
	croak 'handler_for must be hash ref'   if ref $heap->{'handler_for'} ne 'HASH'; 
	
	POE::Session->create(
		inline_states => {
			_start            => \&server_start,
			accept_new_client => \&accept_new_client,
			accept_failed     => \&accept_failed,
			_stop             => \&server_stop,
		},
		heap => $heap,
	);

}


=head2 server_start

Component _start function.

=cut

sub server_start {
	my $heap     = $_[HEAP];
	
	$SERVER_PORT = $heap->{'server_port'} if exists $heap->{'server_port'};
	
	$heap->{'listener'} = new POE::Wheel::SocketFactory(
  		BindPort     => $SERVER_PORT,
		Reuse        => 'yes',
		SuccessEvent => 'accept_new_client',
		FailureEvent => 'accept_failed',
	);
	INFO 'SERVER: Started listening on port ', $SERVER_PORT;
}


=head2 server_stop

Component _stop function.

=cut

sub server_stop {
	INFO "SERVER: Stopped.\n";
}


=head2 accept_new_client

On client connect setup function. Will setup POE::Session
to handle client input using child_* function.

=cut

sub accept_new_client {
	my $heap      = $_[HEAP];
	my $socket    = $_[ARG0];
	my $peer_addr = $_[ARG1];
	my $peer_port = $_[ARG2];
	
	$peer_addr = inet_ntoa($peer_addr);

	POE::Session->create(
		inline_states => {
			_start      => \&child_start,
			_stop       => \&child_stop,
			child_input => \&child_input,
			child_done  => \&child_done,
			child_error => \&child_error,
		},
		args => [ $socket, $peer_addr, $peer_port ],
		heap => {
			'key'         => $heap->{'key'},
			'handler_for' => $heap->{'handler_for'},
		},
	);
	DEBUG 'SERVER: Got connection from '.$peer_addr.':'.$peer_port;
}


=head2 accept_failed

Tidy up and print out error message if accept failed.

=cut

sub accept_failed {
	my $function = $_[ARG0];
	my $error    = $_[ARG2];
	my $heap     = $_[HEAP];

	delete $heap->{'listener'};
	ERROR 'SERVER: call to '.$function.'() failed: '.$error.'.';
}


=head2 child_start

Setup POE::Wheel::ReadWrite with POE::Filter::TacacsPlus so that
child_input will receive directly Net::TacacsPlus::Packet objects
as input.

=cut

sub child_start {
	my $heap      = $_[HEAP];
	my $socket    = $_[ARG0];
	my $peer_addr = $_[ARG1];
	my $peer_port = $_[ARG2];

	$heap->{'peername'} = $peer_addr.':'.$peer_port;

	$heap->{'readwrite'} = new POE::Wheel::ReadWrite (
		Handle => $socket,
		Driver => new POE::Driver::SysRW(),
		Filter => new POE::Filter::TacacsPlus(
			'key' => $heap->{'key'}
		),
		InputEvent   => 'child_input',
		ErrorEvent   => 'child_error',
	);

	DEBUG 'CHILD: Connected to '.$heap->{'peername'};
}


=head2 child_stop

Just print out the debug message that the child is finished.

=cut

sub child_stop {
	DEBUG "CHILD: Stopped.\n";
}


=head2 child_input

Process incomming Net::TacacsPlus::Packet and call propper
handler.

=cut

sub child_input {
	my $packet = $_[ARG0];
	my $heap   = $_[HEAP];
	my $kernel = $_[KERNEL];

	my $reply;

	DEBUG "CHILD: Got input from peer";
	
	my $packet_type = $packet->type;
	DEBUG "packet type> ".$packet_type;

	# check if we have handler for authentication
	my $handler = $heap->{'handler_for'}->{$packet_type};
	if (not defined $handler ) {
		$kernel->yield('child_error', 'packet processing', undef, 'no handler for packet type '.$packet_type);
		return;
	}

	# handle authentication requests
	if ($packet_type == TAC_PLUS_AUTHEN) {
		# check if we have handler for current authentification type
		my $authen_type = $packet->body->authen_type;
		$handler = $handler->{$authen_type};
		if (not defined $handler) {
			$kernel->yield('child_error', 'authentication', undef, 'no handler for authen_type '.$authen_type.' (wrong key?)');
			return;
		};

		# construct default reply packet
		$reply = Net::TacacsPlus::Packet->new(
			'version'     => $packet->version,
			'type'        => TAC_PLUS_AUTHEN,
			'seq_no'      => $packet->seq_no + 1,
			'session_id'  => $packet->session_id,

			'key'         => $heap->{'key'},
			'authen_type' => $authen_type,
			'flags'       => 0,
			'status'      => TAC_PLUS_AUTHEN_STATUS_FAIL,
		);
		
		# call handler and update returned status according to the reply
		if ($handler->($packet->body->user, $packet->body->data)) {
			$reply->status(TAC_PLUS_AUTHEN_STATUS_PASS);
		}
		else {
			$reply->status(TAC_PLUS_AUTHEN_STATUS_FAIL);
		}
	}
	else {
		$kernel->yield('child_error', 'packet processing', undef, ' unsupported handler for packet type '.$packet_type);
		return;
	}

	$heap->{'readwrite'}->put($reply);
}


=head2 child_done

Cleanup after child is done.

=cut

sub child_done {
	my $heap = $_[HEAP];

	delete $heap->{'readwrite'};
	DEBUG "CHILD: disconnected from ", $heap->{'peername'};
}


=head2 child_error

Print out error and do cleanup.

=cut

sub child_error {
	my $operation = $_[ARG0];
	my $error_num = $_[ARG1] || '';
	my $error_msg = $_[ARG2];
	my $heap      = $_[HEAP];
	
	delete $heap->{'readwrite'};
	ERROR 'failed '.$operation.' ('.$error_num.') - '.$error_msg if $error_msg;
}

1;

=head1 SEE ALSO

tac-rfc.1.78.txt

Complete server script C<Net-TacacsPlus/examples/server.pl>.

=cut
