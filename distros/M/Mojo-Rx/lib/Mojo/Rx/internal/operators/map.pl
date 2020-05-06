use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::op_map = sub {
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
};

1;
