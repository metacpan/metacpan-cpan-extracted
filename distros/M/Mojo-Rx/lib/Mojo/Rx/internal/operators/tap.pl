use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

use Scalar::Util 'reftype';

*Mojo::Rx::op_tap = sub {
    my @args = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my @args = @args;
            my $tap_subscriber = $args[0] if (reftype($args[0]) // '') eq 'HASH';
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
};

1;
