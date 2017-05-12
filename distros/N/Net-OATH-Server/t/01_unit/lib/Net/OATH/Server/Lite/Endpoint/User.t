use strict;
use warnings;

use Test::More;
use Plack::Test;

use JSON::XS qw/encode_json decode_json/;

use lib 't/lib/lite';
use TestDataHandler;
use Dummy;

use Net::OATH::Server::Lite::Endpoint::User;

my $app = Net::OATH::Server::Lite::Endpoint::User->new(
   data_handler => q{TestDataHandler}, 
);

subtest q{basic} => sub {
    my ($id, $secret);

    subtest q{create} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "create" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 201, q{code});
            my $content = decode_json($res->content);
            ok ($content, q{response is decoded});
            ok ($content->{id}, q{id});
            $id = $content->{id};
            ok ($content->{secret}, q{secret(base32 encoded)});
            $secret = $content->{secret};
        };
    };

    subtest q{read} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "read", id => $id };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 200, q{code});
            my $content = decode_json($res->content);
            ok ($content, q{response is decoded});
            is ($content->{id}, $id, q{id});
            is ($content->{secret}, $secret, q{secret(base32 encoded)});
        };
    };

    subtest q{update} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "update", id => $id, type => q{hotp}, counter => 10 };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 200, q{code});
            my $content = decode_json($res->content);
            ok ($content, q{response is decoded});
            is ($content->{id}, $id, q{id});
            is ($content->{secret}, $secret, q{secret(base32 encoded)});
            is ($content->{type}, q{hotp}, q{type});
            is ($content->{counter}, 10, q{counter});
        };
    };

    subtest q{delete} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "delete", id => $id };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 200, q{code});
            is ($res->content, q{\{\}}, q{response});
        };
    };

    subtest q{read after delete} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "read", id => $id };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 404, q{code});
            my $content = decode_json($res->content);
            ok ($content, q{response is decoded});
            is ($content->{error}, q{invalid_request}, q{error});
            is ($content->{error_description}, q{invalid id}, q{error_description});
        };
    };
};

subtest q{error} => sub {

    my $app_dummy = Net::OATH::Server::Lite::Endpoint::User->new(
        data_handler => q{Dummy}, 
    );

    test_psgi $app_dummy, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/user');
        $req->content_type('application/json');
        $req->content('{}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 500, q{code});
        is ($res->content, '{"error":"server_error"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/user');
        $req->content('invalid');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        is ($res->content, '{"error":"invalid_request"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/user');
        my $params = { method => "invalid" };
        $req->content(encode_json($params));
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 400, q{code});
        my $error = decode_json($res->content);
        is_deeply ($error, {"error" => "invalid_request", "error_description" => "method not found"}, q{content});
    };

    subtest q{create} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "create", id => "1" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 400, q{code});
            is ($res->content, '{"error":"invalid_request"}', q{content});
        };

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            my $params = { method => "create", type => "invalid" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 400, q{code});
            is ($res->content, '{"error":"invalid_request"}', q{content});
        };

        my $dh = TestDataHandler->new;
        $dh->set_force_return_false;

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            $req->content('{"method":"create"}');
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 500, q{code});
            is ($res->content, '{"error":"server_error"}', q{content});
        };

        $dh->unset_force_return_false;
    };

    subtest q{read} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "read" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 400, q{code});
            my $error = decode_json($res->content);
            is_deeply ($error, {"error" => "invalid_request", "error_description" => "missing id"}, q{content});
        };

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            my $params = { method => "read", id => "invalid" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 404, q{code});
            my $error = decode_json($res->content);
            is_deeply ($error, {"error" => "invalid_request", "error_description" => "invalid id"}, q{content});
        };
    };

    subtest q{update} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "update" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 400, q{code});
            my $error = decode_json($res->content);
            is_deeply ($error, {"error" => "invalid_request", "error_description" => "missing id"}, q{content});
        };

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "update", id => "invalid" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 404, q{code});
            my $error = decode_json($res->content);
            is_deeply ($error, {"error" => "invalid_request", "error_description" => "invalid id"}, q{content});
        };

        my $user = Net::OATH::Server::Lite::Model::User->new(
                       id => q{1},
                       secret => q{secret},
                   );
        my $dh = TestDataHandler->new;
        $dh->insert_user($user);

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "update", id => "1", type => "invalid" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 400, q{code});
            is ($res->content, '{"error":"invalid_request"}', q{content});
        };

        $dh->set_force_return_false;

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "update", id => "1", type => "hotp" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 500, q{code});
            is ($res->content, '{"error":"server_error"}', q{content});
        };

        $dh->unset_force_return_false;
    };

    subtest q{delete} => sub {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "delete" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 400, q{code});
            my $error = decode_json($res->content);
            is_deeply ($error, {"error" => "invalid_request", "error_description" => "missing id"}, q{content});
        };

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "delete", id => "invalid" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 404, q{code});
            my $error = decode_json($res->content);
            is_deeply ($error, {"error" => "invalid_request", "error_description" => "invalid id"}, q{content});
        };

        my $dh = TestDataHandler->new;
        $dh->set_force_return_false;

        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => 'http://localhost/user');
            $req->content_type('application/json');
            my $params = { method => "delete", id => "1" };
            $req->content(encode_json($params));
            my $res = $cb->($req);

            ok ($res, q{response});
            is ($res->code, 500, q{code});
            is ($res->content, '{"error":"server_error"}', q{content});
        };

        $dh->unset_force_return_false;
    };
};

done_testing;
