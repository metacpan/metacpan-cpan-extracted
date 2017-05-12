use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More tests => 4;
use Time::HiRes qw(time);

my $app = sub {
    return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Ok!'],
    ];
};

my $wrapped = builder {
    enable 'Delay', delay => 1;
    $app;
};

test_psgi $wrapped, sub {
    my ( $cb ) = @_;

    my $start = time;
    $cb->(GET '/');
    my $end = time;

    ok $end - $start >= 1, "A request delayed by a second should take longer than a second to complete";
};

$wrapped = builder {
    enable 'Delay', delay => 3;
    $app;
};

test_psgi $wrapped, sub {
    my ( $cb ) = @_;

    my $start = time;
    $cb->(GET '/');
    my $end = time;

    ok $end - $start >= 3, "A request delayed by three seconds should take longer than three seconds to complete";
};

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
    enable 'Delay', delay => 1;
    $app;
};

test_psgi $wrapped, sub {
    my ( $cb ) = @_;

    my $start = time;
    $cb->(GET '/');
    my $end = time;

    ok $end - $start >= 1, "A request delayed by a second should take longer than a second to complete";
};

$wrapped = builder {
    enable 'Delay', delay => 3;
    $app;
};

test_psgi $wrapped, sub {
    my ( $cb ) = @_;

    my $start = time;
    $cb->(GET '/');
    my $end = time;

    ok $end - $start >= 3, "A request delayed by three seconds should take longer than three seconds to complete";
};
