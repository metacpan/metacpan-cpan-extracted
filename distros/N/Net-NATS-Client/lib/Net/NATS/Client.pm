package Net::NATS::Client;

our $VERSION = '0.2.1';

use IO::Select;

use Class::XSAccessor {
    constructors => [ '_new' ],
    accessors => [
        'connection',
        'socket_args',
        'subscriptions',
        'uri',
    ],
    lvalue_accessors => [
        'current_sid',
        'message_count',
    ],
};

use strict;
use warnings;

use URI;
use JSON;

use Net::NATS::Connection;
use Net::NATS::Message;
use Net::NATS::ServerInfo;
use Net::NATS::ConnectInfo;
use Net::NATS::Subscription;

sub new {
    my $class = shift;

    my $self = $class->_new(@_);
    $self->socket_args({}) unless defined $self->socket_args;
    $self->subscriptions({});
    $self->current_sid = 0;
    $self->message_count = 0;

    return $self;
}

sub connect {
    my $self = shift;

    my $uri = URI->new($self->uri)
        or return;

    $self->socket_args->{PeerAddr} = $uri->host;
    $self->socket_args->{PeerPort} = $uri->port;

    my $connection = Net::NATS::Connection->new(socket_args => $self->socket_args)
        or return;
    $self->connection($connection);

    # Get INFO line
    my ($op, @args) = $self->read_line;
    my $info = $self->handle_info(@args);

    my $connect_info = Net::NATS::ConnectInfo->new(
        lang    => 'perl',
        version => $VERSION,
    );

    if ($info->auth_required) {
        if (!defined $uri->password) {
            $connect_info->auth_token($uri->user);
        } else {
            $connect_info->user($uri->user);
            $connect_info->pass($uri->password);
        }
    }

    if ($info->ssl_required || $info->tls_required) {
        $connection->upgrade()
            or return;

        $self->connection($connection);
    }

    my $connect = 'CONNECT ' . to_json($connect_info, { convert_blessed => 1});
    $self->connection->send($connect);

    return 1;
}

sub subscribe {
    my $self = shift;

    my ($subject, $group, $callback);

    if (@_ == 2) {
        ($subject, $callback) = @_;
    } else {
        ($subject, $group, $callback) = @_;
    }

    my $sid = $self->next_sid;

    my $sub = "SUB $subject";
    $sub .= " $group" if defined $group;
    $sub .= " $sid";

    $self->connection->send($sub);

    my $subscription = Net::NATS::Subscription->new(
        subject => $subject,
        group => $group,
        sid => $sid,
        callback => $callback,
        client => $self,
    );
    $self->subscriptions->{$sid} = $subscription;
    return $subscription;
}

sub unsubscribe {
    my $self = shift;
    my ($subscription, $max_msgs) = @_;

    $subscription->max_msgs = $max_msgs;
    my $sid = $subscription->sid;
    my $sub = "UNSUB $sid";
    $sub .= " $max_msgs" if defined $max_msgs;

    $self->connection->send($sub);

    $self->_remove_subscription($subscription)
        unless defined $max_msgs;
}

# 0:$self 1:$subject 2:$data 3:$reply_to
# Returns 1 on success, undef on failure
sub publish {
    my $reply_to = defined $_[3] ? $_[3].' ' : '';
    return $_[0]->connection->send('PUB '.$_[1].' '.$reply_to.length($_[2])."\r\n".$_[2]);
}

sub request {
    my ($self, $subject, $data, $callback) = @_;

    my $inbox = new_inbox();
    my $sub = $self->subscribe($inbox, $callback);
    $self->unsubscribe($sub, 1);
    $self->publish($subject, $data, $inbox);
}

sub _remove_subscription {
    my ($self, $subscription) = @_;

    delete $self->subscriptions->{$subscription->sid};
}

# blocking read built upon non-blocking read
sub read {
    my ($self, $length) = @_;

    my $data;
    my $rv = $self->connection->nb_read($data, $length);
    return unless $rv;          # EOF or error

    if ($rv eq '0E0') {
      while ($rv eq '0E0' && $self->connection->can_read()) { # keep trying until we get the data we need.
        $rv = $self->connection->nb_read($data,$length);
        return unless $rv;        # EOF or error. should report error somewhere...
      }
      return if $rv eq '0E0';   # got timeout from can_read
    }
    $data =~ s/\r\n$//;
    return $data;
}

# non-blocking version of read_line. if no timeout passed, will block
sub read_line {
    my ($self,$timeout) = @_;
    my $line;

    my $rv = $self->connection->nb_getline($line);
    return unless $rv;          # EOF or error

    if ($rv eq '0E0') {         # we do not have a full line
      while ($rv eq '0E0' && $self->connection->can_read($timeout)) {
        $rv = $self->connection->nb_getline($line);
        return unless $rv; # EOF or error. should report error somewhere...
      }
      return if $rv eq '0E0';   # got timeout from can_read
    }
    $line =~ s/\r\n$//;
    return split(' ', $line);
}

sub handle_info {
    my $self = shift;
    my (@args) = @_;
    my $hash = decode_json($args[0]);
    return Net::NATS::ServerInfo->new(%$hash);
}

sub parse_msg {
    my $self = shift;

    my ($subject, $sid, $length, $reply_to);

    if (@_ == 3) {
        ($subject, $sid, $length) = @_;
    } else {
        ($subject, $sid, $reply_to, $length) = @_;
    }

    my $data = $self->read($length+2);
    my $subscription = $self->subscriptions->{$sid};
    my $message = Net::NATS::Message->new(
        subject      => $subject,
        sid          => $sid,
        reply_to     => $reply_to,
        length       => $length,
        data         => $data,
        subscription => $subscription,
    );

    $subscription->message_count++;
    $self->message_count++;

    if ($subscription->defined_max && $subscription->message_count >= $subscription->max_msgs) {
        $self->_remove_subscription($subscription);
    }

    &{$subscription->callback}($message);
}

sub wait_for_op {
    my $self = shift;
    my $timeout = shift;        # in seconds; can be fractional

    my ($op, @args) = $self->read_line($timeout);
    return unless defined $op;

    if ($op eq 'MSG') {
        $self->parse_msg(@args);
    } elsif ($op eq 'PING') {
        $self->handle_ping;
    } elsif ($op eq 'PONG') {
    } elsif ($op eq '+OK') {
    } elsif ($op eq '-ERR') {
        return;
    }
    return 1;
}

sub handle_ping {
    my $self = shift;
    $self->connection->send("PONG");
}

sub next_sid {
    my $self = shift;
    return ++$self->current_sid;
}

sub close {
    my $self = shift;
    $self->connection->_socket->close;
}

sub new_inbox { sprintf("_INBOX.%08X%08X%06X", rand(2**32), rand(2**32), rand(2**24)); }

1;

__END__

=head1 NAME

Net::NATS::Client - A Perl client for the NATS messaging system.

=head1 SYNOPSIS

  #
  # Basic Usage
  #

  $client = Net::NATS::Client->new(uri => 'nats://localhost:4222');
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

  # Unsubscribe
  $subscription->unsubscribe();

  # Close connection
  $client->close();

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


  #
  # TLS
  #

  # Set the socket arguments that will be passed to IO::Socket::SSL
  my $socket_args = {
    SSL_cert_file => $cert_file,
    SSL_key_file  => $key_file,
  };

  my $client = Net::NATS::Client->new(uri => 'nats://localhost:4222', socket_args => $socket_args);
  $client->connect() or die $!;

=head1 REPOSITORY

L<https://github.com/carwynmoore/perl-nats>

=head1 AUTHOR

Carwyn Moore

Vick Khera, <vivek at khera.org>

=head1 COPYRIGHT AND LICENSE

MIT License.  See F<LICENCE> for the complete licensing terms.

Copyright (C) 2016 Carwyn Moore
