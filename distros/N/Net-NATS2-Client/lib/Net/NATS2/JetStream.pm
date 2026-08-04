package Net::NATS2::JetStream;

use v5.10;
use strict;
use warnings;

use JSON qw(decode_json encode_json);
use Time::HiRes 'time';
use Net::NATS2::Base;

has $_ for qw(client timeout last_error);

sub api_info {
    my ($self, $timeout) = @_;
    return $self->_request('$JS.API.INFO', '', $timeout);
}

sub add_stream {
    my ($self, $config, $timeout) = @_;
    return $self->_request('$JS.API.STREAM.CREATE.' . $config->{name}, encode_json($config), $timeout);
}

sub update_stream {
    my ($self, $config, $timeout) = @_;
    return $self->_request('$JS.API.STREAM.UPDATE.' . $config->{name}, encode_json($config), $timeout);
}

sub stream_info {
    my ($self, $name, $timeout) = @_;
    return $self->_request('$JS.API.STREAM.INFO.' . $name, '', $timeout);
}

sub stream_list {
    my ($self, $offset, $timeout) = @_;
    $offset = 0 unless defined $offset;
    return $self->_request('$JS.API.STREAM.LIST', encode_json({offset => $offset}), $timeout);
}

sub delete_stream {
    my ($self, $name, $timeout) = @_;
    return $self->_request('$JS.API.STREAM.DELETE.' . $name, '', $timeout);
}

sub purge_stream {
    my ($self, $name, $timeout) = @_;
    return $self->_request('$JS.API.STREAM.PURGE.' . $name, '', $timeout);
}

sub add_consumer {
    my ($self, $stream, $config, $timeout) = @_;
    my $durable = $config->{durable_name} || $config->{name};
    my $subject
        = defined $durable
        ? '$JS.API.CONSUMER.DURABLE.CREATE.' . $stream . '.' . $durable
        : '$JS.API.CONSUMER.CREATE.' . $stream;
    return $self->_request($subject, encode_json({stream_name => $stream, config => $config,}), $timeout);
}

sub consumer_info {
    my ($self, $stream, $consumer, $timeout) = @_;
    return $self->_request('$JS.API.CONSUMER.INFO.' . $stream . '.' . $consumer, '', $timeout);
}

sub delete_consumer {
    my ($self, $stream, $consumer, $timeout) = @_;
    return $self->_request('$JS.API.CONSUMER.DELETE.' . $stream . '.' . $consumer, '', $timeout);
}

sub publish {
    my ($self, $subject, $data, $timeout) = @_;
    return $self->_request($subject, $data, $timeout);
}

sub fetch {
    my ($self, $stream, $consumer, $batch, $timeout) = @_;
    $batch   = 1              unless defined $batch;
    $timeout = $self->timeout unless defined $timeout;
    $timeout = 1              unless defined $timeout;
    $self->last_error(undef);

    my @messages;
    my $status;
    my $inbox        = $self->client->new_inbox;
    my $subscription = $self->client->subscribe(
        $inbox,
        sub {
            my ($message) = @_;
            $status = _status($message) || $status;
            push @messages, $message unless _status($message);
        }
    );

    my $request = encode_json({batch => $batch, expires => int($timeout * 1_000_000_000),});
    my $subject = '$JS.API.CONSUMER.MSG.NEXT.' . $stream . '.' . $consumer;
    unless ($self->client->publish($subject, $request, $inbox)) {
        $self->client->unsubscribe($subscription);
        $self->last_error({description => 'JetStream fetch publish failed'});
        return;
    }

    my $deadline = time + $timeout;
    while (@messages < $batch && !$status) {
        my $remaining = $deadline - time;
        last if $remaining <= 0;
        last unless $self->client->wait_for_op($remaining);
    }
    $self->client->unsubscribe($subscription);

    $self->last_error($status) if $status && $status->{code} != 404 && $status->{code} != 408;
    return \@messages;
}

sub next_message {
    my ($self, $stream, $consumer, $timeout) = @_;
    my $messages = $self->fetch($stream, $consumer, 1, $timeout) || return;
    return $messages->[0];
}

sub ack {
    return _ack($_[0], $_[1], '');
}

sub nak {
    return _ack($_[0], $_[1], '-NAK');
}

sub term {
    return _ack($_[0], $_[1], '+TERM');
}

sub _ack {
    my ($self, $message, $payload) = @_;
    return unless defined $message->reply_to;
    return $self->client->publish($message->reply_to, $payload);
}

sub _status {
    my $message = shift;
    return unless defined $message->headers;
    my ($code, $description) = $message->headers =~ /^NATS\/1\.0\s+(\d+)(?:\s+([^\r\n]*))?/m;
    ($code) = $message->headers =~ /^Status:\s*(\d+)(?:\s+.*)?$/mi unless defined $code;
    return                                                          unless defined $code;
    ($description) = $message->headers =~ /^Description:\s*(.*)$/mi unless defined $description;
    return {code => $code, description => $description};
}

sub _request {
    my ($self, $subject, $data, $timeout) = @_;
    $self->last_error(undef);
    $timeout = $self->timeout unless defined $timeout;
    $timeout = 1              unless defined $timeout;

    my $message = $self->client->request_sync($subject, $data, $timeout);
    unless ($message) {
        $self->last_error({description => 'JetStream request timed out or failed'});
        return;
    }

    my $response = eval { decode_json($message->data) };
    if ($@ || ref $response ne 'HASH') {
        $self->last_error({description => 'JetStream returned an invalid JSON response'});
        return;
    }
    if ($response->{error}) {
        $self->last_error($response->{error});
        return;
    }
    return $response;
}

1;

__END__

=head1 NAME

Net::NATS2::JetStream - JetStream stream management and synchronous publishing

=head1 SYNOPSIS

  my $js = Net::NATS2::JetStream->new(client => $client);
  $js->add_stream({ name => 'ORDERS', subjects => ['orders'] });
  my $ack = $js->publish('orders', 'created');

  $js->add_consumer('ORDERS', {
      durable_name => 'WORKER',
      ack_policy   => 'explicit',
  });
  my $message = $js->next_message('ORDERS', 'WORKER');
  $js->ack($message);

=head1 DESCRIPTION

This module wraps the JetStream request/reply API for account information,
stream and consumer management, synchronous publish acknowledgements, and
pull-consumer delivery. Methods return a decoded response hash on success. On
failure they return undef and make the JetStream error response, when
available, accessible through C<last_error>.

=head1 PULL CONSUMERS

C<add_consumer($stream, $config)> creates a consumer. Provide C<durable_name>
for a durable consumer and omit C<deliver_subject> to create a pull consumer.
C<fetch($stream, $consumer, $batch, $timeout)> returns an array reference of
up to C<$batch> messages. C<next_message> is the single-message equivalent.

Use C<ack($message)>, C<nak($message)>, or C<term($message)> to acknowledge,
request redelivery, or stop delivery of a received JetStream message.

=cut
