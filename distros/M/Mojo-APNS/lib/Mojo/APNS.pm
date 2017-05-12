package Mojo::APNS;
use feature 'state';
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::JSON 'encode_json';
use Mojo::IOLoop;
use constant FEEDBACK_RECONNECT_TIMEOUT => 5;
use constant DEBUG => $ENV{MOJO_APNS_DEBUG} ? 1 : 0;

our $VERSION = '1.00';

has key     => '';
has cert    => '';
has sandbox => 1;

has ioloop => sub { Mojo::IOLoop->singleton };
has _feedback_port   => 2196;
has _gateway_port    => 2195;
has _gateway_address => sub {
  $_[0]->sandbox ? 'gateway.sandbox.push.apple.com' : 'gateway.push.apple.com';
};

sub on {
  my ($self, $event, @args) = @_;

  if ($event eq 'feedback' and !$self->{feedback_id}) {
    $self->_connect(feedback => $self->_connected_to_feedback_deamon_cb);
  }

  $self->SUPER::on($event => @args);
}

sub _connected_to_feedback_deamon_cb {
  my $self = shift;
  my ($bytes, $ts, $device) = ('');

  sub {
    my ($self, $stream) = @_;
    Scalar::Util::weaken($self);
    $stream->timeout(0);
    $stream->on(
      close => sub {
        $stream->reactor->timer(
          FEEDBACK_RECONNECT_TIMEOUT,
          sub {
            $self or return;
            $self->_connect(feedback => $self->_connected_to_feedback_deamon_cb);
          }
        );
      }
    );
    $stream->on(
      read => sub {
        $bytes .= $_[1];
        ($ts, $device, $bytes) = unpack 'N n/a a*', $bytes;
        warn "[APNS:$device] >>> $ts\n" if DEBUG;
        $self->emit(feedback => {ts => $ts, device => $device});
      }
    );
  };
}

sub send {
  my $cb = ref $_[-1] eq 'CODE' ? pop : \&_default_handler;
  my ($self, $device_token, $message, %args) = @_;
  my $data = {};

  $data->{aps} = {alert => $message, badge => int(delete $args{badge} || 0)};

  if (defined(my $sound = delete $args{sound})) {
    $data->{aps}{sound} = $sound if length $sound;
  }

  if (defined(my $content_available = delete $args{content_available})) {
    $data->{aps}{'content-available'} = $content_available if length $content_available;
  }

  if (%args) {
    $data->{custom} = \%args;
  }

  $message = encode_json $data;

  if (length $message > 256) {
    my $length = length $message;
    return $self->$cb("Too long message ($length)");
  }

  $device_token =~ s/\s//g;
  warn "[APNS:$device_token] <<< $message\n" if DEBUG;

  $self->once(drain => sub { $self->$cb('') });
  $self->_write([chr(0), pack('n', 32), pack('H*', $device_token), pack('n', length $message), $message]);
}

sub _connect {
  my ($self, $type, $cb) = @_;
  my $port = $type eq 'gateway' ? $self->_gateway_port : $self->_feedback_port;

  if (DEBUG) {
    my $key = join ':', $self->_gateway_address, $port;
    warn "[APNS:$key] <<< cert=@{[$self->cert]}\n" if DEBUG;
    warn "[APNS:$key] <<< key=@{[$self->key]}\n"   if DEBUG;
  }

  Scalar::Util::weaken($self);
  $self->{"${type}_stream_id"} ||= $self->ioloop->client(
    address  => $self->_gateway_address,
    port     => $port,
    tls      => 1,
    tls_cert => $self->cert,
    tls_key  => $self->key,
    sub {
      my ($ioloop, $err, $stream) = @_;

      $err and return $self->emit(error => "$type: $err");
      $stream->on(close   => sub { delete $self->{"${type}_stream_id"} });
      $stream->on(error   => sub { $self->emit(error => "$type: $_[1]") });
      $stream->on(drain   => sub { $self->emit('drain'); });
      $stream->on(timeout => sub { delete $self->{"${type}_stream_id"} });
      $self->$cb($stream);
    },
  );
}

sub _default_handler {
  $_[0]->emit(error => $_[1]) if $_[1];
}

sub _write {
  my ($self, $message) = @_;
  my $id = $self->{gateway_stream_id};
  my $stream;

  unless ($id) {
    push @{$self->{messages}}, $message;
    $self->_connect(
      gateway => sub {
        my $self = shift;
        $self->_write($_) for @{delete($self->{messages}) || []};
      }
    );
    return $self;
  }
  unless ($stream = $self->ioloop->stream($id)) {
    push @{$self->{messages}}, $message;
    return $self;
  }

  $stream->write(join '', @$message);
  $self;
}

sub DESTROY {
  my $self = shift;
  my $ioloop = $self->ioloop or return;
  my $id;

  $ioloop->remove($id) if $id = $self->{gateway_id};
  $ioloop->remove($id) if $id = $self->{feedback_id};
}

1;

=encoding utf8

=head1 NAME

Mojo::APNS - Apple Push Notification Service for Mojolicious

=head1 VERSION

1.00

=head1 DESCRIPTION

This module provides an API for sending messages to an iPhone using Apple Push
Notification Service.

This module does not support password protected SSL keys.

NOTE! This module will segfault if you swap L</key> and L</cert> around.

=head1 SYNOPSIS

=head2 Script

  use Mojo::Base -strict;
  use Mojo::APNS;

  my $device_id = shift @ARGV;
  my $apns = Mojo::APNS->new(
    cert    => "/path/to/apns-dev-cert.pem",
    key     => "/path/to/apns-dev-key.pem",
    sandbox => 0,
  );

  # Emulate a blocking request with Mojo::IOLoop->start() and stop()
  $apns->send($device_id, "Hey there!", sub { shift->ioloop->stop })->ioloop->start;

=head2 Web application

  use Mojolicious::Lite;
  use Mojo::APNS;

  # set up a helper that holds the Mojo::APNS object
  helper apns => sub {
    state $apns
      = Mojo::APNS->new(
          cert    => "/path/to/apns-dev-cert.pem",
          key     => "/path/to/apns-dev-key.pem",
          sandbox => 0,
        );
  };

  # send a notification
  post "/notify" => sub {
    my $c         = shift;
    my $device_id = "c9d4a07c fbbc21d6 ef87a47d 53e16983 1096a5d5 faa15b75 56f59ddd a715dff4";

    $c->delay(
      sub {
        my ($delay) = @_;
        $c->apns->send($device_id, "hey there!", $delay->begin);
      },
      sub {
        my ($delay, $err) = @_;
        return $c->reply->exception($err) if $err;
        return $c->render(text => "Message was sent!");
      }
    );
  };

  # listen for feedback events
  app->apns->on(
    feedback => sub {
      my ($apns, $feedback) = @_;
      warn "$feedback->{device} rejected push at $feedback->{ts}";
    }
  );

  app->start;

=head1 EVENTS

=head2 error

  $self->on(error => sub { my ($self, $err) = @_; });

Emitted when an error occurs between client and server.

=head2 drain

  $self->on(drain => sub { my ($self) = @_; });

Emitted once all messages have been sent to the server.

=head2 feedback

  $self->on(feedback => sub { my ($self, $data) = @_; });

This event is emitted once a device has rejected a notification. C<$data> is a
hash-ref:

  {
    ts     => $rejected_epoch_timestamp,
    device => $device_token,
  }

Once you start listening to "feedback" events, a connection will be made to
Apple's push notification server which will then send data to this callback.

=head1 ATTRIBUTES

=head2 cert

  $self = $self->cert("/path/to/apns-dev-cert.pem");
  $path = $self->cert;

Path to apple SSL certificate.

=head2 key

  $self = $self->key("/path/to/apns-dev-key.pem");
  $path = $self->key;

Path to apple SSL key.

=head2 sandbox

  $self = $self->sandbox(0);
  $bool = $self->sandbox;

Boolean true for talking with "gateway.sandbox.push.apple.com" instead of
"gateway.push.apple.com". Default is true.

=head2 ioloop

  $self = $self->ioloop(Mojo::IOLoop->new);
  $ioloop = $self->ioloop;

Holds a L<Mojo::IOLoop> object.

=head1 METHODS

=head2 on

Same as L<Mojo::EventEmitter/on>, but will also set up feedback connection if
the event is L</feedback>.

=head2 send

  $self->send($device, $message, %args);
  $self->send($device, $message, %args, sub { my ($self, $err) = @_; });

Will send a C<$message> to the C<$device>. C<%args> is optional, but can contain:

C<$cb> will be called when the messsage has been sent or if it could not be
sent. C<$err> will be false on success.

=over 4

=item * badge

The number placed on the app icon. Default is 0.

=item * sound

Default is "default".

=item * Custom arguments

=back

=head1 AUTHOR

Glen Hinkle - C<tempire@cpan.org>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
