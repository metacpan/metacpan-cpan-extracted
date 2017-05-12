package Net::Async::AMQP::RPC::Client;
$Net::Async::AMQP::RPC::Client::VERSION = '2.000';
use strict;
use warnings;

use parent qw(Net::Async::AMQP::RPC::Base);

=head1 NAME

Net::Async::AMQP::RPC::Client - client RPC handling

=head1 VERSION

version 2.000

=head1 DESCRIPTION

Provides a client implementation for RPC handling.

=over 4

=item * Declare a new temporary queue

=item * Start a consumer on the queue

=item * Publish requests to the RPC exchange, using our (server-assigned) queue name as the reply_to address

=item * Responses to our queue are matched against original requests using the correlation_id field

=back

=cut

use Log::Any qw($log);

BEGIN {
	eval {
		require UUID::Tiny;
		*next_id = sub { UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V1()) }
	} or do {
		$log->warnf("No UUID::Tiny found, using custom fallback. Install the UUID::Tiny module to avoid this warning");
		# If we don't have a UUID implementation, get something that's
		# random-ish as a workaround
		my @chars = 'a'..'z';
		my $id = join '',
			(map $chars[rand @chars], 1..8),
			(sprintf '%x', time),
			'000000'
		;
		*next_id = sub { ++$id }
	}
}

sub request {
	my ($self, $type, $payload, %args) = @_;
	my $id = $self->next_id;
	Future->needs_all(
		$self->publisher_channel,
		$self->queue_name,
		$self->consumer,
	)->then(sub {
		my ($ch, $queue_name) = @_;
		$self->{pending_requests}{$id} = {
			type => $type,
			future => my $f = $self->loop->new_future->set_label('RPC response for ' . $id),
		};
		$log->debugf(
			"Publishing with correlation ID [%s] and reply_to [%s], type %s",
			$id,
			$queue_name,
			$type
		);
		$ch->publish(
			exchange       => $self->exchange,
			routing_key    => $self->routing_key,
			reply_to       => $queue_name,
			delivery_mode  => 2, # persistent
			correlation_id => $id,
			type           => $type,
			payload        => $payload,
			%args
		)->then(sub {
			$f
		});
	});
}

my $json;
sub json_request {
	my ($self, $cmd, $args) = @_;
	$json ||= do {
		eval {
			require JSON::MaybeXS;
		} or die "->json_request requires the JSON::MaybeXS module, which could not be loaded:\n$@";
		$json = JSON::MaybeXS->new;
	};
	$self->request(
		$cmd,
		$json->encode($args),
		content_type => 'application/json',
	)->then(sub {
		my $data = shift;
		eval {
			Future->done($json->decode($data))
		} or do {
			Future->fail("Invalid JSON data: " . $data);
		}
	});
}

sub process_message {
	my ($self, %args) = @_;
	# $log->infof("Have message: %s", join ' ', %args);
	if(my $item = $self->{pending_requests}{$args{id}}) {
		if($item->{type} eq $args{type}) {
			$item->{future}->done($args{payload})
		} else {
			$log->errorf("Have pending item ID %s but type does not match: had %s, expecting %s", $args{id}, $args{type}, $item->{type});
			$item->{future}->fail("invalid type");
		}
	} else {
		$log->errorf("No pending request for ID %s, type %s", $args{id}, $args{type})
	}
	return '';
}

sub queue { shift->client_queue }

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
