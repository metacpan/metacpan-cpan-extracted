package Net::Async::XMPP::Server;
$Net::Async::XMPP::Server::VERSION = '0.003';
use strict;
use warnings;
use parent qw(Net::Async::XMPP);

=head1 NAME

Net::Async::XMPP::Server - asynchronous XMPP server based on L<Protocol::XMPP> and L<IO::Async::Protocol::Stream>.

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Provides XMPP client support under L<IO::Async>.

See L<Protocol::XMPP> for more details on this implementation.

=head1 METHODS

=cut

sub connect {
	my $self = shift;
	my %params = @_;

# We either have a transport or information for the connection
	unless($params{transport}) {
		$self->_open_connection(%params);
		return;
	}

	my $transport = delete $params{transport};
	$self->configure(transport => $transport);

	$self->write($self->xmpp->preamble);
	$self;
}

sub _open_connection {
	my $self = shift;
	my %params = @_;

	my $on_connected = delete $params{on_connected} or die "Expected 'on_connected' as a CODE ref";

	$self->get_loop->connect(
		%params,
		socktype => 'stream',
		on_stream => sub {
			my ($stream) = @_;

			$self->connect(
				%params,
				transport => $stream,
				on_connected => $on_connected,
			);
		},
	);
	return;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
