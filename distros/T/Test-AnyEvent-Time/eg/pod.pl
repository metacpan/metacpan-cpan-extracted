use strict;
use warnings;

use AnyEvent;

sub your_asynchronous_func {
    my (%params) = @_;
    my $w; $w = AnyEvent->timer(
        after => $params{data},
        cb => sub {
            undef $w;
            $params{cb}->($params{data} + 100);
        }
    );
}


use Test::AnyEvent::Time tests => 4;
use Test::More;


time_within_ok sub {
    my $cv = shift;
    your_asynchronous_func(
        data => 0.5,
        cb => sub {
            my ($result) = @_;
            note "This is the result: $result";

            ## Notify that this function is done.
            $cv->send();
        }
    );
}, 10, "your_asynchronous_func() should return its result within 10 seconds.";


time_within_ok sub {
    my $cv = shift;
    your_asynchronous_func(
        data => 1,
        cb => sub {
            ## Oops! I forgot to signal the CV!
        }
    );
}, 4, "Timeout in 4 seconds and the test fails";


time_between_ok sub {
    my $cv = shift;
    your_asynchronous_func(
        data => 1,
        cb => sub { $cv->send() }
    );
}, 0.3, 1.5, "your_asynchronous_func() should return in between 0.3 seconds and 1.5 seconds";


time_cmp_ok sub {
    my $cv = shift;
    your_asynchronous_func(
        data => 1,
        cb => sub { $cv->send() }
    );
}, ">", 0.3, "your_asynchronous_func() should take more than 0.3 seconds. No timeout set.";


## You can just measure the time your asynchronous function takes.
my $time = elapsed_time sub {
    my $cv = shift;
    your_asynchronous_func(
        data => 5,
        cb => sub { $cv->send }
    );
};
note("It takes $time seconds.");




