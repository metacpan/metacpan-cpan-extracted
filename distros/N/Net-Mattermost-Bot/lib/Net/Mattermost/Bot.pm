package Net::Mattermost::Bot;

use 5.6.1;

use Carp qw(carp croak);
use Furl;
use HTTP::Status ':is';
use JSON::MaybeXS qw(encode_json decode_json);
use List::Util 'pairs';
use Mojo::IOLoop;
use Mojo::UserAgent;
use Moo;
use MooX::HandlesVia;
use Types::Standard qw(ArrayRef Bool HashRef Int Object Str);

our $VERSION = '0.04';

################################################################################

has base_url  => (is => 'ro', isa => Str, required => 1);
has team_name => (is => 'ro', isa => Str, required => 1);
has username  => (is => 'ro', isa => Str, required => 1);
has password  => (is => 'ro', isa => Str, required => 1);

has debug         => (is => 'ro', isa => Bool,    default => 0);
has ping_interval => (is => 'ro', isa => Int,     default => 15);
has ssl_opts      => (is => 'ro', isa => HashRef, default => sub { {} });
has token         => (is => 'rw', isa => Str,     default => '');
has user_id       => (is => 'rw', isa => Str,     default => '');

has api_url   => (is => 'ro', isa => Str,      lazy => 1, builder => '_build_api_url');
has endpoints => (is => 'ro', isa => HashRef,  lazy => 1, builder => '_build_endpoints');
has furl      => (is => 'ro', isa => Object,   lazy => 1, builder => '_build_furl');
has headers   => (is => 'rw', isa => ArrayRef, lazy => 1, builder => '_build_headers',
    handles_via => 'Array',
    handles     => { add_header => 'push' });
has ws_url    => (is => 'ro', isa => Str,      lazy => 1, builder => '_build_ws_url');

################################################################################

sub connect {
    my $self = shift;

    my $login_endpoint = sprintf('%s/users/login', $self->api_url);

    my $init = $self->furl->post($login_endpoint, $self->headers, encode_json({
        name     => $self->team_name,
        login_id => $self->username,
        password => $self->password,
    }));

    my $out = decode_json($init->{content});

    if ($out->{status_code} && !is_success($init->{status_code})) {
        croak $out->{message};
    }

    if ($init->header('Token')) {
        $self->token($init->header('Token'));
        $self->user_id($out->{id});
        $self->add_header(
            Cookie        => sprintf('MMAUTHTOKEN=%s', $self->token),
            Authorization => sprintf('Bearer %s', $self->token),
            'Keep-Alive'  => 1,
        );
    } else {
        croak 'Unauthorized';
    }

    $self->event_connected();
    $self->_start();

    return 1;
}

sub handle_message {
    my $self    = shift;
    my $content = shift;

    # Filter out empty responses and messages from ourself
    return unless $content && $content->{event};

    if ($content->{data}->{post}) {
        my $post_data = decode_json($content->{data}->{post});

        return if $post_data->{user_id} eq $self->user_id;
    }

    my $output;

    if ($content->{event} eq 'hello') {
        if ($self->debug) {
            carp sprintf('Sending auth token (token: %s) at %d', $self->token, time());
        }

        $output = {
            seq    => 1,
            action => 'authentication_challenge',
            data   => { token => $self->token },
        };
    } elsif ($content->{event} eq 'typing') {
        $output = $self->event_typing($content);
    } elsif ($content->{event} eq 'channel_viewed') {
        $output = $self->event_channel_viewed($content);
    } elsif ($content->{event} eq 'posted') {
        $output = $self->event_posted($content);
    } else {
        $output = $self->event_generic($content);
    }

    return $output;
}

# Override these
sub event_connected      {}
sub event_typing         {}
sub event_channel_viewed {}
sub event_posted         {}
sub event_generic        {}

################################################################################

sub _start {
    my $self = shift;

    my $ua = Mojo::UserAgent->new();
    my ($id, $ping_loop_id);

    $ua->on('start' => sub {
        my ($ua, $tx) = @_;

        carp 'Started' if $self->debug;

        $tx->req->headers->header($_->[0] => $_->[1]) foreach pairs @{$self->headers};
    });

    $id = $ua->websocket($self->ws_url => sub {
        my ($ua, $tx) = @_;

        my $last = 0;

        croak 'Websocket handshake failed' unless $tx->is_websocket;

        $ping_loop_id = Mojo::IOLoop->recurring($self->ping_interval => sub {
            my $loop = shift;

            carp 'Ping '.time() if $self->debug;

            $tx->send(encode_json({ seq => ++$last, action => 'ping' }));
        });

        $tx->on(finish => sub {
            my ($tx, $code, $reason) = @_;
            carp sprintf('Finished (%d: %s)', $code, $reason // 'Unknown');
            return Mojo::IOLoop->remove($ping_loop_id);
        });

        $tx->on(message => sub {
            my ($tx, $message) = @_;

            my $content = decode_json($message);
            my $ret     = $self->handle_message($content);

            $last = $content->{seq};

            $tx->send(encode_json($ret->{ws_send})) if $ret && ref $ret eq 'HASH' && $ret->{ws_send};
        });
    });

    Mojo::IOLoop->start() unless Mojo::IOLoop->is_running();
}

sub _format_mm_url {
    my $self = shift;
    my $end  = shift;

    return sprintf('%s/%s', $self->base_url, $end);
}

sub _post_to_channel {
    my $self = shift;
    my $args = shift;

    unless ($args->{channel_id}) {
        carp 'No channel_id provided - could not send to channel';
        return;
    }

    return $self->furl->post($self->endpoints->{channel_msg}, $self->headers, encode_json($args));
}

################################################################################

sub _build_endpoints {
    my $self = shift;

    my $base = $self->api_url;

    return {
        channel_msg => sprintf('%s/posts', $base),
    };
}

sub _build_furl {
    my $self = shift;

    return Furl->new(ssl_opts => $self->ssl_opts);
}

sub _build_headers {
    # Initial headers, added to at connection
    return [
        'Content-Type'     => 'application/json',
        'X-Requested-With' => 'XMLHttpRequest',
    ];
}

sub _build_api_url {
    my $self = shift;

    return $self->_format_mm_url('api/v4');
}

sub _build_ws_url {
    my $self = shift;

    my $url = $self->_format_mm_url('api/v4/websocket');

    $url =~ s/^http(?:s)?/wss/s;

    return $url;
}

################################################################################

1;
__END__

=head1 NAME

Net::Mattermost::Bot - A base class for Mattermost bots.

=head1 VERSION

0.04

=head1 SYNOPSIS

Extend C<Net::Mattermost::Bot> in a C<Moo> or C<Moose> package.

    my $bot = Local::MyBot->new({
        username  => 'username here',
        password  => 'password here',
        team_name => 'team name here',
        base_url  => 'Mattermost server\'s base URL here',

        debug => 1, # For extra WebSocket connection information
    });

    $bot->connect();

    package Local::MyBot;

    use Moo;

    extends 'Net::Mattermost::Bot';

    # A message was posted to the channel
    sub event_posted {
        my $self = shift;
        my $args = shift;

        # $args contains data from Mattermost

        return $self->_post_to_channel({
            channel_id => 1234,
            message    => 'This will be output to channel with ID "1234"',
        });
    }

    1;

API calls can also be made directly to Mattermost using their v4 API (using
Furl):

    sub event_posted {
        my $self = shift;

        # Get a list of your team's custom emoticons
        my $res = $self->furl->get($self->api_url.'/emoji', $self->headers);

        # ...
    }

=head1 DESCRIPTION

Provides a websocket connection and basic API controls for creating a simple
Mattermost bot.

=head2 METHODS

This package provides several methods which may be overridden in your own bot.

Each method takes two arguments (C<$self> and C<$event>), except
C<event_connected> which only passes C<$self>.

=over 4

=item C<event_connected()>

The bot connected to the server.

=item C<event_typing()>

Someone started typing.

=item C<event_channel_viewed()>

Someone viewed the channel.

=item C<event_posted()>

Someone posted to the channel.

=item C<event_generic()>

Generic catch-all for extra events.

=back

=head1 SEE ALSO

=over 4

=item L<https://mojolicious.org/perldoc/Mojo/IOLoop>

The websocket loop is provided by Mojo::IOLoop.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mike Jones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

