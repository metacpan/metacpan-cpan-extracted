package Net::AMQP::RabbitMQ::Batch;

use strict;
use warnings;

our $VERSION = '0.2301';

use Carp qw(carp croak cluck confess);
use Carp::Assert;
use Try::Tiny;
use Net::AMQP::RabbitMQ;
use Time::HiRes qw(time);
use Data::Dumper;

=encoding UTF-8

=head1 NAME

Net::AMQP::RabbitMQ::Batch - simple batch processing of messages for RabbitMQ.

=head1 SYNOPSIS

    my $rb = Net::AMQP::RabbitMQ::Batch->new('localhost', { user => 'guest', password => 'guest' }) or croak;
    $rb->process({
        from_queue  => 'test_in',
        routing_key => 'test_out',
        handler     => \&msg_handler,
        batch       => {
            size          => 10,        # batch size
            timeout       => 2,         #
            ignore_size   => 0          # ignore in/out batches size mismatch
        },
        ignore_errors => 0,             # ignore handler errors
        publish_options => {
            exchange => 'exchange_out', # exchange name, default is 'amq.direct'
        },
    });

    sub msg_handler {
        my $messages = shift;
        # work with 10 messages
        return $messages;
    }

=head1 DESCRIPTION

Assume you read messages from a queue, process them and publish. But you would like to do it in batches, processing many messages at once.

This module:

=over

=item *
gets messages from in queue and publish them by routing key

=item *
uses your handler to batch process messages

=item *
keeps persistency - if processing fails, nothing lost from input queue, nothing published

=back

=head1 USAGE

Define a messages handler:

    sub msg_handler {
        my $messages = shift;
        # works with hashref of messages
        return $messages;
    }

C<$messages> is an arrayref of message objects:

    {
        body => 'Magic Transient Payload', # the reconstructed body
        routing_key => 'nr_test_q',        # route the message took
        delivery_tag => 1,                 # (used for acks)
        ....
        # Not all of these will be present. Consult the RabbitMQ reference for more details.
        props => { ... }
    }

Handler should return arrayref of message objects (only C<body> is required):

    [
        { body => 'Processed message' },
        ...
    ]

Connect to RabbitMQ:

    my $rb = Net::AMQP::RabbitMQ::Batch->new('localhost', { user => 'guest', password => 'guest' }) or croak;

And process a batch:

    $rb->process({
        from_queue  => 'test_in',
        routing_key => 'test_out',
        handler     => \&msg_handler,
        batch       => { size => 10 }
    });

You might like to wrap it with C<while(1) {...}> loop. See F<process_in_batches.pl> or F<process_in_forked_batches.pl> for example.

=head1 METHODS

=head2 process()

=head1 Known Issues

=over

=item *
Can not set infinity timeout (use very long int)

=item *
No individual messages processing possible

=item *
No tests yet which is very sad :(

=back

=head1 AUTHORS

Alex Svetkin

=head1 LICENSE

MIT

=cut

sub new {
    my ($class, $rabbit_hostname, $rabbit_options) = @_;
    croak('No hostname given') unless $rabbit_hostname;
    croak('No connection options given') unless $rabbit_options;

    return bless {
        mq => $class->_get_mq($rabbit_hostname, $rabbit_options),
    }, $class;
}

sub _get_mq {
    my ($class, $rabbit_hostname, $rabbit_options) = @_;
    my $mq = Net::AMQP::RabbitMQ->new();
    $mq->connect($rabbit_hostname, $rabbit_options) or croak;
    return $mq;
}

sub process {
    my ($self, $options) = @_;
    my $channel_id = $options->{channel_id} || int(rand(65535)) + 1;
    my $from_queue = $options->{from_queue} or croak('No from_queue given');
    if (defined($options->{publish_options}) && !defined($options->{routing_key})) {
        croak('publish_options set but not routing_key defined!');
    }
    my $publish = defined($options->{routing_key}) ? 1 : 0;
    my $routing_key = $options->{routing_key};
    my $handler = $options->{handler} or croak('No handler given');
    my $ignore_errors = $options->{ignore_errors} || 0;

    my $success = 1;

    try {
        $self->{mq}->channel_open($channel_id);
        my $messages = $self->_get($channel_id, $from_queue, {no_ack => 0}, $options->{batch});
        my $processed_messages = undef;
        try {
            $processed_messages = &$handler($messages);
        } catch {
            if ($ignore_errors) {
                cluck("Batch handler error: $_");
                $success = 0;
            } else {
                confess("Batch handler error: $_");
            }
        };
        if ($success && $self->_check_messages($messages, $processed_messages, $options->{batch})) {
            if ($publish) {
                $self->_publish($processed_messages, $channel_id, $routing_key,
                    $options->{publish_options}, $options->{publish_props});
            }
            $self->_ack_messages($messages, $channel_id);
        } else {
            $success = 0;
        }
    } catch {
        croak("Error: $_");
    } finally {
        $self->{mq}->channel_close($channel_id);
    };

    return $success;
}

sub _get {
    my ($self, $channel_id, $queue, $mq_opts, $opts) = @_;
    assert($channel_id);
    assert($queue);
    $opts->{size} ||= 10;
    $opts->{timeout} ||= 30;
    $opts->{sleep} ||= 1;

    my $batch_activity_ts = time();
    my $messages = [];
    while (scalar(@$messages) < $opts->{size}) {
        my $msg = $self->{mq}->get($channel_id, $queue, $mq_opts);
        if ($msg) {
            $batch_activity_ts = time();
            push(@$messages, $msg);
        } else {
            if (time() - $batch_activity_ts > $opts->{timeout}) {
                last;
            } else {
                sleep($opts->{sleep});
            }
        }
    }
    return $messages;
}

sub _publish {
    my ($self, $messages, $channel_id, $queue, $mq_options, $mq_props) = @_;
    assert(ref($messages) eq 'ARRAY');
    assert($channel_id);
    assert($queue);

    foreach my $msg (@$messages) {
        assert($msg->{body});
        $self->{mq}->publish($channel_id, $queue, $msg->{body}, $mq_options, $mq_props);
    }
    return;
}

sub _ack_messages {
    my ($self, $messages, $channel_id) = @_;
    assert(ref($messages) eq 'ARRAY');
    assert($channel_id);

    foreach my $msg (@$messages) {
        assert($msg->{delivery_tag});
        $self->{mq}->ack($channel_id, $msg->{delivery_tag});
    }
    return;
}

sub _check_messages {
    my ($self, $messages, $processed_messages, $options) = @_;
    assert(ref($messages) eq 'ARRAY');
    assert(ref($options) eq 'HASH');

    if (ref($processed_messages) ne 'ARRAY') {
        carp('Invalid handler output (expected ARRAYREF)');
        return 0;
    }
    if (!$options->{ignore_size} && scalar(@$messages) != scalar(@$processed_messages)) {
        carp(sprintf('Numbers of incoming and processed messages do not match (expected %d, got %d). '
            . 'Discarding this batch',
            scalar(@$messages), scalar(@$processed_messages)));
        return 0;
    }
    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->{mq}->disconnect();
    return;
}

1;
