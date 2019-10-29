#!perl

use strict;
use warnings;

use File::Basename; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestProducer;
use AnyEvent;
use AnyEvent::XSPromises qw/collect/;
use Data::Dumper qw/Dumper/;

plan skip_all => "Missing Kafka test environment" unless TestProducer->is_ok;

subtest 'Partitions For' => sub { 
    my $producer = TestProducer->new();
    my $partitions = $producer->partitions_for( TestProducer::topic );
    isa_ok($partitions, 'ARRAY');
    is (scalar(@$partitions), TestProducer::topic_partitions(), "fetch partitions info");
};

subtest 'Partitions For (missing topic)' => sub {
    my $producer = TestProducer->new();
    eval {
        my $partitions = $producer->partitions_for( 'non-existing-topic-name' );
        ok(0);
        1;
    } or do {
        ok(1);
    };
};

subtest 'Producer Error Callback' => sub {
    my $error_cb_called = 0;
    my $producer = TestProducer->new(
        'bootstrap.servers' => 'localhost:1234',
        'message.timeout.ms' => 1000,
        error_cb => sub {
            my ($self, $err, $msg) = @_;
            $error_cb_called = 1;
        },
    );
    my $condvar = AnyEvent->condvar;
    $producer->produce(
        topic => TestProducer::topic,
        payload => "test"
    )->then(sub {
        ok(0);
    })->catch(sub {
        ok(1);
    })->finally(sub {
        $condvar->send;
    });
    $condvar->recv;
    ok($error_cb_called);
};

subtest 'Producer Stats Callback' => sub {
    my $stats_cb_called = 0;
    my $stats_cb_received_json = 0;
    my $producer = TestProducer->new(
        'statistics.interval.ms' => 1,
        'stats_cb'               => sub {
            my $self = shift;
            my $json = shift;
            $stats_cb_called++;
            $stats_cb_received_json = $json =~ m/^{.*}$/;
        },
    );
    for (my $i = 0; $i < 10; $i++) {
        my $condvar = AnyEvent->condvar;
        $producer->produce(
            topic => TestProducer::topic,
            payload => "test"
        )->then(sub {
            ok(1);
        })->catch(sub {
            ok(0);
        })->finally(sub {
            $condvar->send;
        });
        $condvar->recv;
    }
    ok($stats_cb_called, 'Stats callback called');
    ok($stats_cb_called > 1, 'Stats callback called more than once');
    ok($stats_cb_received_json, 'Stats callback received_json');
};

subtest 'Close producer' => sub {
    my $producer = TestProducer->new();
    eval {
        $producer->close();
        ok(1);
        1;
    } or do {
        ok(0) or diag($@);
    };
};

subtest 'Produce' => sub {
    my $producer = TestProducer->new();
    my $condvar  = AnyEvent->condvar;

    $producer->produce(
        topic => TestProducer::topic,
        key   => "test_key",
        payload => "test_payload",
    )->then(sub {
        my $dr = shift;
        $condvar->send;
        isa_ok($dr, 'HASH');
        is($dr->{topic}, TestProducer::topic);
        like($dr->{partition}, qr/\d+/);
        like($dr->{timestamp}, qr/\d+/);
        like($dr->{offset}, qr/\d+/);
        is($dr->{payload}, "test_payload");
        is($dr->{key}, "test_key");
    })->catch(sub {
        my $dr = shift;
        $condvar->send;
        ok(0) or diag($dr->{error});
    });

    $condvar->recv;
};

subtest 'Produce 100 items' => sub {
    my $producer = TestProducer->new();
    my $condvar  = AnyEvent->condvar;

    my $count = 0;
    my @promises = ();

    for (my $i = 0; $i < 100; $i++) {
        push @promises => $producer->produce(
            topic => TestProducer::topic,
            payload => "test_payload",
        )->then(sub {
            my $dr = shift;
            like($dr->{offset}, qr/\d+/);
            $count++;
        })->catch(sub {
            my $dr = shift;
            ok(0) or diag($dr->{error});
        });
    }

    collect(@promises)->then(sub {
        $condvar->send;
    })->catch(sub {
        $condvar->send;
    });

    $condvar->recv;
    is($count, 100);
};

subtest 'Produce NULL payload (tombstone)' => sub {
    my $producer = TestProducer->new();
    my $condvar  = AnyEvent->condvar;

    $producer->produce(
        topic => TestProducer::topic,
        key   => "test_key",
    )->then(sub {
        my $dr = shift;
        $condvar->send;
        like($dr->{offset}, qr/\d+/);
        is($dr->{payload}, undef);
        is($dr->{key}, "test_key");
    })->catch(sub {
        my $dr = shift;
        $condvar->send;
        ok(0) or diag($dr->{error});
    });

    $condvar->recv;
};

subtest 'Produce w/o args' => sub {
    my $producer = TestProducer->new();
    eval {
        $producer->produce();
        ok(0, "Produced w/o necessary arguments");
        1;
    } or do {
        ok(1);
    };
};

subtest 'Produce wrong args' => sub {
    my $producer = TestProducer->new();
    my $condvar  = AnyEvent->condvar;

    $producer->produce(
        topic     => TestProducer::topic,
        payload     => "test_payload",
        partition => -100,
    )->then(sub {
        my $dr = shift;
        $condvar->send;
        ok(0, "Produced into unknown partition");
    })->catch(sub {
        my $dr = shift;
        $condvar->send;
        is($dr->{error_code}, -190);
        like($dr->{error}, qr/Unknown partition/);
    });

    $condvar->recv;
};

done_testing();
