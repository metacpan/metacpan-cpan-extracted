package Net::NATS2::Client;

our $VERSION = '0.3.4';

use IO::Select;
use Time::HiRes qw(time sleep);
use Encode      qw(encode_utf8);
use MIME::Base64 qw(encode_base64);

use v5.10;
use strict;
use warnings;

use constant CRLF => "\r\n";
use constant _0E0 => '0E0';

use Net::NATS2::URI;
use JSON;

use Net::NATS2::Connection;
use Net::NATS2::Message;
use Net::NATS2::ServerInfo;
use Net::NATS2::ConnectInfo;
use Net::NATS2::Subscription;
use Net::NATS2::Base qw(-no_new);

has $_ for qw(connection server_info socket_args auto_reconnect reconnect_attempts reconnect_delay subscriptions uri current_sid message_count nkey nkey_sig_cb);

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;
    $self->socket_args({}) unless defined $self->socket_args;
    $self->subscriptions({});
    $self->current_sid(0);
    $self->message_count(0);
    $self->reconnect_attempts(3) unless defined $self->reconnect_attempts;
    $self->reconnect_delay(1)    unless defined $self->reconnect_delay;

    return $self;
}

sub connect {
    my $self = shift;

    my $uri = Net::NATS2::URI->new($self->uri) || return;

    $self->socket_args->{PeerAddr} = $uri->host;
    $self->socket_args->{PeerPort} = $uri->port;

    my $connection = Net::NATS2::Connection->new(socket_args => $self->socket_args) || return;
    $self->connection($connection);

    # Get INFO line
    my ($op, @args) = $self->read_line;
    my $info = Net::NATS2::ServerInfo->new(%{decode_json($args[0])});
    $self->server_info($info);

    my $connect_info = $self->_connect_info($info, $uri);

    if ($info->ssl_required || $info->tls_required) {
        $connection->upgrade() || return;
        $self->connection($connection);
    }

    my $connect = 'CONNECT ' . to_json($connect_info, {convert_blessed => 1});
    $self->connection->send($connect);

    return 1;
}

sub _connect_info {
    my ($self, $info, $uri) = @_;

    my $connect_info = Net::NATS2::ConnectInfo->new(
        lang         => 'perl',
        version      => $VERSION,
        headers      => 1,
        tls_required => $info->ssl_required || $info->tls_required,
    );

    if ($info->auth_required && !defined $self->nkey) {
        if (!defined $uri->password) {
            $connect_info->auth_token($uri->user);
        }
        else {
            $connect_info->user($uri->user);
            $connect_info->pass($uri->password);
        }
    }

    if (defined $self->nkey) {
        die 'NKey authentication requires a server nonce' unless defined $info->nonce;
        die 'NKey authentication requires nkey_sig_cb' unless ref $self->nkey_sig_cb eq 'CODE';

        my $signature = $self->nkey_sig_cb->($info->nonce);
        die 'NKey signature callback returned undef' unless defined $signature;

        $connect_info->nkey($self->nkey);
        $connect_info->sig(_base64url($signature));
    }

    return $connect_info;
}

sub _base64url {
    my ($value) = @_;
    $value = encode_base64($value, '');
    $value =~ tr!+/!-_!;
    $value =~ s/=+\z//;
    return $value;
}

sub subscribe {
    my $self = shift;

    my ($subject, $group, $callback);

    if (@_ == 2) {
        ($subject, $callback) = @_;
    }
    else {
        ($subject, $group, $callback) = @_;
    }

    my $sid = $self->next_sid;
    $group = (defined $group) ? " $group" : '';

    $self->connection->send("SUB $subject$group $sid");

    my $subscription = Net::NATS2::Subscription->new(
        subject  => $subject,
        group    => $group,
        sid      => $sid,
        callback => $callback,
        client   => $self,
    );

    $self->subscriptions->{$sid} = $subscription;
    return $subscription;
}

sub unsubscribe {
    my $self = shift;
    my ($subscription, $max_msgs) = @_;

    $subscription->max_msgs($max_msgs);

    my $sid = $subscription->sid;
    $sid .= " $max_msgs" if defined $max_msgs;

    $self->connection->send("UNSUB $sid");

    $self->_remove_subscription($subscription) unless defined $max_msgs;
}

# 0:$self 1:$subject 2:$data 3:$reply_to
# Returns 1 on success, undef on failure
sub publish {
    my $reply_to = defined $_[3] ? "$_[3] " : '';
    return $_[0]->connection->send("PUB $_[1] $reply_to" . _wire_length($_[2]) . CRLF . $_[2]);
}

# Publish a message with a raw NATS header block.
#
# $headers must include the NATS header version and its terminating empty line,
# for example: "NATS/1.0\r\nX-Request-ID: 42\r\n\r\n".
# Returns 1 on success, undef on failure.
sub hpublish {
    my ($self, $subject, $headers, $data, $reply_to) = @_;
    return if defined $self->server_info && !$self->server_info->headers;

    my $header_length = _wire_length($headers);
    my $total_length  = $header_length + _wire_length($data);
    my $reply         = defined $reply_to ? "$reply_to " : '';

    return $self->connection->send("HPUB $subject $reply$header_length $total_length" . CRLF . $headers . $data);
}

sub _wire_length {
    my $data = shift;
    return utf8::is_utf8($data) ? length(encode_utf8($data)) : length($data);
}

sub publish_with_headers {
    goto &hpublish;
}

sub request {
    my ($self, $subject, $data, $callback) = @_;

    my $inbox = new_inbox();
    my $sub   = $self->subscribe($inbox, $callback);
    $self->unsubscribe($sub, 1);
    $self->publish($subject, $data, $inbox);
}

# Sends a request and waits for one response. Returns a Message on success or
# undef if the publish fails, the connection closes, or the timeout expires.
sub request_sync {
    my ($self, $subject, $data, $timeout) = @_;
    $timeout = 1 unless defined $timeout;

    my $response;
    my $inbox        = new_inbox();
    my $subscription = $self->subscribe($inbox, sub { ($response) = @_ });
    $self->unsubscribe($subscription, 1);
    return unless $self->publish($subject, $data, $inbox);

    my $deadline = time + $timeout;
    while (!defined $response) {
        my $remaining = $deadline - time;
        last if $remaining <= 0;
        last unless $self->wait_for_op($remaining);
    }

    $self->unsubscribe($subscription) unless defined $response;
    return $response;
}

sub _reconnect {
    my $self = shift;
    return unless defined $self->auto_reconnect;

    my $attempt = 0;
    while ($self->auto_reconnect == 0 || $attempt < $self->reconnect_attempts) {
        ++$attempt;
        if ($self->connect) {
            for my $subscription (values %{$self->subscriptions}) {
                my $sid = $subscription->sid;
                $self->connection->send("SUB " . $subscription->subject . $subscription->group . " $sid");
            }
            return 1;
        }
        sleep($self->reconnect_delay) if $self->auto_reconnect == 0 || $attempt < $self->reconnect_attempts;
    }
    return;
}

sub _remove_subscription {
    delete $_[0]->subscriptions->{$_[1]->sid};
}

# blocking read built upon non-blocking read
sub read {
    my ($self, $length) = @_;

    my $data;
    my $rv = $self->connection->nb_read($data, $length) || return;    # EOF or error
    if ($rv eq _0E0) {
        while ($rv eq _0E0 && $self->connection->can_read()) {        # keep tryingi until we get the data we need.
                                                                      # EOF or error. should report error somewhere...
            $rv = $self->connection->nb_read($data, $length) || return;
        }
        return if $rv eq _0E0;                                        # got timeout from can_read
    }
    return _chomp($data);
}

# non-blocking version of read_line. if no timeout passed, will block
sub read_line {
    my ($self, $timeout) = @_;
    my $line;

    my $rv = $self->connection->nb_getline($line) || return;    # EOF or error
    if ($rv eq _0E0) {                                          # we do not have a full line
        while ($rv eq _0E0 && $self->connection->can_read($timeout)) {

            # EOF or error. should report error somewhere...
            $rv = $self->connection->nb_getline($line) || return;
        }
        return if $rv eq _0E0;                                  # got timeout from can_read
    }
    return split(' ', _chomp($line));
}

sub parse_msg {
    my $self = shift;

    my ($subject, $sid, $length, $reply_to);

    if (@_ == 3) {
        ($subject, $sid, $length) = @_;
    }
    else {
        ($subject, $sid, $reply_to, $length) = @_;
    }

    my $data = $self->read($length + 2);
    return unless defined $data;
    my $subscription = $self->subscriptions->{$sid};
    my $message      = Net::NATS2::Message->new(
        subject      => $subject,
        sid          => $sid,
        reply_to     => $reply_to,
        length       => $length,
        data         => $data,
        subscription => $subscription,
    );

    $subscription->message_count($subscription->message_count + 1);
    $self->message_count($self->message_count + 1);

    if ($subscription->defined_max && $subscription->message_count >= $subscription->max_msgs) {
        $self->_remove_subscription($subscription);
    }

    &{$subscription->callback}($message);
    return 1;
}

sub parse_hmsg {
    my $self = shift;

    my ($subject, $sid, $header_length, $total_length, $reply_to);

    if (@_ == 4) {
        ($subject, $sid, $header_length, $total_length) = @_;
    }
    else {
        ($subject, $sid, $reply_to, $header_length, $total_length) = @_;
    }

    my $content = $self->read($total_length + 2);
    return unless defined $content;
    my $headers      = substr($content, 0,              $header_length);
    my $data         = substr($content, $header_length, $total_length - $header_length);
    my $subscription = $self->subscriptions->{$sid};
    my $message      = Net::NATS2::Message->new(
        subject       => $subject,
        sid           => $sid,
        reply_to      => $reply_to,
        header_length => $header_length,
        length        => $total_length - $header_length,
        headers       => $headers,
        data          => $data,
        subscription  => $subscription,
    );

    $subscription->message_count($subscription->message_count + 1);
    $self->message_count($self->message_count + 1);

    if ($subscription->defined_max && $subscription->message_count >= $subscription->max_msgs) {
        $self->_remove_subscription($subscription);
    }

    &{$subscription->callback}($message);
    return 1;
}

sub wait_for_op {
    my $self    = shift;
    my $timeout = shift;    # in seconds; can be fractional

    my ($op, @args) = $self->read_line($timeout);
    return $self->_reconnect unless defined $op;

    return $self->_handle_op($op, @args);
}

# Sends a client PING and waits for its PONG response.
# Returns 1 on success and 0 if the response is not received before timeout.
sub ping {
    my ($self, $timeout) = @_;
    $timeout = 1 unless defined $timeout;

    return 0 if $timeout < 0;
    return 0 unless $self->connection->send('PING');

    my $deadline = time + $timeout;
    while (1) {
        my $remaining = $deadline - time;
        return 0 if $remaining <= 0;

        my ($op, @args) = $self->read_line($remaining);
        return 0 unless defined $op;
        return 1 if $op eq 'PONG';

        return 0 unless $self->_handle_op($op, @args);
    }
}

sub _handle_op {
    my ($self, $op, @args) = @_;

    if ($op eq 'MSG') {
        return $self->parse_msg(@args) || $self->_reconnect;
    }
    elsif ($op eq 'HMSG') {
        return $self->parse_hmsg(@args) || $self->_reconnect;
    }
    elsif ($op eq 'PING') {
        $self->handle_ping;
    }
    elsif ($op eq 'PONG' || $op eq '+OK') {
    }
    elsif ($op eq '-ERR') {
        return;
    }
    return 1;
}

sub _chomp {
    my $data = shift;
    if ($data) {
        local $/ = CRLF;
        chomp($data);
    }
    return $data;
}

sub handle_ping {
    $_[0]->connection->send('PONG');
}

sub next_sid {
    my $self = shift;
    $self->current_sid($self->current_sid + 1);
    return $self->current_sid;
}

sub close {
    $_[0]->connection->_socket->close;
}

sub new_inbox {
    sprintf('_INBOX.%08X%08X%06X', rand(2**32), rand(2**32), rand(2**24));
}

1;

__END__

=head1 NAME

Net::NATS2::Client - A Perl client for the NATS messaging system. Based on Net::NATS::Client

=head1 SYNOPSIS

  #
  # Basic Usage
  #

  $client = Net::NATS2::Client->new(uri => 'nats://localhost:4222');
  $client->connect() or die $!;

  # Simple Publisher
  $client->publish('foo', 'Hello, World!');

  # Simple Async Subscriber
  $subscription = $client->subscribe('foo', sub {
      my ($message) = @_;
      printf("Received a message: %s\n", $message->data);
  });

  # Process one message from the server. Could be a PING message.
  # Must call at least one per ping-timout (default is 120s).
  $client->wait_for_op();

  # Process pending operations, with a timeout (in seconds).
  # A timeout of 0 is polling.
  $client->wait_for_op(3.14);

  # Check that the connection is still live. This waits up to one second
  # for the server's PONG response.
  die 'ERROR: Connection lost!' unless $client->ping(1);

  # Unsubscribe
  $subscription->unsubscribe();

  # Close connection
  $client->close();

  #
  # Headers
  #

  my $headers = "NATS/1.0\r\nX-Trace-ID: 42\r\n\r\n";
  $client->hpublish('foo', $headers, 'Hello, World!');

  # Received header messages retain the raw header block separately.
  $client->subscribe('foo', sub {
      my ($message) = @_;
      print $message->headers;
      print $message->data;
  });

  #
  # Request/Reply
  #

  # Setup reply
  $client->subscribe("foo", sub {
      my ($request) = @_;
      printf("Received request: %s\n", $request->data);
      $client->publish($request->reply_to, "Hello, Human!");
  });

  # Send request
  $client->request('foo', 'Hello, World!', sub {
      my ($reply) = @_;
      printf("Received reply: %s\n", $reply->data);
  });

  # Wait synchronously for one reply, as used by JetStream APIs.
  my $reply = $client->request_sync('foo', 'Hello, World!', 1);

  # Enable reconnect attempts and subscription restoration.
  my $client = Net::NATS2::Client->new(
      uri                => 'nats://localhost:4222',
      auto_reconnect     => 1,
      reconnect_attempts => 3,
      reconnect_delay    => 1,
  );

  # Use JetStream through the connected core client.
  use Net::NATS2::JetStream;
  my $js = Net::NATS2::JetStream->new(client => $client, timeout => 1);


  #
  # TLS
  #

  # Set the socket arguments that will be passed to IO::Socket::SSL
  my $socket_args = {
    SSL_cert_file => $cert_file,
    SSL_key_file  => $key_file,
  };

  my $client = Net::NATS2::Client->new(uri => 'nats://localhost:4222', socket_args => $socket_args);
  $client->connect() or die $!;

  # Change the default 1024-byte socket read chunk size.
  my $client = Net::NATS2::Client->new(
      uri => 'nats://localhost:4222',
      socket_args => { BufferSize => 4096 },
  );

=head1 HEADERS

C<hpublish($subject, $headers, $data, $reply_to)> sends an C<HPUB> command.
C<publish_with_headers> is an alias. C<$headers> must be a complete NATS header
block: the C<NATS/1.0> version line, zero or more header lines, and the final
C<\r\n\r\n> delimiter. C<$reply_to> is optional.

The client advertises header support in C<CONNECT> and returns undef from
C<hpublish> without writing to the socket if the server's C<INFO> reports that
headers are unavailable. Received C<HMSG> messages provide the complete raw
header block through C<< $message->headers >>, its byte count through
C<< $message->header_length >>, and the payload through C<< $message->data >>.

=head1 ENCODING

Protocol lengths are measured in bytes. UTF-8-flagged outbound strings are
encoded as UTF-8 before being written; byte strings are sent unchanged. This
applies to C<PUB> and C<HPUB> payloads as well as protocol control lines.

=head1 NKEY AUTHENTICATION

Set C<nkey> to the user NKey public key and C<nkey_sig_cb> to a coderef that
accepts the server nonce and returns raw Ed25519 signature bytes. The client
base64url-encodes the signature and includes both fields in C<CONNECT>. The
application is responsible for securely loading and using the NKey seed or
private key.

For example, C<Crypt::PK::Ed25519> can load an application-managed private
key and sign the nonce:

  use Crypt::PK::Ed25519;

  my $signer = Crypt::PK::Ed25519->new('/secure/path/user-ed25519.pem');
  # The NATS-encoded public NKey matching the private key above.
  my $nkey = $ENV{NATS_USER_NKEY};
  my $client = Net::NATS2::Client->new(
      uri         => 'nats://localhost:4222',
      nkey        => $nkey,
      nkey_sig_cb => sub { $signer->sign_message($_[0]) },
  );

=head1 RECONNECTION

Automatic reconnect is disabled by default. Set C<auto_reconnect> to a
positive value and optionally configure C<reconnect_attempts> (default 3) and
C<reconnect_delay> (default 1 second). Set C<auto_reconnect> to C<0> for
unlimited attempts; omit it entirely to disable reconnection. When a read-side
disconnect is detected, the client reconnects to its configured URI and
re-establishes each existing subscription with its original subscription ID.

The client does not retry a failed publish automatically: a failed write may
have reached the server, and retrying could duplicate delivery.

=head1 JETSTREAM

L<Net::NATS2::JetStream> uses a connected core client to provide account
information, stream management, synchronous publish acknowledgements, and pull
consumer support. See that module's documentation for its API.

=head1 READ BUFFER SIZE

The client reads socket data in 1024-byte chunks by default. Pass C<BufferSize>
in C<socket_args> to use a different chunk size:

  my $client = Net::NATS2::Client->new(
      uri => 'nats://localhost:4222',
      socket_args => { BufferSize => 4096 },
  );

=head1 UPSTREAM

L<https://github.com/dshadow/perl-nats2>
L<https://github.com/carwynmoore/perl-nats>

=head1 AUTHOR

Carwyn Moore

Vick Khera, <vivek at khera.org>,

Kostiantyn Cherednichenko, <dshadowukraine at gmail.com>

=head1 COPYRIGHT AND LICENSE

MIT License.  See F<LICENSE> for the complete licensing terms.

Copyright (c) 2016 Carwyn Moore, 2026 Kostiantyn Cherednichenko
