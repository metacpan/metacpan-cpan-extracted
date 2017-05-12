use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $app = sub {
    my $env = shift;

    is $env->{'PATH_INFO'}, '/hello/world', 'No multiple slashes';

    [ 200, [ 'Content-Type' => 'text/plain' ], ['OK'] ];
};

$app = builder {
    enable 'Plack::Middleware::NoMultipleSlashes';
    $app;
};

test_psgi $app, sub {
    my $cb   = shift;
    my @reqs = (
        '/hello/world',
        '/hello//world',
        '/hello///world',
        '/hello////world',
        '/hello/////world',
    );

    $cb->( GET $_ ) for @reqs;
};


