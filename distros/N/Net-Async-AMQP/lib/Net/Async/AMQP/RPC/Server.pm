package Net::Async::AMQP::RPC::Server;
$Net::Async::AMQP::RPC::Server::VERSION = '2.000';
use strict;
use warnings;

use parent qw(Net::Async::AMQP::RPC::Base);

=head1 NAME

Net::Async::AMQP::RPC::Server - server RPC handling

=head1 VERSION

version 2.000

=head1 DESCRIPTION

Provides a basic server implementation for RPC handling.

=over 4

=item * Declare a queue

=item * Declare the RPC exchange

=item * Bind our queue to the exchange

=item * Start a consumer on the queue

=item * For each message, process via subclass-defined handlers and send a reply to the default ('') exchange with the reply_to as the routing key

=back

=cut

use Variable::Disposition qw(retain_future);

use Log::Any qw($log);

=head2 queue

Returns the server L<Net::Async::AMQP::Queue> instance.

=cut

sub queue { shift->server_queue }

=head2 json

Returns a L<JSON::MaybeXS> object, for ->encode and ->decode support. This will load L<JSON::MaybeXS> on first call.

=cut

sub json {
	shift->{json} //= do {
		eval {
			require JSON::MaybeXS;
		} or die "JSON RPC support requires the JSON::MaybeXS module, which could not be loaded:\n$@";
		JSON::MaybeXS->new
	}
}

=head2 process_message

Called when there is a message to process. Receives several named parameters:

=cut

sub process_message {
	my ($self, %args) = @_;
	$log->debugf("Have message: %s", join ' ', %args);
	if(my $code = $self->{json_handler}{$args{type}}) {
		# Run the code, and upgrade to a Future if necessary - we accept immediate values,
		# or Futures for deferred responses
		my $f = eval {
			$code->(%args) || die 'expected hashref or arrayref, had false'
		} || Future->fail($@);
		$f = Future->done($f) unless Scalar::Util::blessed($f) && $f->isa('Future');

		# Once our response is ready, send the reply
		retain_future(
			$f->then(sub {
				eval {
					Future->done($self->json->encode(shift))
				} or Future->fail({ error => 'failed to encode output' })
			}, sub {
				$self->json->encode({ error => shift })
			})->then(sub {
				my $v = shift;
				$self->reply(
					reply_to       => $args{reply_to},
					correlation_id => $args{id},
					type           => $args{type},
					content_type   => 'application/json',
					payload        => $v
				)
			})
		);
	} else {
		$self->reply(
			reply_to       => $args{reply_to},
			correlation_id => $args{id},
			type           => $args{type},
			content_type   => 'text/plain',
			payload        => 'no handler defined',
		);
	}
}

=head2 configure

Applies configuration:

=over 4

=item * json_handler - defines the JSON handlers for each type

=item * handler - defines default handlers

=back

=cut

sub configure {
	my ($self, %args) = @_;
	for (qw(json_handler handler)) {
		$self->{$_} = delete $args{$_} if exists $args{$_}
	}
	$self->SUPER::configure(%args)
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
