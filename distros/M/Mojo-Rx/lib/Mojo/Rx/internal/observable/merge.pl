use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::Rx::Subscription;
use Mojo::Rx::Utils 'get_subscription_from_subscriber';

*Mojo::Rx::rx_merge = sub {
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
            my $own_subscription = Mojo::Rx::Subscription->new;
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
};

1;
