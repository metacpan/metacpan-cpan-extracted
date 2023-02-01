package RxPerl::Operators::Pipeable;
use strict;
use warnings;

use RxPerl::Operators::Creation qw/
    rx_observable rx_subject rx_concat rx_of rx_interval rx_combine_latest rx_concat rx_throw_error rx_zip
    rx_merge rx_on_error_resume_next
/;
use RxPerl::ConnectableObservable;
use RxPerl::Utils qw/ get_timer_subs /;
use RxPerl::Subscription;

use Carp 'croak';
use Scalar::Util 'reftype', 'refaddr', 'blessed', 'weaken';

use Exporter 'import';
our @EXPORT_OK = qw/
    op_audit_time op_buffer op_buffer_count op_buffer_time op_catch_error op_combine_latest_with op_concat_all
    op_concat_map op_concat_with op_count op_debounce_time op_default_if_empty op_delay op_distinct_until_changed
    op_distinct_until_key_changed op_element_at op_end_with op_every op_exhaust_all op_exhaust_map op_filter
    op_finalize op_find op_find_index op_first op_ignore_elements op_is_empty op_map op_map_to op_merge_all
    op_merge_map op_merge_with op_multicast op_on_error_resume_next_with op_pairwise op_pluck op_reduce op_ref_count
    op_repeat op_retry op_sample_time op_scan op_share op_skip op_skip_until op_skip_while op_start_with op_switch_all
    op_switch_map op_take op_take_until op_take_while op_tap op_throttle_time op_with_latest_from op_zip_with
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v6.19.0";

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

sub op_buffer {
    my ($notifier) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @buffer;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    push @buffer, $_[0];
                },
                error    => sub {
                    $subscriber->{error}->($_[0]) if defined $subscriber->{error};
                },
                complete => sub {
                    $subscriber->{next}->([@buffer]) if @buffer and defined $subscriber->{next};
                    undef @buffer;
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            my $notifier_subscriber = {
                next  => sub {
                    $subscriber->{next}->([@buffer]) if defined $subscriber->{next};
                    undef @buffer;
                },
                error => sub {
                    $subscriber->{error}->($_[0]) if defined $subscriber->{error};
                },
            };

            my $s1 = $source->subscribe($own_subscriber);
            my $s2 = $notifier->subscribe($notifier_subscriber);

            return [$s1, $s2], sub { undef @buffer };
        })
    }
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

sub op_buffer_time {
    my ($buffer_time_span) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @buffer;

            my $si = rx_interval($buffer_time_span)->subscribe(
                sub {
                    $subscriber->{next}->([ @buffer ]) if defined $subscriber->{next};
                    undef @buffer;
                },
            );

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($v) = @_;
                    push @buffer, $v;
                },
            };

            $source->subscribe($own_subscriber);

            return $si;
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

sub op_combine_latest_with {
    my (@other_observables) = @_;

    return sub {
        my $source = shift;

        return rx_combine_latest([$source, @other_observables]);
    }
}

sub op_concat_all {
    return sub {
        my ($source) = @_;

        return $source->pipe( op_merge_all(1) );
    };
}

sub op_concat_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return $source->pipe(
            op_map($observable_factory),
            op_concat_all(),
        );
    };
}

sub op_concat_with {
    my @other_observables = @_;

    return sub {
        my ($source) = @_;

        return rx_concat(
            $source,
            @other_observables,
        );
    };
}

sub op_count {
    my ($predicate) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $count = 0;
            my $idx = 0;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;
                    local $_ = $v;
                    if (!$predicate or $predicate->($v, $idx++)) {
                        $count++;
                    }
                },
                complete => sub {
                    $subscriber->{next}->($count) if defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
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

sub op_default_if_empty {
    my ($default_value) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $source_emitted = 0;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    $source_emitted = 1;
                    $subscriber->{next}->(@_) if exists $subscriber->{next};
                },
                complete => sub {
                    $subscriber->{next}->($default_value) if ! $source_emitted and exists $subscriber->{next};
                    $subscriber->{complete}->() if exists $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
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
            my $completed;
            my $own_subscriber = {
                error    => sub {
                    my @value = @_;
                    $subscriber->{error}->(@value) if defined $subscriber->{error};
                },
                next     => sub {
                    my @value = @_;

                    if (!defined $queue) {
                        $queue = [];
                        my ($timer1, $timer2);
                        $timer1 = $timer_sub->(0, sub {
                            delete $timers{$timer1};
                            my @queue_copy = @$queue;
                            undef $queue;
                            $timer2 = $timer_sub->($delay, sub {
                                delete $timers{$timer2};
                                foreach my $item (@queue_copy) {
                                    $subscriber->{next}->(@$item) if defined $subscriber->{next};
                                }
                                if ($completed and ! %timers) {
                                    $subscriber->{complete}->() if defined $subscriber->{complete};
                                }
                            });
                            $timers{$timer2} = $timer2;
                        });
                        $timers{$timer1} = $timer1;
                    }
                    push @$queue, \@value;
                },
                complete => sub {
                    $completed = 1;
                    if (! %timers) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
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

sub op_element_at {
    my ($index, $default) = @_;
    my $has_default = @_ >= 2;
    $index = int $index;

    return sub {
        my ($source) = @_;

        $index >= 0 or return rx_throw_error('ArgumentOutOfRangeError');

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $i = 0;
            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    if ($i++ == $index) {
                        $subscriber->{next}->(@_) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
                complete => sub {
                    if ($has_default) {
                        $subscriber->{next}->($default) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    } else {
                        $subscriber->{error}->('ArgumentOutOfRangeError') if defined $subscriber->{error};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
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

sub op_every {
    my ($predicate) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $idx = 0;
            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;
                    local $_ = $v;
                    if (! $predicate->($v, $idx++)) {
                        $subscriber->{next}->(0) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
                complete => sub {
                    $subscriber->{next}->(1) if defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_exhaust_all {
    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $active_subscription;
            my $big_completed;
            my $own_subscription = RxPerl::Subscription->new;

            $subscriber->subscription->add(
                \$active_subscription,
                $own_subscription,
            );

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next             => sub {
                    my ($new_obs) = @_;

                    !$active_subscription or return;
                    $active_subscription = RxPerl::Subscription->new;
                    my $small_subscriber = {
                        new_subscription => $active_subscription,
                        next             => sub {
                            $subscriber->{next}->(@_) if defined $subscriber->{next};
                        },
                        error            => sub {
                            $subscriber->{error}->(@_) if defined $subscriber->{error};
                        },
                        complete         => sub {
                            undef $active_subscription;
                            $subscriber->{complete}->() if $big_completed and defined $subscriber->{complete};
                        },
                    };
                    $new_obs->subscribe($small_subscriber);
                },
                error            => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete         => sub {
                    $big_completed = 1;
                    $subscriber->{complete}->() if !$active_subscription and defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_exhaust_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return $source->pipe(
            op_map($observable_factory),
            op_exhaust_all(),
        );
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
            $own_subscriber->{next} = sub {
                my ($value) = @_;
                my $passes = eval {
                    local $_ = $value;
                    $filtering_sub->($value, $idx++);
                };
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

sub op_find {
    my ($predicate) = @_;

    return sub {
        my ($source) = @_;

        $predicate or return rx_throw_error('missing predicate in op_find');

        return $source->pipe(
            op_first($predicate),
            op_default_if_empty(undef),
        );
    };
}

sub op_find_index {
    my ($predicate) = @_;

    return sub {
        my ($source) = @_;

        $predicate or return rx_throw_error('missing predicate in op_find_index');

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $idx = 0;
            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($val) = @_;
                    my $truth;
                    my $ok = eval {
                        local $_ = $val;
                        $truth = $predicate->($val, $idx++);
                        1
                    };
                    if (!$ok) {
                        $subscriber->{error}->($@) if defined $subscriber->{error};
                    }
                    if ($truth) {
                        $subscriber->{next}->($idx - 1) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
                complete => sub {
                    $subscriber->{next}->(-1) if defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

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

sub op_ignore_elements {
    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my %own_subscriber = %$subscriber;
            delete $own_subscriber{next};

            $source->subscribe(\%own_subscriber);

            return;
        });
    }
}

sub op_is_empty {
    return sub {
        my ($source) = @_;

        return $source->pipe(
            op_first(),
            op_map_to(0),
            op_default_if_empty(1),
        );
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
            $own_subscriber->{next} = sub {
                my ($value) = @_;
                my $result = eval {
                    local $_ = $value;
                    $mapping_sub->($value, $idx++);
                };
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

sub _op_merge_all_make_subscriber {
    my ($small_subscriptions, $subscriber, $num_subscriptions_ref, $stored_observables) = @_;

    my $small_subscription = RxPerl::Subscription->new;
    $small_subscriptions->{$small_subscription} = $small_subscription;
    return {
        new_subscription => $small_subscription,
        next     => sub {
            $subscriber->{next}->(@_) if defined $subscriber->{next};
        },
        error    => sub {
            $subscriber->{error}->(@_) if defined $subscriber->{error};
        },
        complete => sub {
            $$num_subscriptions_ref--;
            delete $small_subscriptions->{$small_subscription};
            if (@$stored_observables) {
                $$num_subscriptions_ref++;
                my $new_obs = shift @$stored_observables;
                $new_obs->subscribe(
                    _op_merge_all_make_subscriber(
                        $small_subscriptions,
                        $subscriber,
                        $num_subscriptions_ref,
                        $stored_observables,
                    ),
                );
            } else {
                $subscriber->{complete}->() if !$$num_subscriptions_ref and defined $subscriber->{complete};
            }
        },
    };
}

sub op_merge_all {
    my ($concurrent) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $num_subscriptions = 0;
            my @stored_observables;
            my %small_subscriptions;

            my $own_subscription = RxPerl::Subscription->new;
            $subscriber->subscription->add(
                $own_subscription,
                \%small_subscriptions,
            );

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next     => sub {
                    my ($new_observable) = @_;

                    push @stored_observables, $new_observable;
                    if (! defined $concurrent or $num_subscriptions < $concurrent) {
                        $num_subscriptions++;
                        my $new_obs = shift @stored_observables;
                        $new_obs->subscribe(
                            _op_merge_all_make_subscriber(
                                \%small_subscriptions,
                                $subscriber,
                                \$num_subscriptions,
                                \@stored_observables,
                            ),
                        );
                    }
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    $subscriber->{complete}->() if !$num_subscriptions and defined $subscriber->{complete};
                },
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

        return $source->pipe(
            op_map($observable_factory),
            op_merge_all(),
        );
    };
}

sub op_merge_with {
    my @other_sources = @_;

    return sub {
        my ($source) = @_;

        return rx_merge(
            $source,
            @other_sources,
        );
    };
}

sub op_multicast {
    my ($subject_factory) = @_;

    return sub {
        my ($source) = @_;

        return RxPerl::ConnectableObservable->new($source, $subject_factory);
    };
}

sub op_on_error_resume_next_with {
    my @other_sources = @_;

    return sub {
        my ($source) = @_;

        return rx_on_error_resume_next(
            $source,
            @other_sources,
        );
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

sub op_reduce {
    my ($accumulator, @seed) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $got_first = @seed;
            my $acc;
            $acc = $seed[0] if $got_first;

            my $idx = 0;
            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;

                    if ($got_first) {
                        my $ok = eval { $acc = $accumulator->($acc, $v, $idx++); 1 };
                        $ok or $subscriber->{error}->($@) if defined $subscriber->{error};
                    } else {
                        $acc = $v;
                        $got_first = 1;
                    }
                },
                complete => sub {
                    $subscriber->{next}->($acc) if $got_first and defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
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

sub op_skip_while {
    my ($predicate) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $finished_skipping = 0;

            my $idx = 0;
            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($v) = @_;

                    my $should_display;
                    if ($finished_skipping) {
                        $should_display = 1;
                    } else {
                        my $satisfies_predicate;
                        my $ok = eval { local $_ = $v; $satisfies_predicate = $predicate->($v, $idx++); 1 };
                        $ok or do {
                            $subscriber->{error}->($@) if defined $subscriber->{error};
                            return;
                        };
                        if (! $satisfies_predicate) {
                            $finished_skipping = 1;
                            $should_display = 1;
                        }
                    }

                    $subscriber->{next}->(@_) if $should_display and defined $subscriber->{next};
                }
            };

            $source->subscribe($own_subscriber);

            return;
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

sub op_switch_all {
    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $old_subscription;

            my $chief_is_complete;
            my $sub_is_complete;

            my $obs_subscriber = {
                next     => sub {
                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    $sub_is_complete = 1;
                    $subscriber->{complete}->() if $chief_is_complete and defined $subscriber->{complete};
                },
            };

            my $own_subscription = RxPerl::Subscription->new;
            $subscriber->subscription->add(\$old_subscription, $own_subscription);

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next     => sub {
                    my ($new_observable) = @_;

                    $sub_is_complete = 0;
                    $old_subscription->unsubscribe() if $old_subscription;
                    $old_subscription = $new_observable->subscribe($obs_subscriber);
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    $chief_is_complete = 1;
                    $subscriber->{complete}->() if $sub_is_complete and defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_switch_map {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return $source->pipe(
            op_map($observable_factory),
            op_switch_all(),
        );
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

sub op_zip_with {
    my @other_sources = @_;

    return sub {
        my ($source) = @_;

        return rx_zip(
            $source,
            @other_sources,
        );
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
