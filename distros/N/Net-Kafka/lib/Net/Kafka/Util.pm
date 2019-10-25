package Net::Kafka::Util;

use strict;
use warnings;

use Net::Kafka qw/RD_KAFKA_TOPIC_CONFIG_KEYS/;

my $topic_config_key_lookup = { map { $_ => 1 } @{ +RD_KAFKA_TOPIC_CONFIG_KEYS } };

sub is_topic_config_key {
    my $key = shift;
    return exists $topic_config_key_lookup->{$key} ? 1 : 0;
}

sub build_config {
    my $args    = shift;
    my $config  = {};

    foreach my $key (keys %$args) {
        if (is_topic_config_key($key)) {
            $config->{default_topic_config}{$key} = $args->{$key};
        } else {
            $config->{$key} = $args->{$key};
        }
    }

    return $config;
}

1;
