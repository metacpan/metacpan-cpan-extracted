# NAME

Net::Kafka - High-performant Perl client for Apache Kafka

# SYNOPSIS

    use Net::Kafka::Producer;
    use Net::Kafka::Consumer;
    use AnyEvent;

    # Produce 1 message into "my_topic"
    my $condvar     = AnyEvent->condvar;
    my $producer    = Net::Kafka::Producer->new(
        'bootstrap.servers' => 'localhost:9092'
    );
    $producer->produce(
        payload => "message",
        topic   => "my_topic"
    )->then(sub {
        my $delivery_report = shift;
        $condvar->send;
        print "Message successfully delivered with offset " . $delivery_report->{offset};
    }, sub {
        my $error = shift;
        $condvar->send;
        die "Unable to produce a message: " . $error->{error} . ", code: " . $error->{code};
    });
    $condvar->recv;

    # Consume message from "my_topic"
    my $consumer    = Net::Kafka::Consumer->new(
        'bootstrap.servers'     => 'localhost:9092',
        'group.id'              => 'my_consumer_group',
        'enable.auto.commit'    => 'true',
    );

    $consumer->subscribe( [ "my_topic" ] );
    while (1) {
        my $msg = $kafka->consumer_poll(1000);
        if ($msg) {
            if ( $msg->err ) {
                say "Error: ", Net::Kafka::Error::to_string($err);
            }
            else {
                say $msg->payload;
            }
        }
    }

# DESCRIPTION

This module provides Perl bindings to librdkafka C client library (https://github.com/edenhill/librdkafka).
It is heavily inspired by Kafka::Librd module originally developed by Pavel Shaydo (https://github.com/trinitum/perl-Kafka-Librd).

Please refer to the following modules documentation in order to understand how to use it:

- `Net::Kafka::Producer` - asynchronous producer interface
- `Net::Kafka::Consumer` - consumer interface that supports both Simple and Distributed modes

# REQUIREMENTS

- GNU make
- pthreads
- librdkafka >= 1.0.0
- lz (optional, for gzip compression support)
- libssl (optional, for SSL and SASL SCRAM support)
- libsasl2 (optional, for SASL GSSAPI support)
- libzstd (optional, for ZStd compression support)

# INSTALLATION

First download and build librdkafka (https://github.com/edenhill/librdkafka#building).

Then to install this module run the following commands:

    perl Makefile.pl
    make
    make test
    make install

# Net::Kafka::Producer

The Net::Kafka::Producer module provides interface to librdkafka's producer methods. It utilizes signal pipes,
[AnyEvent](https://metacpan.org/pod/AnyEvent) watcher and [AnyEvent::XSPromises](https://metacpan.org/pod/AnyEvent%3A%3AXSPromises) to make its behaviour asynchronous. Taking that into consideration
you need to make sure to properly create condvar and `send`/`recv` in order to collect all outstanding promises.
It is highly suggested to familirize yourself with both [AnyEvent](https://metacpan.org/pod/AnyEvent) and [AnyEvent::XSPromises](https://metacpan.org/pod/AnyEvent%3A%3AXSPromises) modules. See ["SYNOPSIS"](#synopsis) for example.

## METHODS

- new()

        my $producer = Net::Kafka::Producer->new(
            'bootstrap.servers' => 'localhost:9092'
        );

    Create an instance of Net::Kafka::Producer. Accept hash where keys are equal to property names of librdkafka (see [https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md)).
    Note that only `error_cb` and `stats_cb` callbacks are supported for Producer. Message delivery reports are served automatically through `Promise` based `produce` method (see below).

- produce()

        my $promise = $producer->produce(
            payload => "my_message",
            topic   => "my_topic",
            key     => "my_key",    # optional
            timestamp => 1234567,   # optional, if not specified current local timestamp will be used
            partition => 0          # optional, if not specified internal librdkafka partitioner will be used
            headers   => $headers,  # Optional, see Net::Kafka::Headers
        )->then(sub {
            my $delivery_report = shift;
            echo "Message is sent with offset " . $delivery_report->{offset};
        })->catch(sub {
            my $error = shift;
            print $error->{error} . "\n";
        });

    Sends a message to Kafka. Accepts hash with parameters.

    Returns back an instance of `Promise` that will be resolved/rejected later. In case message is successfully send "resolve" callback
    will receive a delievry report in the form of the hash that contains `offset`, `partition` and `timestamp`. If message delivery has failed
    "reject" callback will receive a hash that contains `error` (a human readable error description) and (optionally) `error_code` that is
    equal to librdkafka's error code. All error codes are mapped and exported by `Net::Kafka` module as constants (e.g. `Net::Kafka::RD_KAFKA_RESP_ERR__PREV_IN_PROGRESS`) 
    for simplicity.

- partitions\_for()

        my $partitions = $producer->partitions_for("my_topic", $timeout_ms);

    Returns an `ARRAYREF` that contains partition metadata information about the given topic (leader, replicas, ISR replicas);

- close()

        $producer->close();

    Explicitly closees `Net::Kafka::Producer` instance and underlying librdkafka handles.

# Net::Kafka::Consumer

The Net::Kafka::Consumer class provides interface to librdkafka's consumer functionality. It supports both "distributed" (subscription based) and
"simple" (manual partition assignment) modes of work.

- new()

        my $consumer = Net::Kafka::Consumer->new(
            'bootstrap.servers'  => 'localhost:9092',
            'group.id'           => "my_consumer_group",
            'enable.auto.commit' => "true",
        );

    Create an instance of Net::Kafka::Consumer. Accept hash where keys are equal to property names of librdkafka (see [https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md)).
    Note that not all callbacks are supported at the moment. Supported ones are: `error_cb`, `rebalance_cb`, `commit_cb` and `stats_cb`.

- subscribe()

        $consumer->subscribe([ 'my_topic' ]);

    Subscribe to topic set using balanced consumer groups. The main entry-point for "distributed" consumer mode - partitions will be assigned automatically using Kafka's GroupApi semantics.
    Wildcard/regex topics are supported so matching topics will be added to the subscription list.

- unsubscribe()

        $consumer->unsubscribe();

    Unsubscribe from the current subscription set.

- assign()

        # manually assign partitions 0 and 1 to be consumed
        my $tp_list = Net::Kafka::TopicPartitionList->new();
        $tp_list->add("my_topic", 0);
        $tp_list->add("my_topic", 1);
        $consumer->assign($tp_list);

    Atomic assignment of partitions to consume. The main entry-point for "simple" consumer mode - partitions are assigned manually.

- poll()

        my $message = $consumer->poll($timeout_ms);

    Poll the consumer for messages or events. Returns instance of `Net::Kafka::Message`. Will block for at most `timeout_ms` milliseconds. An application should make sure to call
    `poll` at regular intervals.

- committed()

        my $tp_list = Net::Kafka::TopicPartitionList->new();
        $tp_list->add("my_topic", 0);
        $consumer->committed($tp_list);
        my $offset = $tp_list->offset("my_topic_, 0);

    Retrieve committed offsets for topics+partitions.

- offsets\_for\_times()

        my $tp_list = Net::Kafka::TopicPartitionList->new();
        $tp_list->add("my_topic", 0);
        $tp_list->set_offset("my_topic", 0, 958349923); # timestamp if passed through offset field
        $consumer->offsets_for_times($tp_list);
        my $offset = $tp_list->offset("my_topic");

    Look up the offsets for the given partitions by timestamp.

- pause()

        my $tp_list = Net::Kafka::TopicPartitionList->new();
        $tp_list->add("my_topic", 0);
        $consumer->pause($tp_list); # pauses consumption of partition 0 of "my_topic"

    Pause consumption for the provided list of partitions.

- resume()

        my $tp_list = Net::Kafka::TopicPartitionList->new();
        $tp_list->add("my_topic", 0);
        $consumer->resume($tp_list); # resumes consumption of partition 0 of "my_topic"

    Resume consumption for the provided list of partitions.

- subscription()

        my $topics = $consumer->subscription();

    Returns the current topic subscription

- partitions\_for()

        my $partitions = $producer->partitions_for("my_topic");

    Returns an `ARRAYREF` that contains partition metadata information about the given topic (leader, replicas, ISR replicas);

- commit()

        $consumer->commit(); # commit current partition assignment (blocking call)
        $consumer->commit(1); # commit current partition assignment (non-blocking call)
        my $tp_list = Net::Kafka::TopicPartitionList->new();
        $tp_list->add("my_topic", 0);
        $tp_list->set_offset("my_topic", 0, 12345);
        $consumer->commit(0, $tp_list); # commit $tp_list assignment (blocking call);

    Commit offsets on broker for the provided list of partitions. If no partitions provided current assignment is committed instead.

- commit\_message();

        my $message = $consumer->poll(1000);
        $consumer->commit_message(0, $message); # commit message (blocking call);
        $consumer->commit_message(1, $message); # commit message (non-blocking call);

    Commit message's offset on broker for the message's partition.

- position()

        my $position_list = Net::Kafka::TopicPartitionList->new();
        $position_list->add("my_topic", 0);
        $consumer->position($position_list);
        my $position = $position_list->offset("my_topic", 0);

    Retrieve current positions (offsets) for topics+partitions. The \\p offset field of each requested partition 
    will be set to the offset of the last consumed message + 1, or RD\_KAFKA\_OFFSET\_INVALID in case there was
    no previous message.

    Note: in this context the last consumed message is the offset consumed by the current librdkafka instance
    and, in case of rebalancing, not necessarily the last message fetched from the partition.

- seek()

        $consumer->seek("my_topic", 0, 12345); # seek partition 0 of "my_topic" to offset "12345"
        $consumer->seek("my_topic", 0, RD_KAFKA_OFFSET_BEGINNING); # seek to the beginning of "my_topic" partition 0
        $consumer->seek("my_topic", 0, RD_KAFKA_OFFSET_END); # seek to the end of "my_topic" partition 0

    Seek consumer for topic+partition to offset which is either an absolute or logical offset.

- query\_watermark\_offsets()

        my ($low, $high) = $consumer->query_watermark_offsets("my_topic", 0);

    Queries Kafka Broker for lowest and highest watermark offsets in the given topic-partition.

- close()

        $consumer->close();

    Close all consumer handles. Make sure to call it before destroying your application to make sure that all outstanding requests to be flushed.

# Net::Kafka::Message

This class maps to `rd_kafka_message_t` structure from librdkafka and
represents message or event. Objects of this class have the following methods:

- err()

    return error code from the message

- topic()

    return topic name

- partition()

    return partition number

- offset()

    return offset. Note, that the value is truncated to 32 bit if your perl doesn't
    support 64 bit integers.

- key()

    return message key

- payload()

    return message payload

- headers()

    return a copy of message headers

- detach\_headers()

    return message headers and removes them from the message

# Net::Kafka::Headers

This class contains a list of Kafka headers (it allows duplicates).
Objects of this class have the following methods:

- new()

    create a new instance

- add(name, value)

    append a new name/value pair to the header list

- remove(name)

    remove all headers with the given name, if any

- get\_last(name)

    return the last value associated with a given name

- to\_hash()

    return an hash-of-arrays containing all headers

# Net::Kafka::Err

This class provides static methods to convert error codes into names
and descriptions.

- rd\_kafka\_get\_err\_descs()

        rd_kafka_get_err_descs()

    returns a hash mapping error codes to description strings.

- to\_string()

        to_string($code)

    return the description string for this error code.

- to\_name()

        to_name($code)

    return the name of this error code.

# CAVEATS

Message offset is truncated to 32 bit if perl is compiled without support for 64 bit integers.

# SEE ALSO

[https://github.com/edenhill/librdkafka](https://github.com/edenhill/librdkafka)

# LICENSE AND COPYRIGHT

Copyright (C) 2016, 2017 Pavel Shaydo

Copyright (C) 2018, 2019 Booking.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
