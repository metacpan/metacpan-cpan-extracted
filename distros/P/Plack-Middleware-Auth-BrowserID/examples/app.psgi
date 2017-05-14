#!perl

use 5.012;
use warnings;

use lib qw{ ./lib/ ../lib/ };

use Plack::Builder;
use Plack::Session;

use Dancer2;

use MyApp;
require Mojolicious::Commands;
my $app = Mojolicious::Commands->start_app('MyApp');

my $app2 = sub {
    my $env     = shift;
    my $session = Plack::Session->new($env);

    my $data = 'Hello! ' . $session->get('email');
    return [ 200, [ 'Content-type' => 'text' ], [$data] ];
};

builder {
    enable 'Session', store => 'File';

    mount '/auth' => builder {
        enable 'Auth::BrowserID', audience => 'http://localhost:8082/';
    };

    mount '/'      => $app;
    mount '/hello' => $app2;
    mount '/dance' => builder {
        eval 'use MyApp::Bar';
        start;
    };
};
