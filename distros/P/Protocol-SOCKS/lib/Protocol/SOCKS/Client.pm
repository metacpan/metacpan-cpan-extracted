package Protocol::SOCKS::Client;
$Protocol::SOCKS::Client::VERSION = '0.003';
use strict;
use warnings;

use parent qw(Protocol::SOCKS);

=head1 NAME

Protocol::SOCKS::Client - client support for SOCKS protocol

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

This provides an abstraction for dealing with the client side of the SOCKS protocol.

=cut

use Future;
use Socket qw(inet_pton inet_ntop inet_ntoa AF_INET AF_INET6);

use Protocol::SOCKS::Constants qw(:all);

=head1 METHODS

=cut

=head2 completion

Returns the completion future.

=cut

sub completion { $_[0]->{completion} ||= $_[0]->new_future }

=head2 auth

Returns the auth Future.

=cut

sub auth { $_[0]->{auth} ||= $_[0]->new_future }

=head2 auth_methods

Returns the list of auth methods we can handle.

=cut

sub auth_methods {
	my $self = shift;
	@{ $self->{auth_methods} ||= [ AUTH_NONE ] }
}

=head2 init_packet

Initial client packet.

=cut

sub init_packet {
	my $self = shift;
	my @methods = (0);
	pack 'C1C/C*', $self->version, $self->auth_methods;
}

=head2 on_read

Handler for reading data from the server.

=cut

sub on_read {
	my ($self, $buf) = @_;
	if(!$self->auth->is_ready) {
		return unless length($$buf) >= 2;
		my ($version, $method) = unpack 'C1C1', substr $$buf, 0, 2, '';
		die "Unexpected version" unless $version == $self->version;
		if($method == 0xFF) {
			$self->auth->fail($method);
		} else {
			$self->auth->done($method);
		}
		return;
	} else {
		# warn "non-auth, have " . length($$buf) . "bytes";
		return unless my ($host, $port) = $self->parse_reply($buf);

		my $f = shift @{$self->{awaiting_reply}};
		$f->done($host, $port);
	}
}

=head2 init

Startup - writes the initial packet to the server.

=cut

sub init {
	my $self = shift;
	$self->write($self->init_packet);
}

=head2 connect

Issues a connection request.

=cut

sub connect {
	my ($self, $atype, $addr, $port) = @_;
	my $f = $self->new_future;
	my $opaque_addr = $self->pack_address($atype, $addr);
	push @{$self->{awaiting_reply}}, $f;
	$self->write(
		pack(
			'C1C1C1',
			$self->version,
			0x01,
			0x00,
		) . $opaque_addr . pack('n1', $port)
	);
	$f;
}

=head2 parse_reply

Parse a server reply.

=cut

sub parse_reply {
	my ($self, $buffref) = @_;
	return unless length $$buffref >= 4;
	my ($version, $status, $reserved, $atype) = unpack 'C1C1C1C1', substr $$buffref, 0, 4;
	if($status != 0) {
		# warn $Protocol::SOCKS::REPLY_CODE{$status};
		return;
	}

	substr $$buffref, 0, 3, '';
	my $addr = $self->extract_address($buffref);
	my $port = unpack 'n1', substr $$buffref, 0, 2, '';
	# warn "Addr $addr, port $port\n";
	return $addr, $port;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014. Licensed under the same terms as Perl itself.
