package Net::APNs::HTTP2;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.01";

use Moo;
use Crypt::JWT;
use JSON;
use Cache::Memory::Simple;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Protocol::HTTP2::Client;

has [qw/auth_key key_id team_id bundle_id is_development/] => (
    is => 'rw',
);

has apns_port => (
    is      => 'rw',
    default => 443, # can use 2197
);

has on_error => (
    is      => 'rw',
    default => sub {
        sub {};
    },
);

sub _host {
    my $self = shift;
    $self->is_development ? 'api.development.push.apple.com' : 'api.push.apple.com';
}

sub _client {
    my $self = shift;
    $self->{_client} ||= Protocol::HTTP2::Client->new(keepalive => 1);
}

sub _handle {
    my $self = shift;

    unless ($self->_handle_connected) {
        my $handle = AnyEvent::Handle->new(
            keepalive => 1,
            connect   => [ $self->_host, $self->apns_port ],
            tls       => 'connect',
            tls_ctx   => {
                verify          => 1,
                verify_peername => 'https',
            },
            autocork => 1,
            on_error => sub {
                my ($handle, $fatal, $message) = @_;
                $self->on_error->($fatal, $message);
                $handle->destroy;
                $self->{_condvar}->send;
            },
            on_eof => sub {
                my $handle = shift;
                $self->{_condvar}->send;
            },
            on_read => sub {
                my $handle = shift;
                $self->_client->feed(delete $handle->{rbuf});
                while (my $frame = $self->_client->next_frame) {
                    $handle->push_write($frame);
                }
                if ($self->_client->shutdown) {
                    $handle->push_shutdown;
                    return;
                }

                unless ($self->_client->{active_streams} > 0) {
                    $self->{_condvar}->send;
                    return;
                }
            },
        );

        $self->{_handle} = $handle;
    }

    return $self->{_handle};
}

sub _handle_connected {
    my $self = shift;

    my $handle = $self->{_handle};
    return if !$handle;
    return if $handle->destroyed;
    return 1;
}

sub _provider_authentication_token {
    my $self = shift;

    $self->{_cache} ||= Cache::Memory::Simple->new;
    $self->{_cache}->get_or_set('provider_authentication_token', sub {
        my $craims = {
            iss => $self->team_id,
            iat => time,
        };
        my $jwt = Crypt::JWT::encode_jwt(
            payload       => $craims,
            key           => [ $self->auth_key ],
            alg           => 'ES256',
            extra_headers => { kid => $self->key_id },
        );
        return $jwt;
    }, 60 * 50);
}

sub prepare {
    my ($self, $device_token, $payload, $cb, $extra_header) = @_;
    my $apns_expiration  = $extra_header->{apns_expiration} || 0;
    my $apns_priority    = $extra_header->{apns_priority}   || 10;
    my $apns_topic       = $extra_header->{apns_topic}      || $self->bundle_id;
    my $apns_id          = $extra_header->{apns_id};
    my $apns_collapse_id = $extra_header->{apns_collapse_id};

    my $clinet = $self->_client;
    $clinet->request(
        ':scheme'    => 'https',
        ':authority' => join(':', $self->_host, $self->apns_port),
        ':path'      => sprintf('/3/device/%s', $device_token),
        ':method'    => 'POST',
        headers      => [
            'authorization'   => sprintf('bearer %s', $self->_provider_authentication_token),
            'apns-expiration' => $apns_expiration,
            'apns-priority'   => $apns_priority,
            'apns-topic'      => $apns_topic,
            defined $apns_id          ? ('apns-id'          => $apns_id)          : (),
            defined $apns_collapse_id ? ('apns-collapse-id' => $apns_collapse_id) : (),
        ],
        data    => JSON::encode_json($payload),
        on_done => $cb,
    );

    return $self;
}

sub send {
    my $self = shift;

    local $self->{_condvar} = AnyEvent->condvar;

    my $handle = $self->_handle;
    my $clinet = $self->_client;
    while (my $frame = $clinet->next_frame) {
        $handle->push_write($frame);
    }

    $self->{_condvar}->recv;

    return 1;
}

sub close {
    my $self = shift;
    if ($self->{_client} && !$self->{_client}->shutdown) {
        $self->{_client}->close;
    }
    if ($self->{_handle} && !$self->{_handle}->destroyed) {
        $self->{_handle}->destroy;
    }
    delete $self->{_cache};
    delete $self->{_handle};
    delete $self->{_client};

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::APNs::HTTP2 - APNs Provider API for Perl

=head1 SYNOPSIS

    use Net::APNs::HTTP2;

    my $apns = Net::APNs::HTTP2->new(
        is_development => 1,
        auth_key       => 'auth_key.p8',
        key_id         => $key_id,
        team_id        => $team_id,
        bundle_id      => $bundle_id,
    );

    while (1) {
        $apns->prepare($device_token, {
            aps => {
                alert => 'some message',
                badge => 1,
            },
        }, sub {
            my ($header, $content) = @_;
            # $header = [
            #     ":status" => "200",
            #     "apns-id" => "82B34E17-370A-DBF4-5046-FF56A4EA1FAF",
            # ];
            ...
        });

        # You can chainged
        $apns->prepare(...)->prepare(...)->prepare(...);

        # send all prepared requests in parallel
        $apns->send;

        # do something
    }

    # must call `close` when finished
    $apns->close;

=head1 DESCRIPTION

Net::APNs::HTTP2 is APNs Provider API for Perl.

=head1 METHODS

=head2 new(%args)

Create a new instance of C<< Net::APNs::HTTP2 >>.

Supported arguments are:

=over

=item auth_key : File Path

Universal Push Notification Client SSL Certificate.
But, can not use this auth key as it is.
Please convert key as follows:

  openssl pkcs8 -in AuthKey_XXXXXXXXXX.p8 -inform PEM -out auth_key.p8 -outform PEM -nocrypt

=item key_id : Str

A 10-character key identifier (kid) key, obtained from your developer account.

=item team_id : Str

The issuer (iss) registered claim key, whose value is your 10-character Team ID, obtained from your developer account.

=item bundle_id : Str

Your Application bundle identifier.

=item is_development : Bool

Development server: api.development.push.apple.com:443
Production server: api.push.apple.com:443

=back

=head2 $apns->prepare($device_token, $payload, $callback [, $extra_headers ])

Create a request.

  $apns->prepare($device_token, {
      aps => {
         alert => {
            title => 'test message',
            body  => 'from Net::APNs::HTTP2',
         },
         badge => 1,
      },
  }, sub {
      my ($header, $content) = @_;
      # $header = [
      #     ":status" => "200",
      #     "apns-id" => "82B34E17-370A-DBF4-5046-FF56A4EA1FAF",
      # ];
      ...
  });

You can chainged call

  $apns->prepare(...)->prepare(...)->prepare(...)->send();

=head2 $apns->send()

Send notification.

=head2 $apns->close()

Close connections.

=head1 LICENSE

Copyright (C) xaicron.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

xaicron E<lt>xaicron@gmail.comE<gt>

=cut

