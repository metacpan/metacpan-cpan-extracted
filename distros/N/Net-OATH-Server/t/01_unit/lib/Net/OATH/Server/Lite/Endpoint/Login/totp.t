use strict;
use warnings;

use Test::More;
use Test::MockTime;
use Plack::Test;

use Net::OATH::Server::Lite::Model::User;

use lib 't/lib/lite';
use TestDataHandler;

use Net::OATH::Server::Lite::Endpoint::Login;

my $time_for_test = 1388502000; # 2014/1/1 00:00:00
Test::MockTime::set_fixed_time($time_for_test);

my $app = Net::OATH::Server::Lite::Endpoint::Login->new(
   data_handler => q{TestDataHandler}, 
);

subtest q{algorithm} => sub {

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret_for_algorithm},
                   algorithm => q{MD5},
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"888636"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    # TODO: Support SHA256, SHA512
    $dh->clean_user_for_test();
};

subtest q{digits} => sub {

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret},
                   digits => 8,
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"69446275"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    $dh->clean_user_for_test();
};

subtest q{period} => sub {

    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{1},
                   secret => q{secret},
                   period => 60,
               );
    my $dh = TestDataHandler->new;
    $dh->insert_user($user);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/login');
        $req->content_type('application/json');
        $req->content('{"id":"1", "password":"147347"}');
        my $res = $cb->($req);

        ok ($res, q{response});
        is ($res->code, 200, q{code});
        is ($res->content, '{"id":"1"}', q{content});
    };

    $dh->clean_user_for_test();
};

done_testing;
