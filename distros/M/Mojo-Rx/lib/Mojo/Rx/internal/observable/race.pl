use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::Rx::Subscription;
use Mojo::Rx::Utils 'get_subscription_from_subscriber';

*Mojo::Rx::rx_race = sub {
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

            my $own_subscription = Mojo::Rx::Subscription->new;
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
};

1;
