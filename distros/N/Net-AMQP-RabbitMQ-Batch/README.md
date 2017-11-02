# NAME

Net::AMQP::RabbitMQ::Batch - simple batch processing of messages for RabbitMQ.

# SYNOPSIS

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

# DESCRIPTION

Assume you read messages from a queue, process them and publish. But you would like to do it in batches, processing many messages at once.

This module:

- gets messages from in queue and publish them by routing key
- uses your handler to batch process messages
- keeps persistency - if processing fails, nothing lost from input queue, nothing published

# USAGE

Define a messages handler:

    sub msg_handler {
        my $messages = shift;
        # works with hashref of messages
        return $messages;
    }

`$messages` is an arrayref of message objects:

    {
        body => 'Magic Transient Payload', # the reconstructed body
        routing_key => 'nr_test_q',        # route the message took
        delivery_tag => 1,                 # (used for acks)
        ....
        # Not all of these will be present. Consult the RabbitMQ reference for more details.
        props => { ... }
    }

Handler should return arrayref of message objects (only `body` is required):

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

You might like to wrap it with `while(1) {...}` loop. See `process_in_batches.pl` or `process_in_forked_batches.pl` for example.

# METHODS

## process()

# Known Issues

- Can not set infinity timeout (use very long int)
- No individual messages processing possible
- No tests yet which is very sad :(

# AUTHORS

Alex Svetkin

# LICENSE

MIT
