package Protocol::SOCKS::Server;
$Protocol::SOCKS::Server::VERSION = '0.003';
use strict;
use warnings;

use parent qw(Protocol::SOCKS);

=head1 NAME

Protocol::SOCKS::Server - server support for SOCKS protocol

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

This provides an abstraction for dealing with the server side of the SOCKS protocol.

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

Handler for reading data from the client.

=cut

sub on_read {
	my ($self, $buf) = @_;
	if(!$self->init->is_ready) {
		return if length($$buf) < 3;
		my (undef, $method_count) = unpack 'C1C', substr $$buf, 0, 2;
		return unless length($$buf) >= 2 + $method_count;

		my ($version, $methods) = unpack 'C1C/C*', substr $$buf, 0, 2 + $method_count, '';
		die "Invalid version" unless $version == $self->version;
		my $auth_method;
		METHOD:
		for my $method (split //, $methods) {
			next METHOD unless grep $method == $_, $self->auth_methods;
			$auth_method = $method;
			last METHOD;
		}
		unless(defined $auth_method) {
			$self->write(
				pack 'C1C1',
					$self->version,
					AUTH_FAIL,
			);
			return $self->init->fail(auth => 'no suitable methods');
		}
		$self->init->done($version => $auth_method);
		return $self->write(
			pack 'C1C1',
				$self->version,
				$auth_method
		)
	}

	return unless my $details = $self->parse_request($buf);

	my $f = shift @{$self->{awaiting_reply}};
	$f->done($details);
}

=head2 init

Resolves with version and auth method when connection
has been established

=cut

sub init { $_[0]->{init} ||= $_[0]->new_future }

=head2 parse_request

Parse a client request.

=cut

sub parse_request {
	my ($self, $buffref) = @_;
	return unless length $$buffref >= 6;
	my ($version, $cmd, $reserved, $atype) = unpack 'C1C1C1C1', substr $$buffref, 0, 4;
	die "unknown command $cmd" unless $cmd > 0 && $cmd < 4;

	substr $$buffref, 0, 3, '';
	my $addr = $self->extract_address($buffref);
	my $port = unpack 'n1', substr $$buffref, 0, 2, '';
	warn "Addr $addr, port $port\n";
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014. Licensed under the same terms as Perl itself.
