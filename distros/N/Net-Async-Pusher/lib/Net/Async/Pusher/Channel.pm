package Net::Async::Pusher::Channel;
$Net::Async::Pusher::Channel::VERSION = '0.002';
use strict;
use warnings;

=head1 NAME

Net::Async::Pusher::Connection - represents one L<Net::Async::Pusher> server connection

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Provides basic integration with the L<https://pusher.com|Pusher> API.

=cut

use Mixin::Event::Dispatch::Bus;
use JSON::MaybeXS;
use Log::Any qw($log);

sub new {
	my ($class) = shift;
	bless { @_ }, $class
}
sub loop { shift->{loop} }

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }

sub json { shift->{json} //= JSON::MaybeXS->new( allow_nonref => 1) }

sub subscribe {
	my ($self) = shift;
	my @sub;
	while(my ($k, $v) = splice @_, 0, 2) {
		$k = "event::$k";
		$self->bus->subscribe_to_event($k => $v);
		push @sub, $k => $v;
	}
	Future->done(sub {
		while(my ($k, $v) = splice @sub, 0, 2) {
			eval {
				$self->bus->unsubscribe_from_event($k => $v);
			};
		}
		Future->done;
	})
}

sub incoming_message {
	my ($self, $info) = @_;
	if($info->{event} eq 'pusher_internal:subscription_succeeded') {
		return $self->subscribed->done
	} else {
		eval {
			my $data = $self->json->decode($info->{data});
			$self->bus->invoke_event(
				"event::" . $info->{event} => $data
			);
			1
		} or do $log->errorf("Exception [%s] on %s", $@, $info->{data})
	}
}

sub subscribed { $_[0]->{subscribed} //= $_[0]->loop->new_future }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2016. Licensed under the same terms as Perl itself.
