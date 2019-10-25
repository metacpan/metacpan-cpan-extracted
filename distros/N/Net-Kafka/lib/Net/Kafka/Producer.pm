package Net::Kafka::Producer;

use strict;
use warnings;

use POSIX;
use IO::Handle;
use Net::Kafka qw/
    RD_KAFKA_PRODUCER
    RD_KAFKA_PARTITION_UA
    RD_KAFKA_EVENT_DR
    RD_KAFKA_EVENT_NONE
    RD_KAFKA_EVENT_STATS
    RD_KAFKA_EVENT_ERROR
/;
use Net::Kafka::Util;
use AnyEvent::XSPromises qw/deferred/;
use Scalar::Util qw/weaken/;
use AnyEvent;

use constant {
    DEFAULT_ACKS                    => 1,
    DEFAULT_ERROR_CB                => sub {
        my ($self, $err, $msg) = @_;
        warn sprintf("WARNING: Net::Kafka::Producer: %s (%s)", $msg, $err);
    },
};

sub new {
    my ($class, %args)  = @_;
    my $rdkafka_version = Net::Kafka::rd_kafka_version();

    pipe my $r, my $w or die "could not create a signalq pipe: $!";
    $r->autoflush(1);
    $w->autoflush(1);
    my $error_cb    = delete $args{error_cb} // DEFAULT_ERROR_CB;
    my $stats_cb    = delete $args{stats_cb};
    my $config      = Net::Kafka::Util::build_config({
        'acks'      => DEFAULT_ACKS,
        'queue_fd'  => $w->fileno,
        %args
    });
    my $kafka       = delete $args{kafka} || Net::Kafka->new(RD_KAFKA_PRODUCER, $config);
    my $self        = bless {
        _kafka           => $kafka,
        _max_id          => 0,
        _in_flight       => {},
        _read_queue_fd   => $r,
        _write_queue_fd  => $w,
        _error_cb        => $error_cb,
        _stats_cb        => $stats_cb,
        _topics          => {},
        _watcher         => undef,
        _is_closed       => 0,
    }, $class;
    $self->_setup_signal_watcher();
    $self->_process_events(); # process existing events in the queue
    return $self;
}

sub _setup_signal_watcher {
    my $self = shift;
    weaken(my $self_ = $self);
    $self->{_watcher} = AnyEvent->io(
        fh      => $self_->{_read_queue_fd},
        poll    => "r",
        cb      => sub { $self_->_signal_watcher_cb() }
    );
}

sub _signal_watcher_cb {
    my $self = shift;
    return if $self->{_is_closed};

    my $signals_count = sysread $self->{_read_queue_fd}, my $signal, 1;
    if (! defined $signals_count) {
        $! == EAGAIN and return;
        warn "sysread failed: $!";
    } else {
        $self->_process_events();
    }
}

sub _process_events {
    my $self = shift;
    while (my $event = $self->{_kafka}->queue_poll()) {
        if (! defined $event) {
            warn sprintf "ERROR: empty event received";
            next;
        }
        my $event_type = $event->event_type();
        if ($event_type == RD_KAFKA_EVENT_NONE) {
            # do nothing
        } elsif ($event_type == RD_KAFKA_EVENT_DR) {
            $self->_process_event_delivery_reports($event);
        } elsif ($event_type == RD_KAFKA_EVENT_STATS) {
            $self->_process_event_stats($event);
        } elsif ($event_type == RD_KAFKA_EVENT_ERROR) {
            $self->_process_event_error($event);
        } else {
            warn sprintf "ERROR: unknown event type %s received", $event_type;
        }
    }
}

sub _process_event_error {
    my ($self, $event) = @_;
	my $err     = $event->event_error();
    my $err_msg = $event->event_error_string();
 
    $self->{_error_cb}->( $self, $err, $err_msg )
        if defined $self->{_error_cb};
}

sub _process_event_stats {
    my ($self, $event) = @_;
    my $stats = $event->event_stats();
    $self->{_stats_cb}->( $self, $stats )
        if defined $self->{_stats_cb};
}

sub _process_event_delivery_reports {
    my ($self, $event) = @_;
    while (my $report = $event->event_delivery_report_next()) {
        my $msg_id = $report->{msg_id};
        if (exists $report->{err}) {
            $self->_reject_deferred($msg_id, {
                error      => $report->{err_msg},
                error_code => $report->{err},
            });
        } else {
            $self->_resolve_deferred($msg_id, {
                offset    => $report->{offset},
                partition => $report->{partition},
                timestamp => $report->{timestamp},
            });
        }
    }
}

sub produce {
    my ($self, %args) = @_;
    $self->_check_if_closed();

    my $topic_name  = $args{topic} or die 'topic name is required';
    my $partition   = $args{partition} // RD_KAFKA_PARTITION_UA;
    my $timestamp   = $args{timestamp} // 0;
    my $key         = $args{key};
    my $payload     = $args{payload};
    my $headers     = $args{headers};

    my $d           = deferred;
    my $topic       = $self->_topic($topic_name);
    my $msg_id      = $self->_register_deferred($d, \%args);

    eval {
        $topic->produce(
            $partition,
            $key,
            $payload,
            $timestamp,
            $msg_id,
            0,
            $headers,
        );
        1;
    } or do {
        my $err = $@ || "Zombie Error";
        $self->_reject_deferred($msg_id, {
            error      => $err,
            error_code => Net::Kafka::Error::last_error(),
        });
    };

    return $d->promise;
}

sub _topic {
    my ($self, $topic_name) = @_;
    $self->_check_if_closed();

    return $self->{_topics}{$topic_name}
        if exists $self->{_topics}{$topic_name};

    my $topic = $self->{_kafka}->topic($topic_name);
    $self->{_topics}{$topic_name} = $topic;
    return $topic;
}

sub _register_deferred {
    my ($self, $deferred, $args) = @_;
    my $id = $self->{_max_id} + 1;
    $self->{_max_id} = $id;
    $self->{_in_flight}{$id} = {
        deferred => $deferred,
        args     => $args,
    };
    return $id;
}

sub _resolve_deferred {
    my ($self, $msg_id, $data) = @_;
    my $msg     = delete $self->{_in_flight}{$msg_id} or die "Cannot find an in-flight deferred with id $msg_id";
    my $d       = $msg->{deferred};
    my $args    = $msg->{args};
    $d->resolve({ %$args, %$data });
}

sub _reject_deferred {
    my ($self, $msg_id, $data) = @_;
    my $msg     = delete $self->{_in_flight}{$msg_id} or die "Cannot find an in-flight deferred with id $msg_id";
    my $d       = $msg->{deferred};
    my $args    = $msg->{args};
    $d->reject({ %$args, %$data });
}

sub _reject_all_deferred {
    my ($self, $data) = @_;
    my @msg_ids = keys %{ $self->{_in_flight} };
    $self->_reject_deferred($_, $data) foreach @msg_ids;
}

sub partitions_for {
    my ($self, $topic, $timeout_ms) = @_;
    $self->_check_if_closed();
    return $self->{_kafka}->partitions_for($topic, $timeout_ms);
}

sub _check_if_closed {
    my $self = shift;
    die "Producer is closed" if $self->{_is_closed};
}

sub close {
    my $self = shift;
    return if $self->{_is_closed};

    $self->{_topics} = {}; # avoid use-after-free errors from topic destruction
    $self->{_kafka}->close() if defined $self->{_kafka};

    $self->{_watcher} = undef;
    close $self->{_read_queue_fd};
    close $self->{_write_queue_fd};

    $self->{_is_closed} = 1;
}

sub DESTROY {
    my $self = shift;
    $self->close();
}

1;
