use strict;
use warnings;

use AnyEvent::HTTP qw(http_get);
use Plack::Builder;
use Plack::Loader;
use Test::More tests => 4;
use Test::TCP qw(test_tcp);
use Time::HiRes qw(time);

sub run_test {
    my ( $app ) = @_;

    test_tcp(
        client => sub {
            my ( $port ) = @_;

            my $cond = AnyEvent->condvar;

            my $nrequests = 2;

            for(1..2) {
                http_get "http://localhost:$port", sub {
                    my ( $data, $headers ) = @_;

                    $cond->send unless --$nrequests;
                };
            }

            my $start = time;
            $cond->recv;
            my $end = time;

            my $diff = $end - $start;

            ok $diff >= 5, "Two concurrent requests with a delay of five seconds should take no fewer than five seconds...";
            ok $diff <= 10, "...and no more than ten.";
        },
        server => sub {
            my ( $port ) = @_;

            Plack::Loader->load('Twiggy', port => $port)->run($app);
        },
    );
}

my $app = sub {
    return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Ok!'],
    ];
};

my $wrapped = builder {
    enable 'Delay', delay => 5, sleep_fn => sub {
        my ( $delay, $invoke ) = @_;

        my $timer;
        $timer = AnyEvent->timer(
            after => $delay,
            cb    => sub {
                undef $timer;
                $invoke->();
            },
        );
    };
    $app;
};

run_test $wrapped;

$app = sub {
    return sub {
        my ( $respond ) = @_;

        $respond->([
            200,
            ['Content-Type' => 'text/plain'],
            ['Ok!'],
        ]);
    };
};

$wrapped = builder {
    enable 'Delay', delay => 5, sleep_fn => sub {
        my ( $delay, $invoke ) = @_;

        my $timer;
        $timer = AnyEvent->timer(
            after => $delay,
            cb    => sub {
                undef $timer;
                $invoke->();
            },
        );
    };
    $app;
};

run_test $wrapped;
