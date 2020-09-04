package RxPerl::Operators::Pipeable;
use strict;
use warnings FATAL => 'all';

use RxPerl::Operators::Creation 'rx_observable', 'rx_subject';
use RxPerl::ConnectableObservable;
use RxPerl::Utils qw/ get_subscription_from_subscriber get_timer_subs /;
use RxPerl::Subscription;

use Carp 'croak';
use Scalar::Util 'reftype';

use Exporter 'import';
our @EXPORT_OK = qw/
    op_delay op_filter op_map op_map_to op_multicast op_pairwise op_ref_count
    op_scan op_share op_take op_take_until op_tap
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# TODO: are these op_delay comments still valid?
# Two bugs: 1) script doesn't exit upon the subscriber receiving complete, and 2) delaying of(1, 2, 3) often
# shows fewer than 3 'next' values and not in the right order.

sub op_delay {
    my ($delay) = @_;

    my ($timer_sub, $cancel_timer_sub) = get_timer_subs;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my %timers;
            my $queue;
            my $own_subscriber = {
                error => sub {
                    my @value = @_;
                    $subscriber->{error}->(@value) if defined $subscriber->{error};
                },
                map {
                    my $type = $_;

                    (
                        $type => sub {
                            my @value = @_;

                            if (! defined $queue) {
                                $queue = [];
                                my ($timer1, $timer2);
                                $timer1 = $timer_sub->(0, sub {
                                    delete $timers{$timer1};
                                    my @queue_copy = @$queue;
                                    undef $queue;
                                    $timer2 = $timer_sub->($delay, sub {
                                        delete $timers{$timer2};
                                        foreach my $item (@queue_copy) {
                                            my ($type, $value_ref) = @$item;
                                            $subscriber->{$type}->(@$value_ref) if defined $subscriber->{$type};
                                        }
                                    });
                                    $timers{$timer2} = $timer2;
                                });
                                $timers{$timer1} = $timer1;
                            }
                            push @$queue, [$type, \@value];
                        }
                    );
                } qw/ next complete /
            };

            return [
                $source->subscribe($own_subscriber),
                sub {
                    $cancel_timer_sub->($_) foreach values %timers;
                    %timers = ();
                },
            ];
        });
    };
}

sub op_filter {
    my ($filtering_sub) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = { %$subscriber };
            $own_subscriber->{next} &&= sub {
                my $passes = eval { $filtering_sub->(@_) };
                if (my $error = $@) {
                    $subscriber->{error}->($error);
                } else {
                    $subscriber->{next}->(@_) if $passes and defined $subscriber->{next};
                }
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_map {
    my ($mapping_sub) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = { %$subscriber };
            $own_subscriber->{next} &&= sub {
                my $result = eval { $mapping_sub->(@_) };
                if (my $error = $@) {
                    $subscriber->{error}->($error) if defined $subscriber->{error};
                } else {
                    $subscriber->{next}->($result) if defined $subscriber->{next};
                }
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_map_to {
    my ($mapping_value) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = { %$subscriber };
            $own_subscriber->{next} &&= sub {
                $subscriber->{next}->($mapping_value) if defined $subscriber->{next};
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_multicast {
    my ($subject_factory) = @_;

    return sub {
        my ($source) = @_;

        return RxPerl::ConnectableObservable->new($source, $subject_factory);
    };
}

sub op_pairwise {
    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $prev_value;
            my $have_prev_value = 0;

            my $own_subscriber = {
                %$subscriber,
                (
                    next => sub {
                        my ($value) = @_;

                        if ($have_prev_value) {
                            $subscriber->{next}->([$prev_value, $value]) if defined $subscriber->{next};
                        } else {
                            $have_prev_value = 1;
                        }

                        $prev_value = $value;
                    }
                ) x!! defined $subscriber->{next},
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_ref_count {
    return sub {
        my ($source) = @_;

        croak 'op_ref_count() was not applied to a connectable observable'
            unless $source->isa('RxPerl::ConnectableObservable');

        my $count = 0;

        my $connection_subscription;
        my $typical_unsubscription_fn = sub {
            if (--$count == 0) {
                $connection_subscription->unsubscribe;
            }
        };

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $count_was = $count++;

            if ($count_was == 0) {
                $connection_subscription = RxPerl::Subscription->new;

                get_subscription_from_subscriber($subscriber)->add_dependents($typical_unsubscription_fn);
                $source->subscribe($subscriber);

                $connection_subscription = $source->connect;
            } else {
                get_subscription_from_subscriber($subscriber)->add_dependents($typical_unsubscription_fn);
                $source->subscribe($subscriber);
            }

            return;
        });
    };
}

sub op_scan {
    my ($accumulator_function, $seed) = @_;
    my $has_seed = @_ >= 2;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $has_seed = $has_seed;

            my $acc; $acc = $seed if $has_seed;
            my $index = -1;
            my $own_subscriber = {
                %$subscriber,
                (
                    next => sub {
                        my ($value) = @_;

                        if (! $has_seed) {
                            $acc = $value;
                            $has_seed = 1;
                        } else {
                            ++$index;
                            $acc = $accumulator_function->($acc, $value, $index);
                        }

                        $subscriber->{next}->($acc) if defined $subscriber->{next};
                    },
                ) x!! defined $subscriber->{next},
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_share {
    return (
        op_multicast(sub { rx_subject->new }),
        op_ref_count(),
    );
}

sub op_take {
    my ($count) = @_;

    croak 'negative argument passed to op_take' unless $count >= 0;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $remaining = int $count;

            if ($remaining == 0) {
                $subscriber->{complete}->() if defined $subscriber->{complete};
                return;
            }

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                    $subscriber->{complete}->() if --$remaining == 0 and defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_take_until {
    my ($notifier_observable) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $n_s = $notifier_observable->subscribe(
                sub {
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
                sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
            );

            $source->subscribe($subscriber);

            return $n_s;
        });
    };
}

sub op_tap {
    my @args = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @args = @args;
            my $tap_subscriber = $args[0] if (reftype($args[0]) // '') eq 'HASH';
            $tap_subscriber //= {
                map {($_, shift @args)} qw/ next error complete /
            };

            my %own_keys = map {$_ => 1} grep { /^(next|error|complete)\z/ } (keys(%$tap_subscriber), keys(%$subscriber));

            my $own_subscriber = {
                %$subscriber,
                map {
                    my $key = $_;
                    ($key => sub {
                        $tap_subscriber->{$key}->(@_) if defined $tap_subscriber->{$key};
                        $subscriber->{$key}->(@_) if defined $subscriber->{$key};
                    });
                } keys %own_keys
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

1;
