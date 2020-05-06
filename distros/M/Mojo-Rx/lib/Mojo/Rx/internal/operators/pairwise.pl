use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::op_pairwise = sub {
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
};

1;
