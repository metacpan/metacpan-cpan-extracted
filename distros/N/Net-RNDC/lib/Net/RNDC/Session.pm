package Net::RNDC::Session;
{
  $Net::RNDC::Session::VERSION = '0.003';
}

use strict;
use warnings;

use Net::RNDC::Packet;

use Carp qw(croak);

# Controls the flow in next(). undef means next() should never
# be called if we've reached this state
my %states = (
	start        => '_got_start',
	want_read    => '_got_read',
	want_write   => '_got_write',
	want_error   => undef,
	want_finish  => undef,
);

sub new {
	my ($class, %args) = @_;

	my @required_subs = qw(
		want_read
		want_write
		want_finish
		want_error
	);

	my @optional_subs = qw(
	);

	my @required_args = qw(
		key
		command
	);

	my @optional_args = qw(
		is_client
		is_server
	);

	for my $r (@required_subs, @required_args) {
		unless (exists $args{$r}) {
			croak("Missing required argument '$r'");
		}
	}

	unless (exists $args{is_client} || exists $args{is_server}) {
		croak("Argument 'is_client' or 'is_server' must be defined");
	}

	for my $r (@required_subs, @optional_subs) {
		next unless exists $args{$r};

		unless ((ref $args{$r} || '') eq 'CODE') {
			croak("Argument '$r' is not a code ref");
		}
	}

	if (exists $args{is_client} && exists $args{is_server}) {
		croak("Argument 'is_client' cannot be mixed with 'is_server'");
	}

	my %obj = map {
		$_ => $args{$_}
	} grep { exists $args{$_} } (@required_subs, @optional_subs, @required_args, @optional_args);

	if (exists $args{is_client}) {
		$obj{is_client} = 1;
	} else {
		$obj{is_server} = 1;
	}

	my $obj = bless \%obj, $class;

	# Base state
	$obj->_init;

	return $obj;
}

# Maybe open up to public as reset()?
sub _init {
	my ($self) = @_;

	# Have we sent our syn/ack opener?
	$self->{nonce} = 0;

	$self->_state('start');
}

# Set/retrieve state
sub _state {
	my ($self, $state) = @_;

	if ($state) {
		unless (exists $states{$state}) {
			croak("Unknown state $state requested");
		}

		$self->{state} = $state;
	}

	return $self->{state};
}

sub _is_client { return $_[0]->{'is_client'} }
sub _is_server { return $_[0]->{'is_server'} }
sub _key       { return $_[0]->{'key'}       }
sub _nonce     { return $_[0]->{'nonce'}     }
sub _command   { return $_[0]->{'command'}   }

# Entry point. Always.
sub start {
	my ($self) = @_;

	unless (my $state = $self->_state eq 'start') {
		croak("Attempt to re-use an existing session in state '$state'");
	}

	$self->next;
}

# Move things along. Pass in data if needed
sub next {
	my ($self, $data) = @_;

	my $sub = $states{$self->_state};

	unless ($sub) {
		croak("next() called on bad state '" . $self->_state . "'");
	}

	$self->$sub($data);

	return;
}

# _got subs are called after a want_* sub has been called and next() has been used

# Starting out
sub _got_start {
	my ($self, $data) = @_;

	if ($self->_is_client) {
		# Client step 1: send a request packet with no data section
		my $packet = Net::RNDC::Packet->new(
			key => $self->_key,
		);

		$self->_state('want_write');

		return $self->_run_want('want_write', $packet->data, $packet);
	} else {
		# Server step 1: expect a packet with no data section
		$self->_state('want_read');

		return $self->_run_want('want_read');
	}
}

sub _got_read {
	my ($self, $data) = @_;

	if ($self->_is_client) {
		my $packet = Net::RNDC::Packet->new(key => $self->_key);

		if (!$packet->parse($data)) {
			$self->_state('want_error');

			return $self->_run_want('want_error', $packet->error);
		}

		if (! $self->_nonce) {
			# Client step 2: Parse response, get nonce
			$self->{nonce} = 1;

			my $nonce = $packet->{data}->{_ctrl}{_nonce};

			# Client step 3: Send request with nonce/data section
			my $packet2 = Net::RNDC::Packet->new(
				key => $self->_key,
				nonce => $nonce,
				data => {type => $self->_command},
			);

			$self->_state('want_write');

			return $self->_run_want('want_write', $packet2->data, $packet2);
		} else {
			# Client step 4: Read response to command
			my $response = $packet->{data}{_data}{text} || 'command success';

			$self->_state('want_finish');

			return $self->_run_want('want_finish', $response);
		}
	} else {
		my $packet = Net::RNDC::Packet->new(key => $self->_key);

		if (!$packet->parse($data)) {
			$self->_state('want_error');

			return $self->_run_want('want_error', $packet->error);
		}

		if (! $self->_nonce) {
			$self->{nonce} = 1;

			my $nonce = int(rand(2**32));

			$self->{_nonce_data} = $nonce;

			my $challenge = Net::RNDC::Packet->new(
				key => $self->_key,
				nonce => $nonce,
			);

			$self->_state('want_write');

			return $self->_run_want('want_write', $challenge->data, $challenge);
		} else {
			my $nonce = $self->{_nonce_data};

			# TODO: Add time/expiry checking
			# Invalid: (_tim + clockskew < now || _tim - clockskew > now)
			# Invalid: now > exp
			# Also check serial?

			unless ($packet->{data}->{_ctrl}{_nonce}) {
				$self->_state('want_error');

				return $self->_run_want('want_error', "Client nonce not set");	
			}

			unless ($packet->{data}->{_ctrl}{_nonce} == $nonce) {
				$self->_state('want_error');

				return $self->_run_want('want_error', "Client nonce does not match");
			}

			my $response = Net::RNDC::Packet->new(
				key => $self->_key,
				data => {text => $self->_command},
			);

			$self->_state('want_write');

			$self->_run_want('want_write', $response->data, $response);

			$self->_state('want_finish');

			$self->_run_want('want_finish');
		}
	}
}

sub _got_write {
	my ($self) = @_;

	# As a client, after every write we expect a read
	if ($self->_is_client) {
		$self->_state('want_read');

		return $self->_run_want('want_read');
	} elsif ($self->_is_server) {
		$self->_state('want_read');

		return $self->_run_want('want_read');
	}
}

# Run the requested want_* sub
sub _run_want {
	my ($self, $sub, @args) = @_;

	my $ref = $self->{$sub};

	$ref->($self, @args);
}

1;
__END__

=head1 NAME

Net::RNDC::Session - Helper package to manage the RNDC 4-packet session

=head1 VERSION

version 0.003

=head1 SYNOPSIS

To use synchronously as a client:

  use IO::Socket::INET;
  use Net::RNDC::Session;

  my $c = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1:953',
  ) or die "Failed to create a socket: $@ ($!)";

  # Our response
  my $response;

  my $session = Net::RNDC::Session->new(
    key         => 'abcd',
    command     => 'status',
    is_client   => 1,

    want_write =>  sub { my $s = shift; $c->send(shift); $s->next; },
    want_read  =>  sub { my $s = shift; my $b; $c->recv($b, 4096); $s->next($b); },
    want_finish => sub { my $s = shift; $response = shift; },
    want_error =>  sub { my $s = shift; my $err = shift; die "Error: $err\n"; },
  );

  # Since we call next() in want_read/want_write above, this will do everything
  $session->start;

  print "Response: $response\n";

To use asynchronously (for example, with IO::Async):

TBD

To use as a server:

TBD

To use asynchronously as a server:

TBD

=head1 DESCRIPTION

This package is intended to provide the logic for an RNDC client session which 
can used  to run a single command against a remote server and get a response.
See L</SESSION> below for a description of the RNDC client session logic.

This package also supports running sessions as an RNDC server.

For simple use of the RNDC protocol, see L<Net::RNDC>.

There is no socket logic here, that must be provided to this class through the 
constructor in the various C<want_*> methods. This allows for 
synchronous/asynchronous use with a little work.

This package does generate and parse L<Net::RNDC::Packet>s, but the 
L</want_read> and L</want_write> methods allow you to peak at this data before 
it's parsed and before it's sent to the remote end to allow slightly more 
fine-grained control.

To manage the entire process yourself, use L<Net::RNDC::Packet>.

=head1 SESSION

An RNDC client session (where one is sending commands to a remote nameserver 
expecting a response) contains 4 packets.

All packets contain a timestamp/expiracy timestamp to denote a packet validity 
window, as well as an HMAC-MD5 signature of the packets data using a shared 
private key, and a serial number to identify the packet.

=over 4

=item 1

  CLIENT->send(<opening packet>)

The opening packet contains a '_data' section with an undef 'type'.

=item 2

  SERVER->send(<nonce packet>)

The server response packet contains a 'nonce' integer which should be 
copied into the next request.

=item 3

  CLIENT->send(<command packet>)

The nonce should be included in the command packet in the '_ctrl' section, and 
the command to be run on the remote section should be in the 'type' parameter of 
the '_data' section.

=item 4

  SERVER->send(<response packet>)

The response packet will contain an 'error' parameter in the '_data' section if 
something went wrong, otherwise the response will be in the 'text' parameter of 
the '_data' section.

=back

If at any time the remote end disconnects prematurely, this may indicate any of 
the following (along with normal network issues):

=over 4

=item *

The clocks are off

=item *

The key is incorrect

=item *

The window has expired

=back

=head1 SEE ALSO

L<Net::RNDC> - Simple RNDC communication.

L<Net::RNDC::Packet> - Low level RNDC packet manipulation.

=head1 AUTHOR

Matthew Horsfall (alh) <WolfSage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
