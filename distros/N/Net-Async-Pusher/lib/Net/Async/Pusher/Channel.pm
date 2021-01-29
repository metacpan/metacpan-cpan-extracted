package Net::Async::Pusher::Channel;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Net::Async::Pusher::Channel - represents a channel on a L<Net::Async::Pusher::Connection>.

=head1 DESCRIPTION

Provides basic integration with the L<https://pusher.com|Pusher> API.

=cut

use Syntax::Keyword::Try;
use Mixin::Event::Dispatch::Bus;
use JSON::MaybeXS;
use Ryu::Async;

use Log::Any qw($log);

sub configure {
    my ($self, %args) = @_;
    for (qw(name)) {
        $self->{$_} = delete $args{$_} if exists $args{$_};
    }
    return $self->SUPER::configure(%args);
}

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }
sub json { shift->{json} //= JSON::MaybeXS->new( allow_nonref => 1) }

sub ryu { shift->{ryu} }

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
            try {
                $self->bus->unsubscribe_from_event($k => $v);
            } catch {
                $log->errorf('Failed to unsubscribe from %s - %s', $k, $@);
            }
        }
        Future->done;
    })
}

sub incoming_message {
    my ($self, $info) = @_;
    if($info->{event} eq 'pusher_internal:subscription_succeeded') {
        return $self->subscribed->done
    } else {
        try {
            my $data = $self->json->decode($info->{data});
            if(my $bus = $self->{bus}) {
                $self->bus->invoke_event(
                    "event::" . $info->{event} => $data
                );
            }
            if(my $src = $self->{source}) {
                $src->emit($info);
            }
            1
        } catch {
            $log->errorf("Exception [%s] on %s", $@, $info->{data});
        }
    }
}

sub subscribed { $_[0]->{subscribed} //= $_[0]->loop->new_future }

=head2 source

Returns a L<Ryu::Source> which will emit an item for each event on the channel.

=cut

sub source {
    my ($self) = @_;
    $self->{source} //= $self->ryu->source
}

sub _add_to_loop {
    my ($self) = @_;
    $self->add_child(
        $self->{ryu} = Ryu::Async->new
    )
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2021. Licensed under the same terms as Perl itself.
