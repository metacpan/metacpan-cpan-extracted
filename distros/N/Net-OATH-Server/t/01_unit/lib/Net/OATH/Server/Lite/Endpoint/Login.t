use strict;
use warnings;

use Test::More;
use Test::MockTime;
use Plack::Test;
use JSON::XS qw/decode_json/;

use Net::OATH::Server::Lite::Endpoint::Login;
use Net::OATH::Server::Lite::Model::User;

use lib 't/lib/lite';
use TestDataHandler;
use Dummy;

my $time_for_test = 1388502000; # 2014/1/1 00:00:00
Test::MockTime::set_fixed_time($time_for_test);

my $app = Net::OATH::Server::Lite::Endpoint::Login->new(
   data_handler => q{TestDataHandler}, 
);

subtest q{success} => sub {

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret},
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"446275"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    $dh->clean_user_for_test();
};

# TODO: Error Cases
subtest q{error} => sub {

    my $app_dummy = Net::OATH::Server::Lite::Endpoint::Login->new(
        data_handler => q{Dummy}, 
    );

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret},
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app_dummy, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"446275"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 500, q{code});
        is ($res->content, '{"error":"server_error"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/login');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        is ($res->content, '{"error":"invalid_request"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content('not_json_data');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        is ($res->content, '{"error":"invalid_request"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"password":"446275"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        my $error = decode_json($res->content);
        is_deeply ($error, {"error" => "invalid_request", "error_description" => "missing id"}, q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        my $error = decode_json($res->content);
        is_deeply ($error, {"error" => "invalid_request", "error_description" => "missing password"}, q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"2", "password":"446275"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 404, q{code});
        my $error = decode_json($res->content);
        is_deeply ($error, {"error" => "invalid_request", "error_description" => "invalid id"}, q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"dummy", "password":"446275"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 500, q{code});
        is ($res->content, '{"error":"server_error"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"000000"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        my $error = decode_json($res->content);
        is_deeply ($error, {"error" => "invalid_request", "error_description" => "invalid password"}, q{content});
    };

    $dh->clean_user_for_test();
};

done_testing;
