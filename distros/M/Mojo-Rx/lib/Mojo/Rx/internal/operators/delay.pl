use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::IOLoop;

# Two bugs: 1) script doesn't exit upon the subscriber receiving complete, and 2) delaying of(1, 2, 3) often
# shows fewer than 3 'next' values and not in the right order.

*Mojo::Rx::op_delay = sub {
    my ($delay) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $queue;
            my $own_subscriber = {
                map {
                    my $type = $_;

                    (
                        $type => sub {
                            my @value = @_;

                            if (! defined $queue) {
                                $queue = [];
                                Mojo::IOLoop->timer(0, sub {
                                    my @queue_copy = @$queue;
                                    undef $queue;
                                    Mojo::IOLoop->timer($delay, sub {
                                        foreach my $item (@queue_copy) {
                                            my ($type, $value_ref) = @$item;
                                            $subscriber->{$type}->(@$value_ref) if defined $subscriber->{$type};
                                        }
                                    });
                                });
                            }
                            push @$queue, [$type, \@value];
                        }
                    );
                } qw/ next error complete /
            };

            return $source->subscribe($own_subscriber);
        });
    };
};

1;
