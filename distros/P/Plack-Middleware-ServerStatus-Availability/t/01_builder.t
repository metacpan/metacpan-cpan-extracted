# package t::builder;
use warnings;
use strict;

use Test::More tests => 5;
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
        allow => '0.0.0.0/0',
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

        subtest 'Server is under maintenance at first' => sub {
            do {
                ok my $res = $cb->($avail);
                is $res->code, 503;
                like $res->content, qr/maintenance/;
            };
        };

        subtest 'Server becomes available after `up` action' => sub {
            do {
                ok my $res = $cb->($action->{up});
                is $res->code, 200;
                like $res->content, qr/Done/;
            };

            do {
                ok my $res = $cb->($avail);
                is $res->code, 200;
                like $res->content, qr/OK/;
            };
        };

        subtest 'Multiple `up` actions have no effect' => sub {
            do {
                ok my $res = $cb->($action->{up});
                is $res->code, 200;
                like $res->content, qr/Done/;
            };

            do {
                ok my $res = $cb->($avail);
                is $res->code, 200;
                like $res->content, qr/OK/;
            };
        };

        subtest 'Server becomes unavailable again after `down` action' => sub {
            do {
                ok my $res = $cb->($action->{down});
                is $res->code, 200;
                like $res->content, qr/Done/;
            };

            do {
                ok my $res = $cb->($avail);
                is $res->code, 503;
                like $res->content, qr/maintenance/;
            };
        };

        subtest 'Bad action' => sub {
            do {
                ok my $res = $cb->($action->{invalid});
                is $res->code, 400;
                like $res->content, qr/Bad action/;
            };
        };
    };

unlink $file;
