use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::op_filter = sub {
    my ($filtering_sub) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = { %$subscriber };
            $own_subscriber->{next} &&= sub {
                my $passes = eval { $filtering_sub->(@_) };
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
};

1;
