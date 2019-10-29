package Net::Kafka;

use strict;
use warnings;
use constant;

require Exporter;
our @ISA = qw/Exporter/;
our (@EXPORT_OK, %EXPORT_TAGS);

BEGIN {
    our $VERSION = "1.06";
    my $XS_VERSION = $VERSION;
    $VERSION = eval $VERSION;

    require XSLoader;
    XSLoader::load('Net::Kafka', $XS_VERSION);

    my $errors = Net::Kafka::Error::rd_kafka_get_err_descs();
    no strict 'refs';
    for ( keys %$errors ) {
        *{__PACKAGE__ . "::RD_KAFKA_RESP_ERR_$_"} = eval "sub() { $errors->{$_} }";
        push @EXPORT_OK, "RD_KAFKA_RESP_ERR_$_";
    }

    my %constants = (
        RD_KAFKA_TOPIC_CONFIG_KEYS => [qw/
            request.required.acks
            acks
            request.timeout.ms
            message.timeout.ms
            delivery.timeout.ms
            queuing.strategy
            produce.offset.report
            partitioner
            partitioner_cb
            msg_order_cmp
            opaque
            compression.codec
            compression.type
            compression.level
            auto.offset.reset
            offset.store.path
            offset.store.sync.interval.ms
            offset.store.method
            consume.callback.max.messages
        /],
        DEFAULT_METADATA_TIMEOUT => 1000,
    );

    push @EXPORT_OK => keys %constants;
    push @EXPORT_OK => (qw/
        RD_KAFKA_VERSION
        RD_KAFKA_PARTITION_UA
        RD_KAFKA_OFFSET_END
        RD_KAFKA_VERSION
        RD_KAFKA_PRODUCER
        RD_KAFKA_CONSUMER
        RD_KAFKA_TIMESTAMP_NOT_AVAILABLE
        RD_KAFKA_TIMESTAMP_CREATE_TIME
        RD_KAFKA_TIMESTAMP_LOG_APPEND_TIME
        RD_KAFKA_PARTITION_UA
        RD_KAFKA_OFFSET_BEGINNING
        RD_KAFKA_OFFSET_END
        RD_KAFKA_OFFSET_STORED
        RD_KAFKA_OFFSET_INVALID
        RD_KAFKA_OFFSET_STORED
        RD_KAFKA_EVENT_NONE
        RD_KAFKA_EVENT_DR
        RD_KAFKA_EVENT_FETCH
        RD_KAFKA_EVENT_LOG
        RD_KAFKA_EVENT_ERROR
        RD_KAFKA_EVENT_REBALANCE
        RD_KAFKA_EVENT_OFFSET_COMMIT
        RD_KAFKA_EVENT_STATS
    /);

    %EXPORT_TAGS = (
        all => [ @EXPORT_OK ],
    );

    constant->import({ %constants });
}

sub partitions_for {
    my ($self, $topic, $timeout_ms) = @_;
    $timeout_ms //= DEFAULT_METADATA_TIMEOUT;
    my $metadata = $self->topic($topic)->metadata($timeout_ms);
    my @topics   = grep { $_->{topic_name} eq $topic } @{ $metadata->{topics} };
    die sprintf("Unable to fetch metadata for topic %s", $topic)
        if scalar @topics != 1;
    my $topic_metadata = shift @topics;
    die sprintf("Unable to fetch partitions metadata for topic %s", $topic)
        unless @{ $topic_metadata->{partitions} };
    return $topic_metadata->{partitions};
}

1;

=head1 NAME

=for markdown [![Build Status](https://travis-ci.com/bookingcom/perl-Net-Kafka.svg?branch=master)](https://travis-ci.com/bookingcom/perl-Net-Kafka)

Net::Kafka - High-performant Perl client for Apache Kafka

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module provides Perl bindings to L<librdkafka|https://github.com/edenhill/librdkafka> C client library.
It is heavily inspired by L<Kafka::Librd> module originally developed by Pavel Shaydo.

Please refer to the following modules documentation in order to understand how to use it:

=over

=item *
C<Net::Kafka::Producer> - asynchronous producer interface

=item *
C<Net::Kafka::Consumer> - consumer interface that supports both Simple and Distributed modes

=back

=head1 REQUIREMENTS

=over

=item *
GNU make

=item *
librdkafka >= 1.0.0

=back

=head1 INSTALLATION

First install librdkafka (L<https://github.com/edenhill/librdkafka#installation>).

=head2 BUILD FROM CPAN

    cpanm install Net::Kafka

=head2 BUILD FROM SOURCE

Sources are available on Github: L<https://github.com/bookingcom/perl-Net-Kafka>.

    perl Makefile.pl
    make
    make test
    make install

=head1 Net::Kafka::Producer

The Net::Kafka::Producer module provides interface to librdkafka's producer methods. It utilizes signal pipes,
L<AnyEvent> watcher and L<AnyEvent::XSPromises> to make its behaviour asynchronous. Taking that into consideration
you need to make sure to properly create condvar and C<send>/C<recv> in order to collect all outstanding promises.
It is highly suggested to familirize yourself with both L<AnyEvent> and L<AnyEvent::XSPromises> modules. See L</SYNOPSIS> for example.

=head2 METHODS

=over 4

=item new()

    my $producer = Net::Kafka::Producer->new(
        'bootstrap.servers' => 'localhost:9092'
    );

Create an instance of Net::Kafka::Producer. Accept hash where keys are equal to property names of librdkafka (see L<https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md>).
Note that only C<error_cb> and C<stats_cb> callbacks are supported for Producer. Message delivery reports are served automatically through C<Promise> based C<produce> method (see below).

=item produce()

    my $promise = $producer->produce(
        payload     => "my_message",
        topic       => "my_topic",
        key         => "my_key",    # optional
        timestamp   => 1234567,   # optional, if not specified current local timestamp will be used
        partition   => 0          # optional, if not specified internal librdkafka partitioner will be used
        headers     => $headers,  # Optional, see Net::Kafka::Headers
    )->then(sub {
        my $delivery_report = shift;
        print "Message is sent with offset " . $delivery_report->{offset};
    })->catch(sub {
        my $error = shift;
        print $error->{error} . "\n";
    });

Sends a message to Kafka. Accepts hash with parameters.

Returns back an instance of C<Promise> that will be resolved/rejected later. In case message is successfully send "resolve" callback
will receive a delievry report in the form of the hash that contains C<offset>, C<partition> and C<timestamp>. If message delivery has failed
"reject" callback will receive a hash that contains C<error> (a human readable error description) and (optionally) C<error_code> that is
equal to librdkafka's error code. All error codes are mapped and exported by C<Net::Kafka> module as constants (e.g. C<Net::Kafka::RD_KAFKA_RESP_ERR__PREV_IN_PROGRESS>) 
for simplicity.

=item partitions_for()

    my $partitions = $producer->partitions_for("my_topic", $timeout_ms);

Returns an C<ARRAYREF> that contains partition metadata information about the given topic (leader, replicas, ISR replicas);

=item close()

    $producer->close();

Explicitly closees C<Net::Kafka::Producer> instance and underlying librdkafka handles.

=back

=head1 Net::Kafka::Consumer

The Net::Kafka::Consumer class provides interface to librdkafka's consumer functionality. It supports both "distributed" (subscription based) and
"simple" (manual partition assignment) modes of work.

=head2 METHODS

=over 4

=item new()

    my $consumer = Net::Kafka::Consumer->new(
        'bootstrap.servers'  => 'localhost:9092',
        'group.id'           => "my_consumer_group",
        'enable.auto.commit' => "true",
    );

Create an instance of Net::Kafka::Consumer. Accept hash where keys are equal to property names of librdkafka (see L<https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md>).
Note that not all callbacks are supported at the moment. Supported ones are: C<error_cb>, C<rebalance_cb>, C<commit_cb> and C<stats_cb>.

=item subscribe()

    $consumer->subscribe([ 'my_topic' ]);

Subscribe to topic set using balanced consumer groups. The main entry-point for "distributed" consumer mode - partitions will be assigned automatically using Kafka's GroupApi semantics.
Wildcard/regex topics are supported so matching topics will be added to the subscription list.

=item unsubscribe()

    $consumer->unsubscribe();

Unsubscribe from the current subscription set.

=item assign()

    # manually assign partitions 0 and 1 to be consumed
    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add("my_topic", 0);
    $tp_list->add("my_topic", 1);
    $consumer->assign($tp_list);

Atomic assignment of partitions to consume. The main entry-point for "simple" consumer mode - partitions are assigned manually.

=item poll()

    my $message = $consumer->poll($timeout_ms);

Poll the consumer for messages or events. Returns instance of C<Net::Kafka::Message>. Will block for at most C<timeout_ms> milliseconds. An application should make sure to call
C<poll> at regular intervals.

=item committed()

    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add("my_topic", 0);
    $consumer->committed($tp_list);
    my $offset = $tp_list->offset("my_topic_, 0);

Retrieve committed offsets for topics+partitions.

=item offsets_for_times()

    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add("my_topic", 0);
    $tp_list->set_offset("my_topic", 0, 958349923); # timestamp if passed through offset field
    $consumer->offsets_for_times($tp_list);
    my $offset = $tp_list->offset("my_topic");

Look up the offsets for the given partitions by timestamp.

=item pause()

    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add("my_topic", 0);
    $consumer->pause($tp_list); # pauses consumption of partition 0 of "my_topic"

Pause consumption for the provided list of partitions.

=item resume()

    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add("my_topic", 0);
    $consumer->resume($tp_list); # resumes consumption of partition 0 of "my_topic"

Resume consumption for the provided list of partitions.

=item subscription()

    my $topics = $consumer->subscription();

Returns the current topic subscription

=item partitions_for()

    my $partitions = $producer->partitions_for("my_topic");

Returns an C<ARRAYREF> that contains partition metadata information about the given topic (leader, replicas, ISR replicas);

=item commit()

    $consumer->commit(); # commit current partition assignment (blocking call)
    $consumer->commit(1); # commit current partition assignment (non-blocking call)
    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add("my_topic", 0);
    $tp_list->set_offset("my_topic", 0, 12345);
    $consumer->commit(0, $tp_list); # commit $tp_list assignment (blocking call);

Commit offsets on broker for the provided list of partitions. If no partitions provided current assignment is committed instead.

=item commit_message();

    my $message = $consumer->poll(1000);
    $consumer->commit_message(0, $message); # commit message (blocking call);
    $consumer->commit_message(1, $message); # commit message (non-blocking call);

Commit message's offset on broker for the message's partition.

=item position()

    my $position_list = Net::Kafka::TopicPartitionList->new();
    $position_list->add("my_topic", 0);
    $consumer->position($position_list);
    my $position = $position_list->offset("my_topic", 0);

Retrieve current positions (offsets) for topics+partitions. The \p offset field of each requested partition 
will be set to the offset of the last consumed message + 1, or RD_KAFKA_OFFSET_INVALID in case there was
no previous message.

Note: in this context the last consumed message is the offset consumed by the current librdkafka instance
and, in case of rebalancing, not necessarily the last message fetched from the partition.

=item seek()

    $consumer->seek("my_topic", 0, 12345); # seek partition 0 of "my_topic" to offset "12345"
    $consumer->seek("my_topic", 0, RD_KAFKA_OFFSET_BEGINNING); # seek to the beginning of "my_topic" partition 0
    $consumer->seek("my_topic", 0, RD_KAFKA_OFFSET_END); # seek to the end of "my_topic" partition 0

Seek consumer for topic+partition to offset which is either an absolute or logical offset.

=item query_watermark_offsets()
    
    my ($low, $high) = $consumer->query_watermark_offsets("my_topic", 0);

Queries Kafka Broker for lowest and highest watermark offsets in the given topic-partition.

=item close()

    $consumer->close();

Close all consumer handles. Make sure to call it before destroying your application to make sure that all outstanding requests to be flushed.

=back

=head1 Net::Kafka::Message

This class maps to C<rd_kafka_message_t> structure from librdkafka and
represents message or event. Objects of this class have the following methods:

=over 4

=item err()

return error code from the message

=item topic()

return topic name

=item partition()

return partition number

=item offset()

return offset. Note, that the value is truncated to 32 bit if your perl doesn't
support 64 bit integers.

=item key()

return message key

=item payload()

return message payload

=item headers()

return a copy of message headers

=item detach_headers()

return message headers and removes them from the message

=back

=head1 Net::Kafka::Headers

This class contains a list of Kafka headers (it allows duplicates).
Objects of this class have the following methods:

=over 4

=item new()

create a new instance

=item add(name, value)

append a new name/value pair to the header list

=item remove(name)

remove all headers with the given name, if any

=item get_last(name)

return the last value associated with a given name

=item to_hash()

return an hash-of-arrays containing all headers

=back

=head1 Net::Kafka::Err

This class provides static methods to convert error codes into names
and descriptions.

=over 4

=item rd_kafka_get_err_descs()

    rd_kafka_get_err_descs()

returns a hash mapping error codes to description strings.

=item to_string()

    to_string($code)

return the description string for this error code.

=item to_name()

    to_name($code)

return the name of this error code.

=back

=head1 CAVEATS

Message offset is truncated to 32 bit if perl is compiled without support for 64 bit integers.

=head1 SEE ALSO

=over

=item *
L<https://github.com/edenhill/librdkafka>

=item *
L<https://github.com/trinitum/perl-Kafka-Librd>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016, 2017 Pavel Shaydo

Copyright (C) 2018, 2019 Booking.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
