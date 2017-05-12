use strict;
use warnings;

use Test::More;
use Plack::Test;

use Net::OATH::Server::Lite::Model::User;

use lib 't/lib/lite';
use TestDataHandler;

use Net::OATH::Server::Lite::Endpoint::Login;

my $app = Net::OATH::Server::Lite::Endpoint::Login->new(
   data_handler => q{TestDataHandler}, 
);

subtest q{algorithm} => sub {

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret_for_algorithm},
                   type => q{hotp},
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"476423", "counter":0}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    $user->algorithm(q{MD5});
    $dh->update_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"116386", "counter":0}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    # TODO: Support SHA256, SHA512
    $dh->clean_user_for_test();
};

subtest q{counter} => sub {

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret},
                   type => q{hotp},
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"814628"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"533881"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    # reset counter
    $user->counter(0);
    $dh->update_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"814628", "counter":"0"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"533881", "counter":"1"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    # if counter param exists, user's count is not updated.
    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"814628"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"533881"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    $dh->clean_user_for_test();
};

done_testing;
