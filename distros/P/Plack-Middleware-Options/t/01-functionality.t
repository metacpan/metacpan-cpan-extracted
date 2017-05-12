use strict;
use warnings;

use Plack::Builder;
use Plack::Test;
use Test::Deep;
use Test::More;

my @methods = qw/GET POST PUT HEAD DELETE TRACE CONNECT/;

plan tests => 59;

my $app = sub {
    [ 200, [ 'Content-Type' => 'text/plain' ], ['body!'] ];
};

test_psgi
    app => builder {
        enable 'Options';
        $app;
    },
    client => sub {
        my ( $cb ) = @_;

        my $req = HTTP::Request->new(OPTIONS => '/');
        my $res = $cb->($req);
        is $res->code, 200;
        my @allowed = split /[,\s]+/, $res->header('Allow');
        cmp_bag \@methods, \@allowed;
        foreach my $method (@methods) {
            $req = HTTP::Request->new($method => '/');
            $res = $cb->($req);
            is $res->code, 200;
            is $res->content, 'body!';
        }
    };

my @ok     = qw/GET HEAD/;
my @not_ok = qw/PUT POST DELETE TRACE CONNECT/;
test_psgi
    app => builder {
        enable 'Options', allowed => \@ok;
        $app;
    },
    client => sub {
        my ( $cb ) = @_;
        my $req = HTTP::Request->new(OPTIONS => '/');
        my $res = $cb->($req);
        is $res->code, 200;
        my @allowed = split /[,\s]+/, $res->header('Allow');
        cmp_bag \@allowed, \@ok;

        foreach my $method (@ok) {
            $req = HTTP::Request->new($method => '/');
            $res = $cb->($req);
            is $res->code, 200;
            is $res->content, 'body!';
        }
        foreach my $method (@not_ok) {
            $req = HTTP::Request->new($method => '/');
            $res = $cb->($req);
            is $res->code, 405;
            is $res->content, 'Method not allowed';
            @allowed = split /[,\s]+/, $res->header('Allow');
            cmp_bag \@allowed, \@ok;
        }
    };

@ok     = qw/GET POST PUT/;
@not_ok = qw/HEAD DELETE TRACE CONNECT/;
test_psgi
    app => builder {
        enable 'Options', allowed => {
            GET  => 1,
            POST => undef,
            PUT  => 0,
        };
        $app;
    },
    client => sub {
        my ( $cb ) = @_;

        my $req = HTTP::Request->new(OPTIONS => '/');
        my $res = $cb->($req);
        is $res->code, 200;
        my @allowed = split /[,\s]+/, $res->header('Allow');
        cmp_bag \@allowed, \@ok;

        foreach my $method (@ok) {
            $req = HTTP::Request->new($method => '/');
            $res = $cb->($req);
            is $res->code, 200;
            is $res->content, 'body!';
        }
        foreach my $method (@not_ok) {
            $req = HTTP::Request->new($method => '/');
            $res = $cb->($req);
            is $res->code, 405;
            is $res->content, 'Method not allowed';
            @allowed = split /[,\s]+/, $res->header('Allow');
            cmp_bag \@allowed, \@ok;
        }

        SKIP: {
            skip "I don't know how to set Request-URI to '*'", 2;

            $req = HTTP::Request->new(OPTIONS => '*');
            $res = $cb->($req);
            is $res->code, 200;
            cmp_bag \@allowed, \@methods;
        };
    };
