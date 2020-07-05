package Net::Async::Slack::RTM;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::Slack::RTM - realtime messaging support for L<https://slack.com>

=head1 DESCRIPTION

This is a basic wrapper for Slack's RTM features.

The realtime messaging API is mostly useful as an event stream. Although it is
possible to send messages through this API as well - see L</send_message> - the
main HTTP API offers more features.

For a full list of events, see L<https://api.slack.com/events>.

=cut

no indirect;
use mro;

use Future;
use Dir::Self;
use URI;
use URI::QueryParam;
use URI::Template;
use JSON::MaybeXS;
use Time::Moment;
use Syntax::Keyword::Try;

use IO::Async::Timer::Countdown;
use Net::Async::WebSocket::Client;

use Net::Async::Slack::Event::AccountsChanged;
use Net::Async::Slack::Event::AppHomeOpened;
use Net::Async::Slack::Event::AppMention;
use Net::Async::Slack::Event::AppRateLimited;
use Net::Async::Slack::Event::AppUninstalled;
use Net::Async::Slack::Event::BotAdded;
use Net::Async::Slack::Event::BotChanged;
use Net::Async::Slack::Event::Bot;
use Net::Async::Slack::Event::ChannelArchive;
use Net::Async::Slack::Event::ChannelCreated;
use Net::Async::Slack::Event::ChannelDeleted;
use Net::Async::Slack::Event::ChannelHistoryChanged;
use Net::Async::Slack::Event::ChannelJoined;
use Net::Async::Slack::Event::ChannelLeft;
use Net::Async::Slack::Event::ChannelMarked;
use Net::Async::Slack::Event::Channel;
use Net::Async::Slack::Event::ChannelRename;
use Net::Async::Slack::Event::ChannelUnarchive;
use Net::Async::Slack::Event::CommandsChanged;
use Net::Async::Slack::Event::DndUpdated;
use Net::Async::Slack::Event::DndUpdatedUser;
use Net::Async::Slack::Event::EmailDomainChanged;
use Net::Async::Slack::Event::EmojiChanged;
use Net::Async::Slack::Event::FileChange;
use Net::Async::Slack::Event::FileCommentAdded;
use Net::Async::Slack::Event::FileCommentDeleted;
use Net::Async::Slack::Event::FileCommentEdited;
use Net::Async::Slack::Event::FileCreated;
use Net::Async::Slack::Event::FileDeleted;
use Net::Async::Slack::Event::FilePublic;
use Net::Async::Slack::Event::FileShared;
use Net::Async::Slack::Event::FileUnshared;
use Net::Async::Slack::Event::Goodbye;
use Net::Async::Slack::Event::GridMigrationFinished;
use Net::Async::Slack::Event::GridMigrationStarted;
use Net::Async::Slack::Event::GroupArchive;
use Net::Async::Slack::Event::GroupClose;
use Net::Async::Slack::Event::GroupDeleted;
use Net::Async::Slack::Event::GroupHistoryChanged;
use Net::Async::Slack::Event::GroupJoined;
use Net::Async::Slack::Event::GroupLeft;
use Net::Async::Slack::Event::GroupMarked;
use Net::Async::Slack::Event::GroupOpen;
use Net::Async::Slack::Event::GroupRename;
use Net::Async::Slack::Event::GroupUnarchive;
use Net::Async::Slack::Event::Hello;
use Net::Async::Slack::Event::ImClose;
use Net::Async::Slack::Event::ImCreated;
use Net::Async::Slack::Event::ImHistoryChanged;
use Net::Async::Slack::Event::ImMarked;
use Net::Async::Slack::Event::ImOpen;
use Net::Async::Slack::Event::LinkShared;
use Net::Async::Slack::Event::ManualPresenceChange;
use Net::Async::Slack::Event::MemberJoinedChannel;
use Net::Async::Slack::Event::MemberLeftChannel;
use Net::Async::Slack::Event::MessageAppHome;
use Net::Async::Slack::Event::MessageChannels;
use Net::Async::Slack::Event::MessageGroups;
use Net::Async::Slack::Event::MessageIm;
use Net::Async::Slack::Event::MessageMpim;
use Net::Async::Slack::Event::Message;
use Net::Async::Slack::Event::PinAdded;
use Net::Async::Slack::Event::PinRemoved;
use Net::Async::Slack::Event::PrefChange;
use Net::Async::Slack::Event::PresenceChange;
use Net::Async::Slack::Event::PresenceQuery;
use Net::Async::Slack::Event::PresenceSub;
use Net::Async::Slack::Event::ReactionAdded;
use Net::Async::Slack::Event::ReactionRemoved;
use Net::Async::Slack::Event::ReconnectURL;
use Net::Async::Slack::Event::ResourcesAdded;
use Net::Async::Slack::Event::ResourcesRemoved;
use Net::Async::Slack::Event::ScopeDenied;
use Net::Async::Slack::Event::ScopeGranted;
use Net::Async::Slack::Event::StarAdded;
use Net::Async::Slack::Event::StarRemoved;
use Net::Async::Slack::Event::SubteamCreated;
use Net::Async::Slack::Event::SubteamMembersChanged;
use Net::Async::Slack::Event::SubteamSelfAdded;
use Net::Async::Slack::Event::SubteamSelfRemoved;
use Net::Async::Slack::Event::SubteamUpdated;
use Net::Async::Slack::Event::TeamDomainChange;
use Net::Async::Slack::Event::TeamJoin;
use Net::Async::Slack::Event::TeamMigrationStarted;
use Net::Async::Slack::Event::TeamPlanChange;
use Net::Async::Slack::Event::TeamPrefChange;
use Net::Async::Slack::Event::TeamProfileChange;
use Net::Async::Slack::Event::TeamProfileDelete;
use Net::Async::Slack::Event::TeamProfileReorder;
use Net::Async::Slack::Event::TeamRename;
use Net::Async::Slack::Event::TokensRevoked;
use Net::Async::Slack::Event::URLVerification;
use Net::Async::Slack::Event::UserChange;
use Net::Async::Slack::Event::UserResourceDenied;
use Net::Async::Slack::Event::UserResourceGranted;
use Net::Async::Slack::Event::UserResourceRemoved;
use Net::Async::Slack::Event::UserTyping;

use Log::Any qw($log);

my $json = JSON::MaybeXS->new;

=head1 METHODS

=head2 events

This is the stream of events, as a L<Ryu::Source>.

Example usage:

 $rtm->events
     ->filter(type => 'message')
     ->sprintf_methods('> %s', $_->text)
     ->say
     ->await;

=cut

sub events {
    my ($self) = @_;
    $self->{events} //= do {
        $self->ryu->source
    }
}

=head2 send_message

Sends a message to a user or channel.

This is limited (by the Slack API) to the L<default message formatting mode|https://api.slack.com/docs/formatting>,
so it's only useful for simple messages.

Takes the following named parameters:

=over 4

=item * id - custom message ID (optional)

=item * channel - either a L<Net::Async::Slack::Channel> instance, or a channel ID

=back

=cut

sub send_message {
    my ($self, %args) = @_;
    my $id = $self->next_id($args{id});
    my $f = $self->loop->new_future;
    $self->ws->send_frame(
        buffer => $json->encode({
            type    => 'message',
            id      => $id,
            channel => (ref $args{channel} ? $args{channel}->id : $args{channel}),
            text    => $args{text},
        }),
        masked => 1
    );
    $self->{pending_message}{$id} = $f;
}

=head1 METHODS - Internal

You may not need to call these directly. If I'm wrong and you find yourself having
to do that, please complain via the usual channels.

=head2 connect

Establishes the connection. Called by the top-level L<Net::Async::Slack> instance.

=cut

sub connect {
    my ($self, %args) = @_;
    my $uri = $self->wss_uri or die 'no websocket URI available';
    $self->add_child(
        $self->{ws} = Net::Async::WebSocket::Client->new(
            on_frame => $self->curry::weak::on_frame,
        )
    );
    $log->tracef('URL for websockets will be %s', "$uri");
    $self->{ws}->connect(
        url        => "$uri",
    )
}

sub on_frame {
    my ($self, $ws, $bytes) = @_;
    my $text = Encode::decode_utf8($bytes);

    # Empty frame is used for PING, send a response back
    if(!length($text)) {
        $ws->send_frame('');
    } else {
        $log->tracef("<< %s", $text);
        try {
            my $data = $json->decode($text);
            if(my $id = $data->{reply_to}) {
                if(my $f = delete $self->{pending_message}{$id}) {
                    if($data->{ok}) {
                        $f->done(
                            id => $id,
                            ts => $data->{ts},
                            text => $data->{text},
                        );
                    } else {
                        $f->fail(
                            'Failed to send message: ' . $data->{error}{msg},
                            'slack_rtm',
                            code => @{$data->{error}}{qw(code msg)}
                        );
                    }
                } else {
                    # This can happen with the initial stream of events, so maybe
                    # a warning is not necessary.
                    $log->warnf('Had reply %s to message, but it was not listed as pending, content is %s', $id, $data);
                }
            } elsif(my $ev = Net::Async::Slack::EventType->from_json($data)) {
                $log->tracef("Have event [%s], emitting", $ev->type);
                $self->events->emit($ev);
            } else {
                $self->events->emit($data);
            }
        } catch {
            $log->errorf("Exception in websocket raw frame handling: %s (original text %s)", $@, $text);
        }
    }
}

sub slack { shift->{slack} }

sub wss_uri { shift->{wss_uri} }

sub ws { shift->{ws} }

sub ryu { shift->{ryu} }

sub next_id {
    my ($self, $id) = @_;
    $self->{last_id} = $id // ++$self->{last_id};
}

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(slack wss_uri)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub ping_timer {
    my ($self) = @_;
    $self->{ping_timer} ||= do {
        $self->add_child(
            my $timer = IO::Async::Timer::Countdown->new(
                delay => 10,
                on_expire => $self->curry::weak::trigger_ping,
            )
        );
        $timer
    }
}

sub trigger_ping {
    my ($self, %args) = @_;
    my $id = $self->next_id($args{id});
    $self->ws->send_frame(
        buffer => $json->encode({
            type    => 'ping',
            id      => $id,
        }),
        masked => 1
    );
    $self->ping_timer->reset;
    $self->ping_timer->start if $self->ping_timer->is_expired;
}

sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->add_child(
        $self->{ryu} = Ryu::Async->new
    );
    $self->ping_timer->start;
    $self->{last_id} //= 0;
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.

