package RxPerl::Operators::Pipeable;
use strict;
use warnings;

use RxPerl::Operators::Creation qw/ rx_observable rx_subject rx_concat rx_of rx_interval /;
use RxPerl::ConnectableObservable;
use RxPerl::Utils qw/ get_timer_subs /;
use RxPerl::Subscription;

use Carp 'croak';
use Scalar::Util 'reftype', 'refaddr', 'blessed', 'weaken';

use Exporter 'import';
our @EXPORT_OK = qw/
    op_audit_time op_buffer_count op_catch_error op_concat_map op_debounce_time op_delay op_distinct_until_changed
    op_distinct_until_key_changed op_end_with op_exhaust_map op_filter op_finalize op_first op_map op_map_to
    op_merge_map op_multicast op_pairwise op_pluck op_ref_count op_repeat op_retry op_sample_time op_scan
    op_share op_skip op_skip_until op_start_with op_switch_map op_take op_take_until op_take_while op_tap
    op_throttle_time op_with_latest_from
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v6.10.1";

sub op_audit_time {
    my ($duration) = @_;

    my ($timer_sub, $cancel_timer_sub) = get_timer_subs;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $id;
            my $in_audit = 0;
            my @last_value;

            $subscriber->subscription->add(
                sub { $cancel_timer_sub->($id) },
            );

            $source->subscribe({
                %$subscriber,
                next => sub {
                    @last_value = @_;

                    if (! $in_audit) {
                        $in_audit = 1;
                        $id = $timer_sub->($duration, sub {
                            $in_audit = 0;
                            $subscriber->{next}->(@last_value) if defined $subscriber->{next};
                        });
                    }
                },
            });
        });
    };
}

sub op_buffer_count {
    my ($buffer_size, $start_buffer_every) = @_;

    $start_buffer_every //= $buffer_size;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @buffers;
            my $count = 0;
            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($value) = @_;

                    if ($count++ % $start_buffer_every == 0) {
                        push @buffers, [];
                    }

                    for (my $i = 0; $i < @buffers; $i++) {
                        my $buffer = $buffers[$i];

                        push @$buffer, $value;

                        if (@$buffer == $buffer_size) {
                            $subscriber->{next}->($buffer) if defined $subscriber->{next};
                            splice @buffers, $i, 1;
                            $i--;
                            next;
                        }
                    }
                },
                complete => sub {
                    if (defined $subscriber->{next}) {
                        $subscriber->{next}->($_) foreach @buffers;
                    }

                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub _op_catch_error_helper {
    my ($source, $selector, $subscriber, $dependents, $error) = @_;

    my $new_observable;
    if (@_ == 4) {
        $new_observable = $source;
    } else {
        eval { $new_observable = $selector->($error, $source) };
        if (my $e = $@) {
            $subscriber->{error}->($e) if defined $subscriber->{error};
            return;
        }
    }

    my $own_subscription = RxPerl::Subscription->new;
    @$dependents = ($own_subscription);
    my $own_subscriber = {
        new_subscription => $own_subscription,
        next     => $subscriber->{next},
        error    => sub {
            _op_catch_error_helper($source, $selector, $subscriber, $dependents, $_[0]);
        },
        complete => $subscriber->{complete},
    };

    $new_observable->subscribe($own_subscriber);
}

sub op_catch_error {
    my ($selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $dependents = [];
            $subscriber->subscription->add($dependents);

            _op_catch_error_helper(
                $source, $selector, $subscriber, $dependents,
            );

            return;
        });
    };
}

sub _op_concat_map_helper {
    my (
        $value, $inner_subscriptions, $observable_factory,
        $subscriber, $queue, $own_subscription
    ) = @_;

    if (@$inner_subscriptions and ! $inner_subscriptions->[0]{closed}) {
        push @$queue, $value;
        return;
    }

    my $inner_observable = $observable_factory->($value);

    @$inner_subscriptions = (RxPerl::Subscription->new);
    $inner_observable->subscribe({
        new_subscription => $inner_subscriptions->[0],
        next     => $subscriber->{next},
        error    => $subscriber->{error},
        complete => sub {
            @$inner_subscriptions = ();
            if (@$queue) {
                my $new_value = shift @$queue;
                _op_concat_map_helper(
                    $new_value, $inner_subscriptions, $observable_factory,
                    $subscriber, $queue, $own_subscription,
                );
            } else {
                if ($own_subscription->{closed}) {
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                }
            }
        },
    });
}

sub op_concat_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @inner_subscriptions;
            my @queue;

            my $own_subscription = RxPerl::Subscription->new;
            my $own_subscriber = {
                new_subscription => $own_subscription,
                next             => sub {
                    my ($value) = @_;

                    _op_concat_map_helper(
                        $value, \@inner_subscriptions, $observable_factory,
                        $subscriber, \@queue, $own_subscription
                    );
                },
                error            => $subscriber->{error},
                complete         => sub {
                    if (! @inner_subscriptions) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return ($own_subscription, \@inner_subscriptions);
        });
    };
}

my $_debounce_empty = {};

sub op_debounce_time {
    my ($due_time) = @_;

    my ($timer_sub, $cancel_timer_sub) = get_timer_subs;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @value_to_emit;
            my $id;

            my $own_subscription = RxPerl::Subscription->new;
            my $own_observer = {
                new_subscription => $own_subscription,
                next     => sub {
                    my @value = @_;

                    @value_to_emit = @value ? @value : $_debounce_empty;

                    $cancel_timer_sub->($id);
                    $id = $timer_sub->($due_time, sub {
                        undef @value_to_emit;
                        $subscriber->{next}->(@value) if defined $subscriber->{next};
                    });
                },
                error    => sub {
                    $cancel_timer_sub->($id);
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    if (@value_to_emit) {
                        $cancel_timer_sub->($id);
                        @value_to_emit = () if _eqq($value_to_emit[0], $_debounce_empty);
                        $subscriber->{next}->(@value_to_emit);
                    }
                    $subscriber->{complete}->();
                },
            };

            $source->subscribe($own_observer);

            return ($own_subscription, sub { $cancel_timer_sub->($id) });
        });
    }
}

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

sub op_distinct_until_changed {
    my ($comparison_function) = @_;

    $comparison_function //= \&_eqq;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $prev_value;
            my $have_prev_value = 0;

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my @value = @_;

                    if (! $have_prev_value or ! $comparison_function->($prev_value, $value[0])) {
                        $subscriber->{next}->(@value) if defined $subscriber->{next};
                        $have_prev_value = 1;
                        $prev_value = $value[0];
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_distinct_until_key_changed {
    my ($key) = @_;

    return op_distinct_until_changed(sub {
        _eqq($_[0]->{$key}, $_[1]->{$key});
    }),
}

sub op_end_with {
    my (@values) = @_;

    return sub {
        my ($source) = @_;

        return rx_concat(
            $source,
            rx_of(@values),
        );
    }
}

sub op_exhaust_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $inner_subscription;
            my $own_subscription = RxPerl::Subscription->new;
            my $own_observer = {
                new_subscription => $own_subscription,
                next             => sub {
                    my ($value) = @_;

                    if (!$inner_subscription or $inner_subscription->{closed}) {
                        my $inner_observable = $observable_factory->($value);
                        $inner_subscription = RxPerl::Subscription->new;
                        my $inner_observer = {
                            new_subscription => $inner_subscription,
                            next             => $subscriber->{next},
                            error            => $subscriber->{error},
                            complete         => sub {
                                if ($own_subscription->{closed}) {
                                    $subscriber->{complete}->() if defined $subscriber->{complete};
                                }
                            },
                        };
                        $inner_observable->subscribe($inner_observer);
                    }
                },
                error            => $subscriber->{error},
                complete         => sub {
                    if (! $inner_subscription or $inner_subscription->{closed}) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };

            $source->subscribe($own_observer);

            return ($own_subscription, \$inner_subscription);
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
            my $idx = 0;
            $own_subscriber->{next} &&= sub {
                my ($value) = @_;
                my $passes = eval { $filtering_sub->($value, $idx++) };
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

sub op_finalize {
    my ($fn) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $arr = $subscriber->{_subscription}{_finalize_cbs} //= [];
            unshift @$arr, $fn;
            $subscriber->{_subscription}->add( $arr );

            $source->subscribe($subscriber);

            return;
        });
    };
}

sub op_first {
    my ($condition) = @_;

    return sub {
        my ($source) = @_;

        my @pipes = (op_take(1));
        unshift @pipes, op_filter($condition) if defined $condition;

        return $source->pipe(@pipes);
    };
}

sub op_map {
    my ($mapping_sub) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = { %$subscriber };
            my $idx = 0;
            $own_subscriber->{next} &&= sub {
                my ($value) = @_;
                my $result = eval { $mapping_sub->($value, $idx++) };
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

sub op_merge_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $subscription = $subscriber->subscription;

            my %these_subscriptions;
            my $own_subscription = RxPerl::Subscription->new;

            $subscription->add(\%these_subscriptions, $own_subscription);

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next     => sub {
                    my ($value) = @_;

                    my $this_subscription = RxPerl::Subscription->new;
                    $these_subscriptions{$this_subscription} = $this_subscription;

                    my $this_new_subscriber = {
                        new_subscription => $this_subscription,
                        next     => sub {
                            $subscriber->{next}->(@_) if defined $subscriber->{next};
                        },
                        error    => sub {
                            $subscriber->{error}->(@_) if defined $subscriber->{error};
                        },
                        complete => sub {
                            delete $these_subscriptions{$this_subscription};
                            $subscriber->{complete}->() if !%these_subscriptions and $own_subscription->{closed}
                                and defined $subscriber->{complete};
                        },
                    };

                    my $this_observable = $observable_factory->($value);
                    $this_observable->subscribe($this_new_subscriber);
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    $subscriber->{complete}->() if !%these_subscriptions and defined $subscriber->{complete};
                },
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

sub op_pluck {
    my (@keys) = @_;

    croak 'List of properties cannot be empty,' unless @keys;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my (@value) = @_;

                    if (! @value) {
                        $subscriber->{next}->() if defined $subscriber->{next};
                        return;
                    }

                    my $cursor = $value[0];
                    foreach my $key (@keys) {
                        if ((reftype($cursor) // '') eq 'HASH' and exists $cursor->{$key}) {
                            $cursor = $cursor->{$key};
                        } else {
                            $subscriber->{next}->(undef) if defined $subscriber->{next};
                            return;
                        }
                    }

                    $subscriber->{next}->($cursor) if defined $subscriber->{next};
                },
            };

            $source->subscribe($own_subscriber);
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

                $subscriber->subscription->add($typical_unsubscription_fn);
                $source->subscribe($subscriber);

                $connection_subscription = $source->connect;
            } else {
                $subscriber->subscription->add($typical_unsubscription_fn);
                $source->subscribe($subscriber);
            }

            return;
        });
    };
}

sub _op_repeat_helper {
    my ($subscriber, $source, $count_ref, $own_subscription_ref) = @_;

    my $own_subscription = RxPerl::Subscription->new;
    $$own_subscription_ref = $own_subscription;
    my $own_subscriber = {
        new_subscription => $own_subscription,
        next     => $subscriber->{next},
        error    => $subscriber->{error},
        complete => sub {
            if (--$$count_ref) {
                _op_repeat_helper(
                    $subscriber, $source, $count_ref, $own_subscription_ref,
                );
            } else {
                $subscriber->{complete}->() if defined $subscriber->{complete};
            }
        },
    };

    $source->subscribe($own_subscriber);
}

sub op_repeat {
    my ($count) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $count = $count;

            $count = -1 if ! defined $count;
            if ($count == 0) {
                $subscriber->{complete}->() if defined $subscriber->{complete};
                return;
            }

            my $own_subscription;
            my $own_subscription_ref = \$own_subscription;

            $subscriber->subscription->add(
                $own_subscription_ref,
            );

            _op_repeat_helper(
                $subscriber, $source, \$count, $own_subscription_ref,
            );

            return;
        });
    };
}

sub _op_retry_helper {
    my ($subscriber, $source, $count_ref, $own_subscription_ref) = @_;

    my $own_subscription = RxPerl::Subscription->new;
    $$own_subscription_ref = $own_subscription;
    my $own_subscriber = {
        new_subscription => $own_subscription,
        next     => $subscriber->{next},
        error    => sub {
            if ($$count_ref--) {
                _op_retry_helper(
                    $subscriber, $source, $count_ref, $own_subscription_ref,
                );
            } else {
                $subscriber->{error}->(@_) if defined $subscriber->{error};
            }
        },
        complete => $subscriber->{complete},
    };

    $source->subscribe($own_subscriber);
}

sub op_retry {
    my ($count) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $count = $count;

            $count = -1 if ! defined $count;

            my $own_subscription;
            my $own_subscription_ref = \$own_subscription;

            $subscriber->subscription->add(
                $own_subscription_ref,
            );

            _op_retry_helper(
                $subscriber, $source, \$count, $own_subscription_ref,
            );

            return;
        });
    };
}

sub op_sample_time {
    my ($period) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @last_value;
            my $emitted = 0;

            my $n_s = rx_interval($period)->subscribe(sub {
                if ($emitted) {
                    $emitted = 0;
                    $subscriber->{next}->(@last_value) if defined $subscriber->{next};
                }
            });

            $subscriber->subscription->add($n_s);

            $source->subscribe({
                %$subscriber,
                next => sub {
                    my @value = @_;

                    @last_value = @value;
                    $emitted = 1;
                },
            });
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

sub op_skip {
    my ($count) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $count = int $count;

            my $own_subscriber;
            $own_subscriber = $subscriber if $count <= 0;
            $own_subscriber //= {
                %$subscriber,
                next => sub {
                    if ($count-- <= 0) {
                        $subscriber->{next}->(@_) if defined $subscriber->{next};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_skip_until {
    my ($notifier) = @_;

    # FUTURE TODO: allow notifier to be a promise
    croak q"You provided 'undef' where a stream was expected. You can provide an observable."
        unless defined $notifier;
    croak q"The notifier of 'op_skip_until' needs to be an observable."
        unless blessed $notifier and $notifier->isa('RxPerl::Observable');

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $notifier_has_emitted;
            my $n_s = $notifier->pipe(
                op_take(1),
            )->subscribe(
                sub {
                    $notifier_has_emitted = 1;
                },
                sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
            );

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    $subscriber->{next}->(@_) if defined $subscriber->{next}
                        and $notifier_has_emitted;
                },
            };

            $source->subscribe($own_subscriber);

            return $n_s;
        });
    };
}

sub op_start_with {
    my (@values) = @_;

    return sub {
        my ($source) = @_;

        return rx_concat(
            rx_of(@values),
            $source,
        );
    };
}

sub op_switch_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $this_own_subscription;
            my $own_subscription = RxPerl::Subscription->new;

            $subscriber->subscription->add(
                \$this_own_subscription, $own_subscription,
            );

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next     => sub {
                    my ($value) = @_;

                    my $new_observable = $observable_factory->($value);
                    $this_own_subscription->unsubscribe() if $this_own_subscription;
                    $this_own_subscription = RxPerl::Subscription->new;
                    my $this_own_subscriber = {
                        new_subscription => $this_own_subscription,
                        next     => sub {
                            $subscriber->{next}->(@_) if defined $subscriber->{next};
                        },
                        error    => sub {
                            $subscriber->{error}->(@_) if defined $subscriber->{error};
                        },
                        complete => sub {
                            $subscriber->{complete}->() if $own_subscription->{closed}
                                and defined $subscriber->{complete};
                        },
                    };

                    $new_observable->subscribe($this_own_subscriber);
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    # $source_complete = 1;
                    $subscriber->{complete}->() if defined $subscriber->{complete} and
                        (not $this_own_subscription or $this_own_subscription->{closed});
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    }
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

sub op_take_while {
    my ($cond, $include) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($value) = @_;

                    if (! $cond->($value)) {
                        $subscriber->{next}->($value) if $include and defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                        return;
                    }

                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                },
            };

            $source->subscribe($own_subscriber);

            return;
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
            my $tap_subscriber; $tap_subscriber = $args[0] if (reftype($args[0]) // '') eq 'HASH';
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

sub op_throttle_time {
    my ($duration) = @_;

    my ($timer_sub, $cancel_timer_sub) = get_timer_subs;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $silent_mode = 0;
            my $silence_timer_id;

            $subscriber->subscription->add(
                sub { $cancel_timer_sub->($silence_timer_id) if defined $silence_timer_id }
            );

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my @value = @_;

                    if (! $silent_mode) {
                        $silent_mode = 1;
                        $silence_timer_id = $timer_sub->($duration, sub {
                            undef $silence_timer_id;
                            $silent_mode = 0;
                        });

                        $subscriber->{next}->(@value) if defined $subscriber->{next};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_with_latest_from {
    my (@other_observables) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @other_observables = @other_observables;
            my $i = 0;
            my %didnt_emit = map {($i++, 1)} @other_observables;
            my @latest_values;
            my %other_subscriptions;

            $subscriber->subscription->add(
                \%other_subscriptions, sub { undef @other_observables },
            );

            for (my $i = 0; $i < @other_observables; $i++) {
                my $j = $i;
                my $other_observable = $other_observables[$j];

                my $other_subscription = RxPerl::Subscription->new;
                $other_subscriptions{$other_subscription} = $other_subscription;
                $other_observable->subscribe({
                    new_subscription => $other_subscription,
                    next     => sub {
                        my ($value) = @_;

                        $latest_values[$j] = $value;
                        delete $didnt_emit{$j};
                    },
                    error    => $subscriber->{error},
                });
            }

            $source->subscribe({
                %$subscriber,
                next => sub {
                    my ($value) = @_;

                    if (! %didnt_emit) {
                        $subscriber->{next}->([$value, @latest_values]) if defined $subscriber->{next};
                    }
                },
            });

            return;
        });
    };
}

sub _eqq {
    my ($x, $y) = @_;

    defined $x or return !defined $y;
    defined $y or return !!0;
    ref $x eq ref $y or return !!0;
    return length(ref $x) ? refaddr $x == refaddr $y : $x eq $y;
}

1;
