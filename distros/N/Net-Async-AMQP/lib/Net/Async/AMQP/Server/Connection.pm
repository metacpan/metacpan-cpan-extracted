package Net::Async::AMQP::Server::Connection;
$Net::Async::AMQP::Server::Connection::VERSION = '2.000';
use strict;
use warnings;

use parent qw(IO::Async::Stream);

=head1 NAME

Net::Async::AMQP::Server::Connection

=head1 VERSION

version 2.000

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use curry;

use Net::Async::AMQP;
use Net::Async::AMQP::Server::Protocol;

=head1 METHODS

=cut

=head2 protocol

Returns the L<Net::Async::AMQP::Server::Protocol> instance, creating a new one if necessary.

=cut

sub protocol {
	my $self = shift;
	$self->{protocol} ||= Net::Async::AMQP::Server::Protocol->new(
		write          => $self->curry::weak::write,
		future_factory => $self->loop->curry::weak::new_future,
	)
}

=head2 on_read

Handle incoming data by passing through to the
protocol instance.

=cut

sub on_read {
	my ($self, $buffer, $eof) = @_;
	$self->debug_printf("MQ connection - read %s", $$buffer);

	$self->{read_handler} ||= $self->protocol->can('on_read');
	while(1) {
		my $code = $self->{read_handler}->(
			$self->protocol,
			$buffer,
			$eof
		);
		return $code unless ref $code;

		# Replace our read handler if necessary
		$self->{read_handler} = $code;
	}
	die "unreachable"
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Licensed under the same terms as Perl itself, with additional licensing
terms for the MQ spec to be found in C<share/amqp0-9-1.extended.xml>
('a worldwide, perpetual, royalty-free, nontransferable, nonexclusive
license to (i) copy, display, distribute and implement the Advanced
Messaging Queue Protocol ("AMQP") Specification').
