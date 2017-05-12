package Net::Async::Pusher::Connection;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.002';

=head1 NAME

Net::Async::Pusher::Connection - represents one L<Net::Async::Pusher> server connection

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Provides basic integration with the L<https://pusher.com|Pusher> API. This implements
the protocol as documented in L<https://pusher.com/docs/pusher_protocol>.

=cut

use Mixin::Event::Dispatch::Bus;
use Net::Async::WebSocket::Client;
use IO::Async::SSL;
use HTML::Entities ();
use JSON::MaybeXS;
use curry::weak;
use Time::HiRes;
use Log::Any qw($log);
use Variable::Disposition qw(retain_future);

use Net::Async::Pusher::Channel;

=head1 METHODS

=cut

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }

sub json { shift->{json} //= JSON::MaybeXS->new( allow_nonref => 1) }

=head2 send_ping

Sends a ping request on this connection.

=cut

sub send_ping {
	my ($self) = @_;
	$self->client->send_frame($self->json->encode({
		event => 'pusher:ping',
		data  => { }
	}));
	if(my $timer = $self->{inactivity_timeout}) {
		$timer->stop if $timer->is_running;
		$timer->reset;
		$timer->start;
	}
	$self
}

=head2 incoming_frame

Deals with incoming frames.

=cut

sub incoming_frame {
	my $self = shift;
	my ($client, $frame) = @_;

	return unless defined($frame) && length($frame);

	eval {
		$log->tracef("Frame [%s]", $frame);
		$self->{last_seen} = time;
		my $info = $self->json->decode($frame);
		if(exists $info->{channel}) {
			return $self->{channel}{$info->{channel}}->incoming_message($info);
		} elsif($info->{event} eq 'pusher:connection_established') {
			my $data = $self->json->decode($info->{data});
			$self->{socket_id} = $data->{socket_id};
			$self->add_child(
				$self->{inactivity_timer} = IO::Async::Timer::Countdown->new(
					delay => $data->{activity_timeout},
					on_expire => $self->curry::weak::send_ping,
				)
			);
			return $self->connected->done;
		} elsif($info->{event} eq 'pusher:ping') {
			return $self->client->send_frame($self->json->encode({
				event => 'pusher:pong',
				data  => { }
			}));
		} elsif($info->{event} eq 'pusher:pong') {
			return $log->trace("Pong event received from pusher");
		}
		die "unhandled"
	} or do {
		my $err = $@;
		$log->errorf("Unexpected frame (%s) [%s]", $err, $frame);
		$self->bus->invoke_event(
			error => $err, $frame
		);
	}
}

sub socket_id { shift->{socket_id} }

=head2 client

Returns the L<Net::Async::WebSocket::Client> instance.

=cut

sub client { shift->{client} }

=head2 open_channel

Opens a channel.

 my $ch = $conn->open_channel(
  'xyz'
 )->get;

Resolves to a L<Net::Async::Pusher::Channel> instance.

=cut

sub open_channel {
	my ($self, $name, %args) = @_;
	$self->connected->then(sub {
		$log->tracef("Subscribing to [%s]", $name);
		my $ch = $self->{channel}{$name} = Net::Async::Pusher::Channel->new(
			loop => $self->loop,
			name => $name,
		);
		my $frame = $self->json->encode({
			event => 'pusher:subscribe',
			# double-encoded
			data  => {
				(exists $args{auth} ? (auth => $args{auth}) : ()),
				channel => $name
			}
		});
		$log->tracef("Subscribing: %s", $frame);
		$self->client->send_frame($frame);
		$self->{channel}{$name}->subscribed->transform(
			done => sub { $ch }
		)
	});
}

=head2 connect

(Re)connects to the feed.

=cut

sub connect {
	my ($self) = @_;
	$self->add_child(
		 $self->{client} = Net::Async::WebSocket::Client->new(
			on_frame => $self->curry::weak::incoming_frame,
		)
	);
	retain_future(
		$self->client->connect(
			# all lovely hardcoded magic here
			host    => 'ws.pusherapp.com',
			service => 443,
			url     => 'wss://ws.pusherapp.com/app/' . $self->key . '?protocol=7&client=perl-net-async-pusher&version=' . $self->VERSION,
			extensions => [ qw(SSL) ],
		)->then(sub {
			# don't seem to get any response until we send something first
			$self->send_ping;
			Future->done($self)
		})
	)
}

=head2 connected

L<Future> representing current connection state.

=cut

sub connected { $_[0]->{connected} ||= $_[0]->loop->new_future }

sub configure {
	my ($self, %args) = @_;
	for(grep exists $args{$_}, qw(key)) {
		$self->{$_} = delete $args{$_};
	}
	$self->SUPER::configure(%args);
}

=head2 key

The key.

=cut

sub key { shift->{key} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2016. Licensed under the same terms as Perl itself.
