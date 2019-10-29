package Net::Kafka::Consumer;

use strict;
use warnings;

use Net::Kafka qw/RD_KAFKA_CONSUMER/;
use Net::Kafka::Util;

use constant {
    DEFAULT_SEEK_TIMEOUT                => 1000,
    DEFAULT_FETCH_OFFSET_TIMEOUT        => 5000,
    DEFAULT_ERROR_CB                => sub {
        my ($self, $err, $msg) = @_;
        warn sprintf("WARNING: Net::Kafka::Consumer: %s (%s)", $msg, $err);
    },
};

sub new {
    my ($class, %args) = @_;
    my $rdkafka_version = Net::Kafka::rd_kafka_version();
    my $error_cb = delete $args{error_cb} // DEFAULT_ERROR_CB;
    my $config = Net::Kafka::Util::build_config({
        'error_cb'               => $error_cb,
        %args
    });
    my $kafka = delete $args{kafka} || Net::Kafka->new(RD_KAFKA_CONSUMER, $config);
    return bless {
        _kafka        => $kafka,
        _is_closed    => 0,
    }, $class;
}

sub subscribe {
    my ($self, $topics) = @_;
    $self->{_kafka}->subscribe($topics);
}

sub unsubscribe {
    my ($self) = @_;
    $self->{_kafka}->unsubscribe();
}

sub assign {
    my $self = shift;
    $self->{_kafka}->assign(@_);
}

sub poll {
    my $self = shift;
    return $self->{_kafka}->consumer_poll(@_);
}

sub committed {
    my ($self, $tp_list, $timeout_ms) = @_;
    $self->{_kafka}->committed($tp_list, $timeout_ms // DEFAULT_FETCH_OFFSET_TIMEOUT);
}

sub offsets_for_times {
    my ($self, $tp_list, $timeout_ms) = @_;
    $self->{_kafka}->offsets_for_times($tp_list, $timeout_ms // DEFAULT_FETCH_OFFSET_TIMEOUT);
}

sub query_watermark_offsets {
    my ($self, $topic, $partition, $timeout_ms) = @_;
    $self->{_kafka}->query_watermark_offsets($topic, $partition, $timeout_ms // DEFAULT_FETCH_OFFSET_TIMEOUT);
}

sub pause {
    my ($self, $tp_list) = @_;
    $self->{_kafka}->pause($tp_list);
}

sub position {
    my ($self, $tp_list) = @_;
    $self->{_kafka}->position($tp_list);
}

sub resume {
    my ($self, $tp_list) = @_;
    $self->{_kafka}->resume($tp_list);
}

sub subscription {
    my $self = shift;
    my $topics = [];
    my $subscription = $self->{_kafka}->subscription();
    for ( my $i=0; $i < $subscription->size(); $i++ ) {
        my ($t) = $subscription->get($i);
        push @$topics, $t;
    }
    return $topics;
}

sub partitions_for {
    my ($self, $topic, $timeout_ms) = @_;
    return $self->{_kafka}->partitions_for($topic, $timeout_ms);
}

sub commit {
    my ($self, $async, $topic_partitions) = @_;
    $async //= 0;
    $topic_partitions ?
        $self->{_kafka}->commit($async, $topic_partitions) :
        $self->{_kafka}->commit($async);
}

sub commit_message {
    my ($self, $async, $msg) = @_;
    $async //= 0;
    $self->{_kafka}->commit_message($async, $msg);
}

sub seek {
    my ($self, $topic, $partition, $offset, $timeout_ms) = @_;
    $timeout_ms //= DEFAULT_SEEK_TIMEOUT;
    $self->{_kafka}->topic($topic)->seek($partition, $offset, $timeout_ms);
}

sub close {
    my $self = shift;
    return if $self->{_is_closed};

    $self->{_kafka}->close() if defined $self->{_kafka};
    $self->{_is_closed} = 1;
}

sub DESTROY {
    my $self = shift;
    $self->close();
}

1;
