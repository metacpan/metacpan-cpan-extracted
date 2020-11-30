package Net::Async::Slack;
# ABSTRACT: Slack realtime messaging API support for IO::Async

use strict;
use warnings;

our $VERSION = '0.005';

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::Slack - support for the L<https://slack.com> APIs with L<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Slack;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $gh = Net::Async::Slack->new(
   token => '...',
  )
 );

=head1 DESCRIPTION

This is a basic wrapper for Slack's API. It's an early version, the module API is likely
to change somewhat over time.

See the C<< examples/ >> directory for usage.

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
use File::ShareDir ();
use Path::Tiny ();

use Cache::LRU;

use Ryu::Async;
use Ryu::Observable;
use Net::Async::WebSocket::Client;

use Log::Any qw($log);

use Net::Async::OAuth::Client;

use Net::Async::Slack::RTM;
use Net::Async::Slack::Message;

my $json = JSON::MaybeXS->new;

=head1 METHODS

=cut

=head2 rtm

Establishes a connection to the Slack RTM websocket API, and
resolves to a L<Net::Async::Slack::RTM> instance.

=cut

sub rtm {
    my ($self, %args) = @_;
    $log->tracef('Endpoint is %s', $self->endpoint(
        'rtm_connect',
        token => $self->token
    ));
    $self->{rtm} //= $self->http_get(
        uri => URI->new(
            $self->endpoint(
                'rtm_connect',
                token => $self->token
            )
        )
    )->then(sub {
        my $result = shift;
        return Future->done(URI->new($result->{url})) if exists $result->{url};
        return Future->fail('invalid URL');
    })->then(sub {
        my ($uri) = @_;
        $self->add_child(
            my $rtm = Net::Async::Slack::RTM->new(
                slack => $self,
                wss_uri => $uri,
            )
        );
        $rtm->connect->transform(done => sub { $rtm })
    })
}

=head2 send_message

Send a message to a user or channel.

Supports the following named parameters:

=over 4

=item * channel - who to send the message to, can be a channel ID or C<< #channel >> name, or user ID

=item * text - the message, see L<https://api.slack.com/docs/message-formatting> for details

=item * attachments - more advanced messages, see L<https://api.slack.com/docs/message-attachments>

=item * parse - whether to parse content and convert things like links

=back

and the following named boolean parameters:

=over 4

=item * link_names - convert C<< @user >> and C<< #channel >> to links

=item * unfurl_links - show preview for URLs

=item * unfurl_media - show preview for things that look like media links

=item * as_user - send as user

=item * reply_broadcast - send to all users when replying to a thread

=back

Returns a L<Future>, although the content of the response is subject to change.

=cut

sub send_message {
    my ($self, %args) = @_;
    die 'You need to pass either text or attachments' unless $args{text} || $args{attachments};
    my @content;
    push @content, token => $self->token;
    push @content, channel => $args{channel} || die 'need a channel';
    push @content, text => $args{text} if defined $args{text};
    push @content, attachments => $json->encode($args{attachments}) if $args{attachments};
    push @content, blocks => $json->encode($args{blocks}) if $args{blocks};
    push @content, $_ => $args{$_} for grep exists $args{$_}, qw(parse link_names unfurl_links unfurl_media as_user reply_broadcast thread_ts);
    $self->http_post(
        $self->endpoint(
            'chat.postMessage',
        ),
        \@content,
    )->then(sub {
        my ($data) = @_;
        return Future->fail('send failed', slack => $data) unless $data->{ok};
        Future->done(
            Net::Async::Slack::Message->new(
                slack => $self,
                channel => $data->{channel},
                thread_ts => $data->{ts},
            )
        )
    })
}

=head2 conversations_info

Provide information about a channel.

Takes the following named parameters:

=over 4

=item * C<channel> - the channel ID to look up

=back

and returns a L<Future> which will resolve to a hashref containing
C<< { channel => { name => '...' } } >>.

=cut

sub conversations_info {
    my ($self, %args) = @_;
    my @content;
    push @content, token => $self->token;
    push @content, channel => $args{channel} || die 'need a channel';
    return $self->http_post(
        $self->endpoint(
            'conversations.info',
        ),
        \@content,
    )
}

=head2 join_channel

Attempt to join the given channel.

Takes the following named parameters:

=over 4

=item * C<channel> - the channel ID or name to join

=back

=cut

sub join_channel {
    my ($self, %args) = @_;
    die 'You need to pass a channel name' unless $args{channel};
    my @content;
    push @content, token => $self->token;
    push @content, name => $args{channel};
    $self->http_post(
        $self->endpoint(
            'channels.join',
        ),
        \@content,
    )
}

=head1 METHODS - Internal

=head2 endpoints

Returns the hashref of API endpoints, loading them on first call from the C<share/endpoints.json> file.

=cut

sub endpoints {
    my ($self) = @_;
    $self->{endpoints} ||= do {
        my $path = Path::Tiny::path(__DIR__)->parent(3)->child('share/endpoints.json');
        $path = Path::Tiny::path(
            File::ShareDir::dist_file(
                'Net-Async-Slack',
                'endpoints.json'
            )
        ) unless $path->exists;
        $json->decode($path->slurp_utf8)
    };
}

sub slack_host { shift->{slack_host} }

=head2 endpoint

Processes the given endpoint as a template, using the named parameters
passed to the method.

=cut

sub endpoint {
    my ($self, $endpoint, %args) = @_;
    my $uri = URI::Template->new($self->endpoints->{$endpoint . '_url'})->process(%args);
    $uri->host($self->slack_host) if $self->slack_host;
    $uri
}

sub oauth {
    my ($self) = @_;
    $self->{oauth} //= Net::Async::OAuth::Client->new(
        realm           => 'Slack',
        consumer_key    => $self->key,
        consumer_secret => $self->secret,
        token           => $self->token,
        token_secret    => $self->token_secret,
    )
}

sub client_id { shift->{client_id} }

=head2 oauth_request

=cut

sub oauth_request {
    use Bytes::Random::Secure qw(random_string_from);
    use namespace::clean qw(random_string_from);
    my ($self, $code, %args) = @_;

    my $state = random_string_from('abcdefghjklmnpqrstvwxyz0123456789', 32);

    my $uri = $self->endpoint(
        'oauth',
        client_id => $self->client_id,
        scope     => 'bot,channels:write',
        state     => $state,
        %args,
    );
    $log->debugf("OAuth URI endpoint is %s", "$uri");
    $code->($uri)->then(sub {
            Future->done;
    })
}

=head2 token

API token.

=cut

sub token { shift->{token} }

=head2 http

Returns the HTTP instance used for communicating with the API.

Currently autocreates a L<Net::Async::HTTP> instance.

=cut

sub http {
    my ($self) = @_;
    $self->{http} ||= do {
        require Net::Async::HTTP;
        $self->add_child(
            my $ua = Net::Async::HTTP->new(
                fail_on_error            => 1,
                close_after_request      => 1,
                max_connections_per_host => 2,
                pipeline                 => 0,
                max_in_flight            => 8,
                decode_content           => 1,
                timeout                  => 30,
                user_agent               => 'Mozilla/4.0 (perl; https://metacpan.org/pod/Net::Async::Slack; TEAM@cpan.org)',
            )
        );
        $ua
    }
}

=head2 http_get

Issues an HTTP GET request.

=cut

sub http_get {
    my ($self, %args) = @_;

    my $uri = delete $args{uri};
    $log->tracef("GET %s { %s }", "$uri", \%args);
    $self->http->GET(
        $uri,
        %args
    )->then(sub {
        my ($resp) = @_;
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        try {
            $log->tracef('HTTP response for %s was %s', "$uri", $resp->as_string("\n"));
            return Future->done($json->decode($resp->decoded_content))
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

=head2 http_post

Issues an HTTP POST request.

=cut

sub http_post {
    my ($self, $uri, $content, %args) = @_;

    $log->tracef("POST %s { %s } <= %s", "$uri", \%args, $content);

    $self->http->POST(
        $uri,
        $content,
    )->then(sub {
        my ($resp) = @_;
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        try {
            $log->tracef('HTTP response for %s was %s', "$uri", $resp->as_string("\n"));
            return Future->done($json->decode($resp->decoded_content))
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(client_id token slack_host)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

1;

=head1 SEE ALSO

=over 4

=item * L<AnyEvent::SlackRTM> - low-level API wrapper around RTM

=item * L<Mojo::SlackRTM> - another RTM-specific wrapper, this time based on Mojolicious

=item * L<Slack::RTM::Bot> - more RTM support, this time via LWP and a subprocess/thread for handling the websocket part

=item * L<WebService::Slack::WebApi> - Furl-based wrapper around the REST API

=item * L<AnyEvent::SlackBot> - another AnyEvent RTM implementation

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.

