package RxPerl::Operators::Creation;
use strict;
use warnings FATAL => 'all';

use RxPerl::Observable;
use RxPerl::Subscription;
use RxPerl::Utils 'get_subscription_from_subscriber', 'get_timer_subs', 'get_interval_subs';
use RxPerl::Subject;

use Carp 'croak';
use Scalar::Util 'weaken';

use Exporter 'import';
our @EXPORT_OK = qw/
    rx_observable rx_of rx_concat rx_defer rx_EMPTY rx_from_event
    rx_from_event_array rx_interval rx_merge rx_never rx_race
    rx_subject rx_throw_error rx_timer
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub rx_observable;

sub _rx_concat_helper {
    my ($sources, $subscriber, $early_returns) = @_;

    @$sources or do {
        $subscriber->{complete}->() if defined $subscriber->{complete};
        return;
    };

    my $source = shift @$sources;

    my $own_subscription = RxPerl::Subscription->new;
    @$early_returns = ($own_subscription);
    get_subscription_from_subscriber($subscriber)->add_dependents($early_returns);

    my $own_subscriber = {
        new_subscription => $own_subscription,
        next             => $subscriber->{next},
        error            => $subscriber->{error},
        complete         => sub {
            _rx_concat_helper->($sources, $subscriber, $early_returns);
        },
    };

    $source->subscribe($own_subscriber);
}

sub rx_concat {
    my (@sources) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my @sources = @sources;

        my $early_returns = [];
        get_subscription_from_subscriber($subscriber)->add_dependents($early_returns, sub { @sources = () });
        _rx_concat_helper(\@sources, $subscriber, $early_returns);

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

# NOTE: rx_from_event and rx_from_event_array keep a hard reference to the
# EventEmitter $object. Should this change? TODO: think about that.

sub rx_from_event {
    my ($object, $event_type) = @_;

    croak 'invalid object type, at rx_from_event' if not $object->isa('Mojo::EventEmitter');

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $cb = sub {
            my ($e, @args) = @_;

            $subscriber->{next}->(splice @args, 0, 1) if defined $subscriber->{next};
        };

        get_subscription_from_subscriber($subscriber)->add_dependents(sub { $object->unsubscribe($cb) });

        $object->on($event_type, $cb);

        return;
    });
}

sub rx_from_event_array {
    my ($object, $event_type) = @_;

    croak 'invalid object type, at rx_from_event' if not $object->isa('Mojo::EventEmitter');

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $cb = sub {
            my ($e, @args) = @_;

            $subscriber->{next}->([@args]) if defined $subscriber->{next};
        };

        get_subscription_from_subscriber($subscriber)->add_dependents(sub { $object->unsubscribe($cb) });

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
        get_subscription_from_subscriber($subscriber)->add_dependents(
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

sub rx_never {
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

sub rx_race {
    my (@sources) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;
        # TODO: experiment in the end with passing a second parameter here, an arrayref, called \@early_return_values
        # TODO: like: my ($subscriber, $early_return_values) = @_; and then push @$early_return_values, sub {...};

        my @sources = @sources;

        my @own_subscriptions;
        get_subscription_from_subscriber($subscriber)->add_dependents(\@own_subscriptions);

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
