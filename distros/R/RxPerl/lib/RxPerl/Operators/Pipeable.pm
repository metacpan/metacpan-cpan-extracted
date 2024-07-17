package RxPerl::Operators::Pipeable;
use strict;
use warnings;

use RxPerl::Operators::Creation qw/
    rx_observable rx_subject rx_concat rx_of rx_interval rx_combine_latest rx_concat
    rx_throw_error rx_zip rx_merge rx_on_error_resume_next rx_race rx_timer
    rx_behavior_subject
/;
use RxPerl::ConnectableObservable;
use RxPerl::Utils qw/ get_timer_subs /;
use RxPerl::Subscription;

use Carp 'croak';
use Scalar::Util 'reftype', 'refaddr', 'blessed', 'weaken';
use Time::HiRes ();

use Exporter 'import';
our @EXPORT_OK = qw/
    op_audit op_audit_time op_buffer op_buffer_count op_buffer_time op_catch_error op_combine_latest_with op_concat_all
    op_concat_map op_concat_with op_count op_debounce op_debounce_time op_default_if_empty op_delay op_delay_when
    op_distinct op_distinct_until_changed op_distinct_until_key_changed op_element_at op_end_with op_every
    op_exhaust_all op_exhaust_map op_filter op_finalize op_find op_find_index op_first op_ignore_elements
    op_is_empty op_last op_map op_map_to op_max op_merge_all op_merge_map op_merge_with op_min op_multicast
    op_on_error_resume_next_with op_pairwise op_pluck op_race_with op_reduce op_ref_count op_repeat op_retry op_sample
    op_sample_time op_scan op_share op_single op_skip op_skip_last op_skip_until op_skip_while op_start_with
    op_switch_all op_switch_map op_take op_take_last op_take_until op_take_while op_tap op_throttle op_throttle_time
    op_throw_if_empty op_time_interval op_timeout op_timestamp op_to_array op_with_latest_from op_zip_with
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v6.29.0";

sub op_audit {
    my ($duration_selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $last_val;
            my $mini_subscription;
            my $main_is_complete;

            my $mini_subscriber = {
                next     => sub {
                    $subscriber->{next}->($last_val) if defined $subscriber->{next};
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    undef $mini_subscription;
                    undef $last_val;
                    if ($main_is_complete) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };

            my $own_subscriber = {
                next     => sub {
                    my ($v) = @_;

                    $last_val = $v;
                    if (!defined $mini_subscription) {
                        my $o = do { local $_ = $v; $duration_selector->($v) };
                        $mini_subscription = $o->pipe(
                            op_take(1),
                        )->subscribe($mini_subscriber);
                    }
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    $main_is_complete = 1;
                    if (! defined $mini_subscription) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                }
            };

            my $own_subscription = $source->subscribe($own_subscriber);

            return $mini_subscription, $own_subscription;
        });
    };
}

sub op_audit_time {
    my ($duration) = @_;

    return op_audit(sub { rx_timer($duration) });
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

    return op_buffer(rx_interval($buffer_time_span));
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
    return op_merge_all(1);
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

sub op_debounce {
    my ($duration_selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $mini_subscription;
            my $last_val;
            my $has_last_val;

            my $mini_subscriber = {
                next     => sub {
                    $subscriber->{next}->($last_val) if defined $subscriber->{next};
                    undef $has_last_val;
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    undef $mini_subscription;
                },
            };

            my $own_subscriber = {
                next     => sub {
                    my ($v) = @_;

                    if (defined $mini_subscription) {
                        $mini_subscription->unsubscribe();
                    }

                    $last_val = $v;
                    $has_last_val = 1;

                    my $o = do { local $_ = $v; $duration_selector->($v) };
                    $mini_subscription = $o->pipe(
                        op_take(1),
                    )->subscribe($mini_subscriber);
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    if ($has_last_val) {
                        $subscriber->{next}->($last_val) if defined $subscriber->{next};
                    }
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                }
            };

            my $main_subscription = $source->subscribe($own_subscriber);
            $main_subscription->add(\$mini_subscription);

            return $main_subscription, $mini_subscription;
        });
    };
}

sub op_debounce_time {
    my ($due_time) = @_;

    return op_debounce(sub { rx_timer($due_time) });
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

sub op_delay_when {
    my ($delay_duration_selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $idx = 0;
            my %mini_subscriptions;
            my $main_finished;

            my $make_mini_subscriber = sub {
                my ($v) = @_;

                my $mini_subscription = RxPerl::Subscription->new;
                $mini_subscriptions{$mini_subscription} = $mini_subscription;

                return {
                    new_subscription => $mini_subscription,
                    next             => sub {
                        $subscriber->{next}->($v) if defined $subscriber->{next};
                    },
                    error            => sub {
                        $subscriber->{error}->(@_) if defined $subscriber->{error};
                    },
                    complete         => sub {
                        delete $mini_subscriptions{$mini_subscription};
                        if ($main_finished and ! %mini_subscriptions) {
                            $subscriber->{complete}->() if defined $subscriber->{complete};
                        }
                    },
                };
            };

            my $own_subscription = RxPerl::Subscription->new;
            my $own_subscriber = {
                new_subscription => $own_subscription,
                next             => sub {
                    my ($v) = @_;

                    local $_ = $v;
                    my $mini_obs = $delay_duration_selector->($v, $idx++);
                    $mini_obs->subscribe($make_mini_subscriber->($v));
                },
                error            => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete         => sub {
                    $main_finished = 1;
                    if (!%mini_subscriptions) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };

            $subscriber->subscription->add($own_subscription, \%mini_subscriptions);

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_distinct {
    my ($key_selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my %keys_passed;
            $subscriber->subscription->add(sub { %keys_passed = () });

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($v) = @_;

                    my $k;
                    if ($key_selector) {
                        my $ok = eval { local $_ = $v; $k = $key_selector->($v); 1 };
                        if (! $ok) {
                            $subscriber->{error}->($@) if defined $subscriber->{error};
                            return;
                        }
                    } else {
                        $k = $v;
                    }
                    if (! exists $keys_passed{$k}) {
                        $keys_passed{$k} = 1;
                        $subscriber->{next}->($v) if defined $subscriber->{next};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
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
                        $subscriber->{next}->(!!0) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
                complete => sub {
                    $subscriber->{next}->(!!1) if defined $subscriber->{next};
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
            op_map_to(!!0),
            op_default_if_empty(!!1),
        );
    };
}

sub op_last {
    my ($predicate, $default) = @_;
    my $has_default = @_ >= 2;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $last_val;
            my $last_val_obtained;

            my $idx = 0;
            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($v) = @_;

                    if ($predicate) {
                        my $passes;
                        my $ok = eval { local $_ = $v; $passes = $predicate->($v, $idx++); 1 };
                        $ok or do {
                            $subscriber->{error}->($@) if defined $subscriber->{error};
                            return;
                        };
                        if ($passes) {
                            $last_val = $v;
                            $last_val_obtained = 1;
                        }
                    } else {
                        $last_val = $v;
                        $last_val_obtained = 1;
                    }
                },
                complete => sub {
                    if (! $last_val_obtained) {
                        if ($has_default) {
                            $subscriber->{next}->($default) if defined $subscriber->{next};
                            $subscriber->{complete}->() if defined $subscriber->{complete};
                        } else {
                            $subscriber->{error}->("no last value found");
                        }
                    } else {
                        $subscriber->{next}->($last_val) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
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

sub op_max {
    my ($comparer) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $curr_max;
            my $has_curr_max;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;

                    if (!$has_curr_max) {
                        $curr_max = $v;
                        $has_curr_max = 1;
                    }
                    else {
                        if (!$comparer) {
                            if ($v > $curr_max) {
                                $curr_max = $v;
                            }
                        }
                        else {
                            if ($comparer->($v, $curr_max) > 0) {
                                $curr_max = $v;
                            }
                        }
                    }
                },
                complete => sub {
                    if ($has_curr_max) {
                        $subscriber->{next}->($curr_max) if defined $subscriber->{next};
                    }
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub _op_merge_all_make_subscriber {
    my ($small_subscriptions, $subscriber, $stored_observables, $big_completed_ref) = @_;

    my $small_subscription = RxPerl::Subscription->new;
    $small_subscriptions->{$small_subscription} = $small_subscription;
    return {
        new_subscription => $small_subscription,
        next             => sub {
            $subscriber->{next}->(@_) if defined $subscriber->{next};
        },
        error            => sub {
            $subscriber->{error}->(@_) if defined $subscriber->{error};
        },
        complete         => sub {
            delete $small_subscriptions->{$small_subscription};
            if (@$stored_observables) {
                my $new_obs = shift @$stored_observables;
                $new_obs->subscribe(
                    _op_merge_all_make_subscriber(
                        $small_subscriptions,
                        $subscriber,
                        $stored_observables,
                        $big_completed_ref,
                    ),
                );
            } elsif ($$big_completed_ref and !%$small_subscriptions) {
                $subscriber->{complete}->() if defined $subscriber->{complete};
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

            my @stored_observables;
            my %small_subscriptions;
            my $big_completed;

            my $own_subscription = RxPerl::Subscription->new;
            $subscriber->subscription->add(
                $own_subscription,
                \%small_subscriptions,
            );

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next             => sub {
                    my ($new_observable) = @_;

                    push @stored_observables, $new_observable;
                    if (!defined $concurrent or keys(%small_subscriptions) < $concurrent) {
                        my $new_obs = shift @stored_observables;
                        $new_obs->subscribe(
                            _op_merge_all_make_subscriber(
                                \%small_subscriptions,
                                $subscriber,
                                \@stored_observables,
                                \$big_completed,
                            ),
                        );
                    }
                },
                error            => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete         => sub {
                    $big_completed = 1;
                    $subscriber->{complete}->() if !%small_subscriptions and defined $subscriber->{complete};
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

sub op_min {
    my ($comparer) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $curr_min;
            my $has_curr_min;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;

                    if (!$has_curr_min) {
                        $curr_min = $v;
                        $has_curr_min = 1;
                    }
                    else {
                        if (!$comparer) {
                            if ($v < $curr_min) {
                                $curr_min = $v;
                            }
                        }
                        else {
                            if ($comparer->($v, $curr_min) < 0) {
                                $curr_min = $v;
                            }
                        }
                    }
                },
                complete => sub {
                    if ($has_curr_min) {
                        $subscriber->{next}->($curr_min) if defined $subscriber->{next};
                    }
                    $subscriber->{complete}->() if defined $subscriber->{complete};
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

sub op_race_with {
    my @other_sources = @_;

    return sub {
        my ($source) = @_;

        return rx_race(
            $source,
            @other_sources,
        );
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

sub op_sample {
    my ($notifier) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $last_val;
            my $has_last_val;

            my $notifier_subscription = RxPerl::Subscription->new;
            my $notifier_subscriber = {
                new_subscription => $notifier_subscription,
                next             => sub {
                    if ($has_last_val) {
                        $subscriber->{next}->($last_val) if defined $subscriber->{next};
                        undef $has_last_val;
                    }
                },
                error            => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
            };

            $subscriber->subscription->add($notifier_subscription);

            my $own_subscriber = {
                %$subscriber,
                next  => sub {
                    my ($v) = @_;

                    $last_val = $v;
                    $has_last_val = 1;
                },
            };

            $notifier->subscribe($notifier_subscriber);
            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_sample_time {
    my ($period) = @_;

    return op_sample(rx_interval($period));
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

sub op_single {
    my ($predicate) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @found;

            my $idx = 0;
            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;

                    if (!$predicate) {
                        push @found, $v;
                    } else {
                        my $found;
                        my $ok = eval { local $_ = $v; $found = $predicate->($v, $idx++); 1 };
                        if (! $ok) {
                            $subscriber->{error}->($@) if defined $subscriber->{error};
                            return;
                        }
                        push @found, $v if $found;
                    }

                    $subscriber->{error}->('Too many values match') if @found > 1 and defined $subscriber->{error};
                },
                complete => sub {
                    if (! @found) {
                        $subscriber->{error}->('No values match') if defined $subscriber->{error};
                    } else {
                        $subscriber->{next}->($found[0]) if defined $subscriber->{next};
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
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

sub op_skip_last {
    my ($skip_count) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @skipped;
            $subscriber->subscription->add(sub { undef @skipped });

            my $own_subscriber = { %$subscriber };
            $own_subscriber->{next} &&= sub {
                my ($v) = @_;

                push @skipped, $v;
                if (@skipped > $skip_count) {
                    my $new_v = shift @skipped;
                    $subscriber->{next}->($new_v) if defined $subscriber->{next};
                }
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

sub op_take_last {
    my ($count) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @last_values;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;

                    push @last_values, $v;
                    if (@last_values > $count) {
                        shift @last_values;
                    }
                },
                complete => sub {
                    foreach my $last_val (@last_values) {
                        $subscriber->{next}->($last_val) if defined $subscriber->{next};
                    }
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    }
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

            my $i = 0;
            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($value) = @_;

                    if (! do { local $_ = $value; $cond->($value, $i++) }) {
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

sub op_throttle {
    my ($duration_selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $mini_subscription;

            my $mini_subscriber = {
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    undef $mini_subscription;
                },
            };

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    my ($v) = @_;

                    if (! $mini_subscription) {
                        $subscriber->{next}->(@_) if defined $subscriber->{next};
                        $mini_subscription = do { local $_ = $v; $duration_selector->($v) }->pipe(
                            op_take(1),
                        )->subscribe($mini_subscriber);
                    }
                },
            };

            $subscriber->subscription->add(\$mini_subscription);

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_throttle_time {
    my ($duration) = @_;

    return op_throttle(sub { rx_timer($duration) });
}

sub op_throw_if_empty {
    my ($error_factory) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $is_empty = 1;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    $is_empty = 0;
                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                },
                complete => sub {
                    if ($is_empty) {
                        $subscriber->{error}->($error_factory->()) if defined $subscriber->{error};
                    } else {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_time_interval {
    return sub {
        my ($source) = @_;

        my $t0 = Time::HiRes::time();

        return $source->pipe(
            op_map(sub {
                my $now = Time::HiRes::time();
                my $interval = $now - $t0;
                $t0 = $now;
                return { value => $_, interval => $interval };
            }),
        );
    };
}

sub op_timeout {
    my ($duration) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $subject = rx_behavior_subject->new(1);
            my $s_s = $subject->pipe(
                op_switch_map(sub { rx_timer($duration) }),
            )->subscribe(sub {
                $subscriber->{error}->('Timeout has occurred') if defined $subscriber->{error};
            });

            my $own_subscription = RxPerl::Subscription->new;
            $subscriber->subscription->add($own_subscription, $s_s);

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next     => sub {
                    $subject->{next}->(1) if defined $subject->{next};
                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                },
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                }
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}

sub op_timestamp {
    return op_map(sub {
        return {
            value     => $_,
            timestamp => Time::HiRes::time(),
        };
    });
}

sub op_to_array {
    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @values;

            my $own_subscriber = {
                %$subscriber,
                next     => sub {
                    my ($v) = @_;
                    push @values, $v;
                },
                complete => sub {
                    $subscriber->{next}->(\@values) if defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
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
