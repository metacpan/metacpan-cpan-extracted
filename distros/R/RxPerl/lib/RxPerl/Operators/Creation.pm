package RxPerl::Operators::Creation;
use strict;
use warnings;

use RxPerl::Observable;
use RxPerl::Subscription;
use RxPerl::Utils 'get_timer_subs', 'get_interval_subs';
use RxPerl::Subject;
use RxPerl::BehaviorSubject;
use RxPerl::ReplaySubject;

use Carp 'croak';
use Scalar::Util qw/ weaken blessed reftype /;

use Exporter 'import';
our @EXPORT_OK = qw/
    rx_behavior_subject rx_combine_latest rx_concat rx_defer rx_EMPTY
    rx_fork_join rx_from rx_from_event rx_from_event_array rx_interval
    rx_merge rx_NEVER rx_observable rx_of rx_partition rx_race
    rx_replay_subject rx_subject rx_throw_error rx_timer
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v6.10.1";

sub rx_observable;

sub rx_behavior_subject { "RxPerl::BehaviorSubject" }

sub rx_combine_latest {
    my ($sources) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $sources = [@$sources];

        my %own_subscriptions;
        my $i = 0;
        my %didnt_emit = map {($i++, 1)} @$sources;
        my @latest_values;
        my $num_active = @$sources;

        $subscriber->subscription->add(
            \%own_subscriptions, sub { undef @$sources },
        );

        for (my $i = 0; $i < @$sources; $i++) {
            my $j = $i;
            my $source = $sources->[$j];
            my $own_subscription = RxPerl::Subscription->new;
            $own_subscriptions{$own_subscription} = $own_subscription;
            my $own_observer = {
                new_subscription => $own_subscription,
                next             => sub {
                    my ($value) = @_;

                    $latest_values[$j] = $value;
                    delete $didnt_emit{$j};

                    if (!%didnt_emit) {
                        $subscriber->{next}->([@latest_values]) if defined $subscriber->{next};
                    }
                },
                error            => $subscriber->{error},
                complete         => sub {
                    $num_active--;
                    if ($num_active == 0) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };
            $source->subscribe($own_observer);
        }

        return;
    });
}

sub _rx_concat_helper {
    my ($sources, $subscriber, $active) = @_;

    if (! @$sources) {
        $subscriber->{complete}->() if defined $subscriber->{complete};
        return;
    }

    my $source = shift @$sources;
    my $own_subscription = RxPerl::Subscription->new;
    my $own_subscriber = {
        new_subscription => $own_subscription,
        next     => $subscriber->{next},
        error    => $subscriber->{error},
        complete => sub {
            _rx_concat_helper($sources, $subscriber, $active);
        },
    };
    @$active = ($own_subscription);
    $source->subscribe($own_subscriber);
}

sub rx_concat {
    my (@sources) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my @sources = @sources;

        my @active;
        $subscriber->subscription->add(
            \@active, sub { undef @sources },
        );

        _rx_concat_helper(\@sources, $subscriber, \@active);

        return;
    });
}

sub rx_defer {
    my ($observable_factory) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $observable = $observable_factory->();

        return $observable->subscribe($subscriber);
    });
}

my $rx_EMPTY;

sub rx_EMPTY {
    $rx_EMPTY //= rx_observable->new(sub {
        my ($subscriber) = @_;

        $subscriber->{complete}->() if defined $subscriber->{complete};

        return;
    });
}

sub rx_fork_join {
    my ($sources) = @_;

    my $arg_is_array = !(blessed $sources) && (reftype $sources eq 'ARRAY');
    my $arg_is_hash = !(blessed $sources) && (reftype $sources eq 'HASH');

    croak "argument of rx_fork_join needs to be either an arrayref or a hashref"
        unless $arg_is_array or $arg_is_hash;

    if ($arg_is_array) {
        my $i = 0;
        $sources = { map {($i++, $_)} @$sources };
    }

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $sources = { %$sources };
        my %last_values;
        my %own_subscriptions;
        my @keys = keys %$sources;
        @keys = sort {$a <=> $b} @keys if $arg_is_array;

        $subscriber->subscription->add(
            \%own_subscriptions, sub { undef @keys },
        );

        if (! @keys) {
            $subscriber->{complete}->() if defined $subscriber->{complete};
            return;
        }

        for (my $i = 0; $i < @keys; $i++) {
            my $key = $keys[$i];
            my $source = $sources->{$key};
            my $own_subscription = RxPerl::Subscription->new;
            $own_subscriptions{$own_subscription} = $own_subscription;
            $source->subscribe({
                new_subscription => $own_subscription,
                next     => sub {
                    $last_values{$key} = $_[0];
                },
                error    => $subscriber->{error},
                complete => sub {
                    if (exists $last_values{$key}) {
                        if (keys(%last_values) == keys %$sources) {
                            if ($arg_is_array) {
                                my @ret;
                                $ret[$_] = $last_values{$_} foreach keys %last_values;
                                $subscriber->{next}->(\@ret) if defined $subscriber->{next};
                            }
                            else {
                                $subscriber->{next}->(\%last_values) if defined $subscriber->{next};
                            }
                            $subscriber->{complete}->() if defined $subscriber->{complete};
                        }
                    } else {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            });
        }

        return;
    });
}

sub rx_from {
    my ($thing) = @_;

    if (blessed $thing and $thing->isa('RxPerl::Observable')) {
        return $thing;
    }

    elsif (blessed $thing and $thing->isa('Future')) {
        return rx_observable->new(sub {
            my ($subscriber) = @_;

            $thing->on_done(sub {
                $subscriber->{next}->(splice @_, 0, 1) if defined $subscriber->{next};
                $subscriber->{complete}->() if defined $subscriber->{complete};
            });

            $thing->on_fail(sub {
                $subscriber->{error}->(splice @_, 0, 1) if defined $subscriber->{error};
            });

            $thing->on_ready(sub {
                if ($thing->is_cancelled) {
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                }
            });
        });
    }

    elsif (blessed $thing and $thing->can('then')) {
        return rx_observable->new(sub {
            my ($subscriber) = @_;

            $thing->then(
                sub {
                    $subscriber->{next}->(splice @_, 0, 1) if defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
                sub {
                    $subscriber->{error}->(splice @_, 0, 1) if defined $subscriber->{error};
                },
            );

            return;
        });
    }

    elsif (ref $thing eq 'ARRAY' and ! blessed $thing) {
        return rx_of(@$thing);
    }

    elsif (defined $thing and ! length(ref $thing)) {
        my @letters = split //, $thing;
        return rx_of(@letters);
    }

    else {
        croak "rx_from only accepts arrayrefs, promises, observables, and strings as argument at the moment,";
    }
}

# NOTE: rx_from_event and rx_from_event_array keep a weak reference to the
# EventEmitter $object. Should this change? TODO: think about that.

sub rx_from_event {
    my ($object, $event_type) = @_;

    croak 'invalid object type, at rx_from_event' if not $object->isa('Mojo::EventEmitter');

    weaken($object);
    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $cb = sub {
            my ($e, @args) = @_;

            $subscriber->{next}->(splice @args, 0, 1) if defined $subscriber->{next};
        };

        $subscriber->subscription->add(sub {
            $object->unsubscribe($cb) if defined $object;
        });

        $object->on($event_type, $cb);

        return;
    });
}

sub rx_from_event_array {
    my ($object, $event_type) = @_;

    croak 'invalid object type, at rx_from_event_array' if not $object->isa('Mojo::EventEmitter');

    weaken($object);
    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $cb = sub {
            my ($e, @args) = @_;

            $subscriber->{next}->([@args]) if defined $subscriber->{next};
        };

        $subscriber->subscription->add(sub {
            $object->unsubscribe($cb) if defined $object;
        });

        $object->on($event_type, $cb);

        return;
    });
}

sub rx_interval {
    my ($after) = @_;

    my ($interval_sub, $cancel_interval_sub) = get_interval_subs;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $counter = 0;
        my $timer = $interval_sub->($after, sub {
            $subscriber->{next}->($counter++) if defined $subscriber->{next};
        });

        return sub {
            $cancel_interval_sub->($timer);
        };
    });
}

sub rx_merge {
    my @sources = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my @sources = @sources;

        my %own_subscriptions;
        $subscriber->subscription->add(
            \%own_subscriptions,
            sub { @sources = () },
        );

        my $num_active_subscriptions = @sources;
        $num_active_subscriptions or $subscriber->{complete}->() if defined $subscriber->{complete};

        for (my $i = 0; $i < @sources; $i++) {
            my $source = $sources[$i];
            my $own_subscription = RxPerl::Subscription->new;
            $own_subscriptions{$own_subscription} = $own_subscription;
            my $own_subscriber = {
                new_subscription => $own_subscription,
                next             => $subscriber->{next},
                error            => $subscriber->{error},
                complete         => sub {
                    delete $own_subscriptions{$own_subscription};
                    if (! --$num_active_subscriptions) {
                        $subscriber->{complete}->() if defined $subscriber->{complete};
                    }
                },
            };
            $source->subscribe($own_subscriber);
        }

        return;
    });
}

my $rx_never;

sub rx_NEVER {
    return $rx_never //= rx_observable->new(sub {
        return;
    });
}

sub rx_observable { "RxPerl::Observable" }

sub rx_of {
    my (@values) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        foreach my $value (@values) {
            return if !! ${ $subscriber->{closed_ref} };
            $subscriber->{next}->($value) if defined $subscriber->{next};
        }
        $subscriber->{complete}->() if defined $subscriber->{complete};

        return;
    });
}

sub rx_partition {
    my ($source, $predicate) = @_;

    my $o1 = $source->pipe(
        RxPerl::Operators::Pipeable::op_filter($predicate),
    );

    my $i = -1;
    my $o2 = $source->pipe(
        RxPerl::Operators::Pipeable::op_filter(sub {
            $i++;
            return not $predicate->($_[0], $i);
        }),
    );

    return ($o1, $o2);
}

sub rx_race {
    my (@sources) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;
        # TODO: experiment in the end with passing a second parameter here, an arrayref, called \@early_return_values
        # TODO: like: my ($subscriber, $early_return_values) = @_; and then push @$early_return_values, sub {...};

        my @sources = @sources;

        my @own_subscriptions;
        $subscriber->subscription->add(\@own_subscriptions);

        for (my $i = 0; $i < @sources; $i++) {
            my $source = $sources[$i];

            my $own_subscription = RxPerl::Subscription->new;
            push @own_subscriptions, $own_subscription;
            my $own_subscriber = {
                new_subscription => $own_subscription,
            };

            foreach my $type (qw/ next error complete /) {
                $own_subscriber->{$type} = sub {
                    $_->unsubscribe foreach grep $_ ne $own_subscription, @own_subscriptions;
                    @own_subscriptions = ($own_subscription);
                    @sources = ();
                    $subscriber->{$type}->(@_) if defined $subscriber->{$type};
                    @$own_subscriber{qw/ next error complete /} = @$subscriber{qw/ next error complete /};
                };
            }

            $source->subscribe($own_subscriber);
        }

        # this could be replaced with a 'return undef' at this point
        return \@own_subscriptions;
    });
}

sub rx_replay_subject { "RxPerl::ReplaySubject" }

sub rx_subject { "RxPerl::Subject" }

sub rx_throw_error {
    my ($error) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        $subscriber->{error}->($error) if defined $subscriber->{error};

        return;
    });
};

sub rx_timer {
    my ($after, $period) = @_;

    my ($timer_sub, $cancel_timer_sub) = get_timer_subs;
    my ($interval_sub, $cancel_interval_sub) = get_interval_subs;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $counter = 0;
        my $timer_int;
        my $timer = $timer_sub->($after, sub {
            $subscriber->{next}->($counter++) if defined $subscriber->{next};
            if (defined $period) {
                $timer_int = $interval_sub->($period, sub {
                    $subscriber->{next}->($counter++) if defined $subscriber->{next};
                });
            } else {
                $subscriber->{complete}->() if defined $subscriber->{complete};
            }
        });

        return sub {
            $cancel_timer_sub->($timer);
            $cancel_interval_sub->($timer_int);
        };
    });
};

1;
