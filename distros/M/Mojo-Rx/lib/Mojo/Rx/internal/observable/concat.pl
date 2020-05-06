use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::Rx::Subscription;
use Mojo::Rx::Utils 'get_subscription_from_subscriber';

use Scalar::Util 'weaken';

*Mojo::Rx::_rx_concat_helper = sub {
    my ($sources, $subscriber, $early_returns) = @_;

    @$sources or do {
        $subscriber->{complete}->() if defined $subscriber->{complete};
        return;
    };

    my $source = shift @$sources;

    my $own_subscription = Mojo::Rx::Subscription->new;
    @$early_returns = ($own_subscription);
    get_subscription_from_subscriber($subscriber)->add_dependents($early_returns);

    my $own_subscriber = {
        new_subscription => $own_subscription,
        next             => $subscriber->{next},
        error            => $subscriber->{error},
        complete         => sub {
            Mojo::Rx::_rx_concat_helper->($sources, $subscriber, $early_returns);
        },
    };

    $source->subscribe($own_subscriber);
};

*Mojo::Rx::rx_concat = sub {
    my (@sources) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my @sources = @sources;

        my $early_returns = [];
        get_subscription_from_subscriber($subscriber)->add_dependents($early_returns, sub { @sources = () });
        Mojo::Rx::_rx_concat_helper(\@sources, $subscriber, $early_returns);

        return;
    });
};

1;
