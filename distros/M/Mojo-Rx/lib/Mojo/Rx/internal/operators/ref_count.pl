use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::Rx::Utils 'get_subscription_from_subscriber';
use Mojo::Rx::Subscription;

use Carp 'croak';

*Mojo::Rx::op_ref_count = sub {
    return sub {
        my ($source) = @_;

        croak 'op_ref_count() was not applied to a connectable observable'
            unless $source->isa('Mojo::Rx::ConnectableObservable');

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
                $connection_subscription = Mojo::Rx::Subscription->new;

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
};

1;
