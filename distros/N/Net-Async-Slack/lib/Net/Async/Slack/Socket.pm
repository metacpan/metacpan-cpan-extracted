package Net::Async::Slack::Socket;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::Slack::Socket - socket-mode notifications for L<https://slack.com>

=head1 DESCRIPTION

This is a basic wrapper for Slack's socket-mode features.

This provides an event stream using websockets.

For a full list of events, see L<https://api.slack.com/events>.

=cut

no indirect;
use mro;

use Future;
use Future::AsyncAwait;
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
use Net::Async::Slack::Event::BlockActions;
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
use Net::Async::Slack::Event::MessageAction;
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

=head1 METHODS - Internal

You may not need to call these directly. If I'm wrong and you find yourself having
to do that, please complain via the usual channels.

=head2 connect

Establishes the connection. Called by the top-level L<Net::Async::Slack> instance.

=cut

async sub connect {
    my ($self, %args) = @_;
    my $uri = $self->wss_uri or die 'no websocket URI available';
    $self->add_child(
        $self->{ws} = Net::Async::WebSocket::Client->new(
            on_frame => $self->curry::weak::on_frame,
            on_ping_frame => $self->curry::weak::on_ping_frame,
        )
    );
    $log->tracef('URL for websockets will be %s', "$uri");
    my $res = await $self->{ws}->connect(
        url        => "$uri",
    );
    $self->event_mangler;
    return $res;
}

sub on_ping_frame {
    my ($self, $ws, $bytes) = @_;
    $ws->send_pong_frame('');
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
            if(my $env_id = $data->{envelope_id}) {
                $self->ws->send_frame(
                    buffer => $json->encode({
                        envelope_id => $env_id
                    }),
                    masked => 1
                )->retain;
            }
            if(my $type = $data->{payload}{type}) {
                if($type eq 'event_callback') {
                    my $ev = Net::Async::Slack::EventType->from_json(
                        $data->{payload}{event}
                    );
                    $log->tracef("Have event [%s], emitting", $ev->type);
                    $self->events->emit($ev);
                } else {
                    if(my $ev = Net::Async::Slack::EventType->from_json(
                        $data->{payload}
                    )) {
                        $log->tracef("Have event [%s], emitting", $ev->type);
                        $self->events->emit($ev);
                    } else {
                        $log->errorf('Failed to locate event type from payload %s', $data->{payload});
                    }
                }
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
                on_expire => $self->$curry::weak(sub { shift->trigger_ping }),
            )
        );
        $timer
    }
}

=head2 handle_unfurl_domain

=cut

sub handle_unfurl_domain {
    my ($self, %args) = @_;
    $self->{unfurl_domain}{
        delete $args{domain} || die 'need a domain'
    } = $args{handler}
        or die 'need a handler';
    return;
}

sub event_mangler {
    my ($self) = @_;
    $self->{event_handling} //= $self->events->map($self->$curry::weak(async sub {
        my ($self, $ev) = @_;
        try {
            if(my $code = $self->can($ev->type)) {
                await $self->$code($ev);
            } else {
                $log->tracef('Ignoring event %s', $ev->type);
            }
        } catch ($e) {
            $log->errorf('Event handling on %s failed: %s', $ev, $e);
        }
    }))->ordered_futures(
        low => 16,
        high => 100,
    );
}

async sub link_shared {
    my ($self, $ev) = @_;
    my %uri_map;
    for my $link ($ev->{links}->@*) {
        if(my $handler = $self->{unfurl_domain}{$link->{domain}}) {
            my $uri = URI->new($link->{url});
            $log->tracef('Unfurling URL %s', $uri);
            my $unfurled = await $handler->($uri);
            $uri_map{$uri} = $unfurled if $unfurled;
        }
    }
    return unless keys %uri_map;
    my $res = await $self->slack->chat_unfurl(
        channel => $ev->{channel_id} // $ev->{channel}->id,
        ts      => $ev->{message_ts},
        unfurls => \%uri_map,
    );
    die 'invalid URI unfurling' unless $res->{ok};
    return;
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
    # $self->ping_timer->start;
    $self->{last_id} //= 0;
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.

