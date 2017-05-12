# package t::builder;
use warnings;
use strict;

use Test::More tests => 10;
use Plack::Builder;
use Plack::Test;
use Plack::Middleware::ServerStatus::Availability;
use HTTP::Request;

my $file = './up';
my $status = '/server/avail';
my $control = '/server/control/avail';

unlink $file;

my $app = builder {
    enable 'ServerStatus::Availability', (
        path => {
            status  => $status,
            control => $control,
        },
        allow => [],
        file => $file,
    );
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;

        my $avail = HTTP::Request->new(GET => "http://localhost$status");
        my $action = { map {
            my $url = "http://localhost$control?action=$_";
            $_ => HTTP::Request->new(POST => $url);
        } qw(up down invalid) };

        do {
            ok my $res = $cb->($avail);
            is $res->code, 403;
        };

        do {
            ok my $res = $cb->($action->{up});
            is $res->code, 403;
        };

        do {
            ok my $res = $cb->($action->{down});
            is $res->code, 403;
        };

        do {
            ok my $res = $cb->($action->{invalid});
            is $res->code, 403;
        };

        do {
            ok my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
            is $res->code, 200;
        };
    };

unlink $file;
