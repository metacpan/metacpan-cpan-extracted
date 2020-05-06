#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::rx_of = sub {
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
};

1;
