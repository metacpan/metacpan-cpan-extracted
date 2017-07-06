package Mojo::SlackRTM;
use Mojo::Base 'Mojo::EventEmitter';

use IO::Socket::SSL;
use Mojo::IOLoop;
use Mojo::JSON ();
use Mojo::Log;
use Mojo::UserAgent;
use Scalar::Util ();

use constant DEBUG => $ENV{MOJO_SLACKRTM_DEBUG};

our $VERSION = '0.04';

has ioloop => sub { Mojo::IOLoop->singleton };
has ua => sub { Mojo::UserAgent->new };
has log => sub { Mojo::Log->new };
has "token";
has "pinger";
has 'ws';
has 'auto_reconnect' => 1;

our $SLACK_URL = "https://slack.com/api";

sub _dump {
    shift;
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    my $dump = Data::Dumper::Dumper(@_);
    if (-t STDOUT) {
        warn "  \e[33m$_\e[m\n" for split /\n/, $dump;
    } else {
        warn "  $_\n" for split /\n/, $dump;
    }
}

my $TX_ERROR = sub {
    my $tx = shift;
    return if $tx->success and $tx->res->json("/ok");
    if ($tx->success) {
        my $error = $tx->res->json("/error") || "Unknown error";
        return $error;
    } else {
        my $error = $tx->error;
        return $error->{code} ? "$error->{code} $error->{message}" : $error->{message};
    }
};

sub metadata {
    my $self = shift;
    return $self->{_metadata} unless @_;
    my $metadata = shift;
    $self->{_metadata} = $metadata;
    unless ($metadata) {
        $self->{$_} = undef for qw(_users _channels);
        return;
    }
    $self->{_users}    = [
        +{ map { ($_->{id}, $_->{name}) } @{$metadata->{users}} },
        +{ map { ($_->{name}, $_->{id}) } @{$metadata->{users}} },
    ];
    $self->{_channels} = [
        +{ map { ($_->{id}, $_->{name}) } @{$metadata->{channels}} },
        +{ map { ($_->{name}, $_->{id}) } @{$metadata->{channels}} },
    ];
    $metadata;
}
sub next_id {
    my $self = shift;
    $self->{_id} //= 0;
    ++$self->{_id};
}

sub start {
    my $self = shift;
    $self->connect;
    $self->ioloop->start unless $self->ioloop->is_running;
}

sub connect {
    my $self = shift;
    my $token = $self->token or die "Missing token";
    my $tx = $self->ua->get("$SLACK_URL/rtm.start?token=$token");
    if (my $error = $TX_ERROR->($tx)) {
        $self->log->fatal("failed to get $SLACK_URL/rtm.start?token=XXX: $error");
        return;
    }
    my $metadata = $tx->res->json;
    $self->metadata($metadata);
    my $url = $metadata->{url};
    $self->ua->websocket($url => sub {
        my ($ua, $ws) = @_;
        unless ($ws->is_websocket) {
            $self->log->fatal("$url does not return websocket connection");
            return;
        }
        $self->ws($ws);
        $self->pinger( $self->ioloop->recurring(10 => sub { $self->ping }) );
        $self->ws->on(json => sub {
            my ($ws, $event) = @_;
            $self->_handle_event($event);
        });
        $self->ws->on(finish => sub {
            my ($ws) = @_;
            $self->log->warn("detect 'finish' event");
            $self->_clear;
            Mojo::IOLoop->timer(1 => sub { $self->connect }) if $self->auto_reconnect;
        });
    });
}

sub finish {
    my $self = shift;
    $self->ws->finish if $self->ws;
    $self->_clear;
}

sub reconnect {
    my $self = shift;
    $self->finish;
    $self->connect;
}

sub _clear {
    my $self = shift;
    if (my $pinger = $self->pinger) {
        $self->ioloop->remove($pinger);
        $self->pinger(undef);
    }
    $self->ws(undef);
    $self->metadata(undef);
    $self->{_id} = 0;
}

sub _handle_event {
    my ($self, $event) = @_;
    if (my $type = $event->{type}) {
        if ($type eq "message" and defined(my $reply_to = $event->{reply_to})) {
            DEBUG and $self->log->debug("===> skip 'message' event with reply_to $reply_to");
            DEBUG and $self->_dump($event);
            return;
        }
        DEBUG and $self->log->debug("===> emit '$type' event");
        DEBUG and $self->_dump($event);
        $self->emit($type, $event);
    } else {
        DEBUG and $self->log->debug("===> got event without 'type'");
        DEBUG and $self->_dump($event);
    }
}

sub ping {
    my $self = shift;
    my $hash = {id => $self->next_id, type => "ping"};
    DEBUG and $self->log->debug("===> emit 'ping' event");
    DEBUG and $self->_dump($hash);
    $self->ws->send({json => $hash});
}

sub find_channel_id {
    my ($self, $name) = @_;
    $self->{_channels}[1]{$name};
}
sub find_channel_name {
    my ($self, $id) = @_;
    $self->{_channels}[0]{$id};
}
sub find_user_id {
    my ($self, $name) = @_;
    $self->{_users}[1]{$name};
}
sub find_user_name {
    my ($self, $id) = @_;
    $self->{_users}[0]{$id};
}

sub send_message {
    my ($self, $channel, $text, %option) = @_;
    my $hash = {
        id => $self->next_id,
        type => "message",
        channel => $channel,
        text => $text,
        %option,
    };
    DEBUG and $self->log->debug("===> send message");
    DEBUG and $self->_dump($hash);
    $self->ws->send({json => $hash});
}

sub call_api {
    my ($self, $method) = (shift, shift);
    my ($param, $cb);
    if (@_ and ref $_[-1] eq "CODE") {
        $cb    = pop;
        $param = shift;
    } else {
        $param = shift;
    }
    $param ||= +{};
    $cb ||= sub {
        my ($slack, $tx) = @_;
        if (my $error = $TX_ERROR->($tx)) {
            $slack->log->warn("$method: $error");
        }
    };

    # Data structures like "attachments" need to be serialized to JSON
    for my $key (keys %$param) {
        if (ref $param->{$key} && !Scalar::Util::blessed($param->{$key})) {
            $param->{$key} = Mojo::JSON::to_json($param->{$key});
        }
    }

    $param->{token} = $self->token unless exists $param->{token};

    DEBUG and $self->log->debug("===> call api '$method'");
    DEBUG and $self->_dump($param);
    my $url = "$SLACK_URL/$method";
    $self->ua->post($url => form => $param => sub {
        (undef, my $tx) = @_;
        $cb->($self, $tx);
    });
}

1;
__END__

=for stopwords SlackRTM api websocket ioloop ws

=encoding utf-8

=head1 NAME

Mojo::SlackRTM - non-blocking SlackRTM client using Mojo::IOLoop

=head1 SYNOPSIS

  use Mojo::SlackRTM;

  # get from https://api.slack.com/web#authentication
  my $token = "xoxb-12345678901-AbCdEfGhIjKlMnoPqRsTuVWx";

  my $slack = Mojo::SlackRTM->new(token => $token);
  $slack->on(message => sub {
    my ($slack, $event) = @_;
    my $channel_id = $event->{channel};
    my $user_id    = $event->{user};
    my $user_name  = $slack->find_user_name($user_id);
    my $text       = $event->{text};
    $slack->send_message($channel_id => "hello $user_name!");
  });
  $slack->start;

=head1 DESCRIPTION

Mojo::SlackRTM is a non-blocking L<SlackRTM|https://api.slack.com/rtm> client using L<Mojo::IOLoop>.

This class inherits all events, methods, attributes from L<Mojo::EventEmitter>.

=head1 EVENTS

There are a lot of events, eg, B<hello>, B<message>, B<user_typing>, B<channel_marked>, ....

See L<https://api.slack.com/rtm> for details.

  $slack->on(reaction_added => sub {
    my ($slack, $event) = @_;
    my $reaction  = $event->{reaction};
    my $user_id   = $event->{user};
    my $user_name = $slack->find_user_name($user_id);
    $slack->log->info("$user_name reacted with $reaction");
  });

=head1 METHODS

=head2 call_api

  $slack->call_api($method);
  $slack->call_api($method, $param);
  $slack->call_api($method, $cb);
  $slack->call_api($method, $param, $cb);

Call slack web api. See L<https://api.slack.com/methods> for details.

  $slack->call_api("channels.list", {exclude_archived => 1}, sub {
    my ($slack, $tx) = @_;
    if ($tx->success and $tx->res->json("/ok")) {
      my $channels = $tx->res->json("/channels");
      $slack->log->info($_->{name}) for @$channels;
      return;
    }
    my $error = $tx->success ? $tx->res->json("/error") : $tx->error->{message};
    $slack->log->error($error);
  });

=head2 connect

  $slack->connect;

=head2 find_channel_id

  my $id = $slack->find_channel_id($name);

=head2 find_channel_name

  my $name = $slack->find_channel_name($id);

=head2 find_user_id

  my $id = $slack->find_user_id($name);

=head2 find_user_name

  my $name = $slack->find_user_name($id);

=head2 finish

  $slack->finish;

=head2 next_id

  my $id = $slack->next_id;

=head2 ping

  $slack->ping;

=head2 reconnect

  $slack->reconnect;

=head2 send_message

  $slack->send_message($channel => $text);

Send C<$text> to slack C<$channel> via the websocket transaction.

=head2 start

  $slack->start;

This is a convenient method. In fact it is equivalent to:

  $slack->connect;
  $slack->ioloop->start unless $slack->ioloop->is_running;

=head1 ATTRIBUTES

=head2 auto_reconnect

Automatically reconnect to slack

=head2 ioloop

L<Mojo::IOLoop> singleton

=head2 log

L<Mojo::Log> instance

=head2 metadata

The response of rtm.start. See L<https://api.slack.com/methods/rtm.start> for details.

=head2 token

slack access token

=head2 ua

L<Mojo::UserAgent> instance

=head2 ws

Websocket transaction

=head1 DEBUGGING

Set C<MOJO_SLACKRTM_DEBUG=1>.

=head1 SEE ALSO

L<AnyEvent::SlackRTM>

L<AnySan::Provider::Slack>

L<http://perladvent.org/2015/2015-12-23.html|http://perladvent.org/2015/2015-12-23.html>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
