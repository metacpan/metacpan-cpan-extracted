#!perl

use strict;
use warnings;

use File::Basename; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestConsumer;
use TestProducer;
use AnyEvent;
use AnyEvent::XSPromises qw/collect/;
use Data::Dumper qw/Dumper/;
use Net::Kafka qw/
    RD_KAFKA_RESP_ERR__PARTITION_EOF
    RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS
    RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS
    RD_KAFKA_RESP_ERR_NO_ERROR
    RD_KAFKA_OFFSET_END
    RD_KAFKA_OFFSET_BEGINNING
/;

use constant BATCH_SIZE => 10;
use constant TIMEOUT    => 30; # 30 seconds

plan skip_all => "Missing Kafka test environment" unless TestConsumer->is_ok;

my $producer = TestProducer->new();
my $test_id  = TestConsumer::group_prefix() . time();
diag($test_id);

# Produce BATCH_SIZE messages into test topic and return delivery report map
# per partition like:
#
# {
#   0 => {
#       reports => {
#           77544 => { ... },
#           77545 => { ... },
#           77546 => { ... },
#       },
#       min_offset => 77544,
#       max_offset => 77546,
#   },
#   1 => {
#       ...
#   }
# }
#
#
sub produce {
    my %args        = @_;
    my $condvar     = AnyEvent->condvar;
    my $result      = {};
    my @promises    = ();

    for (my $i = 0; $i < BATCH_SIZE; $i++) {
        push @promises => $producer->produce(
            topic   => TestConsumer::topic,
            payload => $args{payload},
            ( defined $args{partition} ? ( partition => $args{partition} ) : () ),
            ( defined $args{headers} ? ( headers => $args{headers} ) : () ),
        )->then(sub {
            my $dr = shift;
            $result->{ $dr->{partition} }{reports}{ $dr->{offset} } = $dr;
            $result->{ $dr->{partition} }{min_offset} = $dr->{offset}
                if ! defined $result->{ $dr->{partition} }{min_offset} ||
                     $dr->{offset} < $result->{ $dr->{partition} }{min_offset};
            $result->{ $dr->{partition} }{max_offset} = $dr->{offset}
                if ! defined $result->{ $dr->{partition} }{max_offset} ||
                     $dr->{offset} > $result->{ $dr->{partition} }{max_offset};
        });
    }

    collect(@promises)->then(sub {
        $condvar->send;
    })->catch(sub {
        ok(0) or diag(@_);
        $condvar->send;
    });
    $condvar->recv;

    return $result;
}

# Consume a batch of messages produce by "produce" method
# and check their sanity
sub consume {
    my ($consumer, $group_id, $messages, $test) = @_;

    my $start_time = time();
    my $consumed   = 0;
    my @received;

    while(1) {
        if (time() - $start_time > TIMEOUT) {
            ok(0, "timeout reading messages from topic: $test");
            last;
        }
        my $message = $consumer->poll(100);
        next unless $message;
        if ( $message->err ) {
            is ( $message->err, RD_KAFKA_RESP_ERR__PARTITION_EOF );
        } else {
            next unless $message->payload;
            next unless $message->payload eq $group_id;
            is( $message->topic, TestConsumer::topic );
            like($message->offset, qr/\d+/);
            like($message->partition, qr/\d+/);
            ok(0, "unexpected message consumed")
                unless exists $messages->{ $message->partition }{ reports }{ $message->offset };
            $consumed++;
            push @received, $message;
        }

        last if $consumed == BATCH_SIZE;
    }

    return @received;
}

subtest 'Position' => sub {
    my $group_id = sprintf("%s__position", $test_id);
    my $consumer = TestConsumer->new(
        'group.id' => $group_id
    );
    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add(TestConsumer::topic, 0);
    $tp_list->set_offset(TestConsumer::topic, 0, RD_KAFKA_OFFSET_BEGINNING);
    $consumer->assign($tp_list);

    my $start_time = time();
    while (1) {
        if (time() - $start_time > TIMEOUT) {
            ok(0, "timeout reading messages before finding the position");
            last;
        }
        my $message = $consumer->poll();
        next unless $message;
        next if $message->err;

        my $offset = $message->offset;
        my $position_list = Net::Kafka::TopicPartitionList->new();
        $position_list->add(TestConsumer::topic, 0);
        $consumer->position($position_list);
        my $position = $position_list->offset(TestConsumer::topic, 0);

        like($position, qr/\d+/);
        is($position, $offset + 1);
        last;
    }
};

subtest 'Query Watermark Offsets' => sub {
    my $consumer = TestConsumer->new();
    my @offsets = $consumer->query_watermark_offsets( TestConsumer::topic, 0 );
    is(scalar(@offsets), 2);
    like($offsets[0], qr/\d+/);
    like($offsets[1], qr/\d+/);
    ok($offsets[0] <= $offsets[1]);
};

subtest 'Commit w/o local offset stored' => sub {
    my $consumer = TestConsumer->new(
        'group.id' => $test_id
    );
    eval {
        $consumer->commit();
        ok(1);
        1;
    } or do {
        ok(0) or diag($@);
    };
};

subtest 'Partitions For' => sub { 
    my $consumer = TestConsumer->new();
    my $partitions = $consumer->partitions_for( TestConsumer::topic );
    isa_ok($partitions, 'ARRAY');
    is (scalar(@$partitions), TestConsumer::topic_partitions, "fetch partitions info");
};

subtest 'Partitions For (missing topic)' => sub {
    my $consumer = TestConsumer->new();
    eval {
        my $partitions = $consumer->partitions_for( 'non-existing-topic-name' );
        ok(0);
        1;
    } or do {
        ok(1);
    };
};

subtest 'Consumer Error Callback' => sub {
    my $group_id = sprintf("%s__error", $test_id);
    my $error_cb_called = 0;
    my $consumer = TestConsumer->new(
        'group.id'          => $group_id,
        'bootstrap.servers' => 'localhost:1234',
        'error_cb'          => sub {
            my $self = shift;
            $error_cb_called = 1;
        },
    );
    my $start_time = time();
    while ($error_cb_called != 1) {
        last if time() - $start_time > TIMEOUT;
        $consumer->poll();
    }
    ok($error_cb_called, 'Error callback called');
    $consumer->close();
};

subtest 'Consumer Stats Callback' => sub {
    my $group_id = sprintf("%s__error", $test_id);
    my $stats_cb_called = 0;
    my $stats_cb_received_json = 0;
    my $consumer = TestConsumer->new(
        'group.id'               => $group_id,
        'statistics.interval.ms' => 1,
        'stats_cb'               => sub {
            my $self = shift;
            my $json = shift;
            $stats_cb_called = 1;
            $stats_cb_received_json = $json =~ m/^{.*}$/;
        },
    );
    my $start_time = time();
    while ($stats_cb_called != 1) {
        last if time() - $start_time > TIMEOUT;
        $consumer->poll();
    }
    ok($stats_cb_called, 'Stats callback called');
    ok($stats_cb_received_json, 'Stats callback received_json');
    $consumer->close();
};

subtest 'Distributed Consumer' => sub {
    my $group_id = sprintf("%s__distributed", $test_id);

    my $messages = produce( payload => $group_id );
    my $consumer = TestConsumer->new(
        'group.id'          => $group_id,
        'offset_commit_cb'  => sub {
            my ( $self, $err, $tp_list ) = @_;
            is( $err, RD_KAFKA_RESP_ERR_NO_ERROR, "commit callback unexpected err $err" );
        },
        # When rebalance is finished make sure to seek offsets to the ones
        # that are produced by "produce" call above
        'rebalance_cb'      => sub {
            my ( $self, $err, $tp_list ) = @_;
            if ( $err == RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS ) {
                is( $tp_list->size, TestConsumer::topic_partitions );
                foreach my $partition ( keys %$messages ) {
                    like($tp_list->offset( TestConsumer::topic, $partition ), qr/\d+/);
                    $tp_list->set_offset( TestConsumer::topic, $partition, $messages->{$partition}{min_offset} );
                }
                $self->assign( $tp_list );
            } elsif ( $err == RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS ) {
                $self->assign();
            } else {
                ok(0, "rebalance cb unexpected err $err");
            }
        },
    );

    # Sub
    $consumer->subscribe([ TestConsumer::topic ]);

    # Check our current subscription
    my $subscription = $consumer->subscription();
    isa_ok( $subscription, 'ARRAY' );
    is( scalar(@$subscription), 1, "subscription info size" );
    is( $subscription->[0], TestConsumer::topic );

    # Consume produced messages
    consume($consumer, $group_id, $messages, "consuming from assigned partitions");

    # Unsub
    $consumer->unsubscribe();
    $consumer->close();
};

subtest 'Simple Consumer' => sub {
    my $group_id = sprintf("%s__simple", $test_id);

    # Produce message into partition "0"
    my $messages = produce( payload => $group_id, partition => 0 );
    my $consumer = TestConsumer->new(
        'enable.auto.commit' => 'false', # Disable autocommit
        'group.id'           => $group_id,
    );

    # Generate custom partition assignment and set offset to a min offset
    # produced by "produce" call above, we are only listening to partition "0"
    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add( TestConsumer::topic, 0 );
    $tp_list->set_offset( TestConsumer::topic, 0, $messages->{ 0 }{ min_offset } );
    is( $tp_list->size(), 1 );
    isnt( $messages->{ 0 }{ min_offset }, $messages->{ 0 }{ max_offset } );
    $consumer->assign($tp_list);
 
    # Consume messages
    consume($consumer, $group_id, $messages, "consuming from partition 0 for the first time");

    # Commit consumed messages
    $consumer->commit();

    # Check what is actually committed
    $consumer->committed($tp_list);
    is( $tp_list->offset(TestConsumer::topic, 0), $messages->{0}{max_offset} + 1 );

    # Seek to the first offset
    $consumer->seek( TestConsumer::topic, 0, $messages->{0}{min_offset} );

    # Consume messages once again
    consume($consumer, $group_id, $messages, "consuming from partition 0 after manual seek");

    # Close consumer cleanly
    $consumer->close();
};

subtest 'Consume headers' => sub {
    my $group_id = sprintf("%s__simple", $test_id);

    my $headers = Net::Kafka::Headers->new();
    $headers->add('head', 'tail');

    # Produce message into partition "0"
    my $messages = produce( payload => $group_id, partition => 0, headers => $headers );
    my $consumer = TestConsumer->new(
        'enable.auto.commit' => 'false', # Disable autocommit
        'group.id'           => $group_id,
    );

    # Generate custom partition assignment and set offset to a min offset
    # produced by "produce" call above, we are only listening to partition "0"
    my $tp_list = Net::Kafka::TopicPartitionList->new();
    $tp_list->add( TestConsumer::topic, 0 );
    $tp_list->set_offset( TestConsumer::topic, 0, $messages->{ 0 }{ min_offset } );
    is( $tp_list->size(), 1 );
    isnt( $messages->{ 0 }{ min_offset }, $messages->{ 0 }{ max_offset } );
    $consumer->assign($tp_list);

    # Consume messages
    my @messages = consume($consumer, $group_id, $messages, "consuming from partition 0 for the first time");

    is(scalar @messages, BATCH_SIZE);
    my $received_message = $messages[0];

    # headers can be retrieved multiple times
    {
        my $received_headers = $received_message->headers();
        isa_ok($received_headers, 'Net::Kafka::Headers');
        is($received_headers->get_last('head'), 'tail');
    }

    {
        my $received_headers = $received_message->headers();
        isa_ok($received_headers, 'Net::Kafka::Headers');
        is($received_headers->get_last('head'), 'tail');
    }

    # headers can be retrieved multiple times (they are recreated transparently after detach)
    {
        my $received_headers = $received_message->detach_headers();
        isa_ok($received_headers, 'Net::Kafka::Headers');
        is($received_headers->get_last('head'), 'tail');
    }

    {
        my $received_headers = $received_message->detach_headers();
        isa_ok($received_headers, 'Net::Kafka::Headers');
        is($received_headers->get_last('head'), 'tail');
    }
};

subtest 'Close consumer' => sub {
    my $consumer = TestConsumer->new();
    eval {
        $consumer->close();
        ok(1);
        1;
    } or do {
        ok(0) or diag($@);
    };
};

done_testing();
