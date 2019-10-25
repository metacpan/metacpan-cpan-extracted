package TestConsumer;

use strict;
use warnings;

use Net::Kafka::Consumer;

sub is_ok {
    return bootstrap_servers() && topic() && topic_partitions() && group_prefix();
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

sub group_prefix {
    return $ENV{KAFKA_CONSUMER_GROUP_PREFIX};
}

sub new {
    my ($class, %args) = @_;
    return Net::Kafka::Consumer->new(
        'bootstrap.servers' => $args{'bootstrap.servers'} // bootstrap_servers(),
        %args
    );
}

1;
