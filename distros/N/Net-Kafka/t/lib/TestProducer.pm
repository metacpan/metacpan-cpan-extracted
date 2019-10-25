package TestProducer;

use strict;
use warnings;

use Net::Kafka::Producer;

sub is_ok {
    return bootstrap_servers() && topic() && topic_partitions();
}

sub bootstrap_servers {
    return $ENV{KAFKA_BOOTSTRAP_SERVERS};
}

sub topic {
    return $ENV{KAFKA_TEST_TOPIC};
}

sub topic_partitions {
    return $ENV{KAFKA_TEST_TOPIC_PARTITIONS};
}

sub new {
    my ($class, %args) = @_;
    return Net::Kafka::Producer->new(
        'bootstrap.servers' => $args{'bootstrap.servers'} // bootstrap_servers(),
        %args
    );
}

1;
