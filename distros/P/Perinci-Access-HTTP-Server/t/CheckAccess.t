#!perl

package main;

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Plack::Builder;
use Plack::Test;

test_CheckAccess_middleware(
    name => "allow_log=0 (default)",
    args => {},
    requests => [
        {args => [GET => '/Foo'], allowed => 1},
        {args => [GET => '/Foo?-riap-loglevel=1'], allowed => 0},
    ],
);
test_CheckAccess_middleware(
    name => "allow_log=1",
    args => {allow_log=>1},
    requests => [
        {args => [GET => '/Foo?-riap-loglevel=1'], allowed => 1},
    ],
);

test_CheckAccess_middleware(
    name => "allow_uri, deny_uri",
    args => {allow_uri=>['/Foo/a', '/Foo/x'], deny_uri=>qr/x/},
    requests => [
        {args => [GET => '/Foo/a?x=1'], allowed => 1},
        {args => [GET => '/Foo/x'],     allowed => 0},
        {args => [GET => '/Foo/a/x'],   allowed => 0},
    ],
);
test_CheckAccess_middleware(
    name => "allow_uri_scheme, deny_uri_scheme",
    args => {allow_uri_scheme=>['pl', 'a', 'ax'], deny_uri_scheme=>qr/x/},
    requests => [
        {args => [GET => '/1', ["X-Riap-URI"=>"/x"]]  , allowed => 1},
        {args => [GET => '/2', ["X-Riap-URI"=>"a:1"]] , allowed => 1},
        {args => [GET => '/3', ["X-Riap-URI"=>"ax:1"]], allowed => 0},
    ],
);
test_CheckAccess_middleware(
    name => "allow_action, deny_action",
    args => {allow_action=>['a', 'ax'], deny_action=>qr/x/},
    requests => [
        {args => [GET => '/1', ["X-Riap-Action"=>"a"]]  , allowed => 1},
        {args => [GET => '/2', ["X-Riap-Action"=>"ax"]] , allowed => 0},
        {args => [GET => '/3', ["X-Riap-Action"=>"x"]]  , allowed => 0},
    ],
);

done_testing;

sub test_CheckAccess_middleware {
    my %args = @_;

    my $app = builder {
        enable "PeriAHS::ParseRequest";
        #enable sub {
        #    my $app=shift;
        #    sub {
        #        my $env=shift;
        #        diag explain $env->{"riap.request"};
        #        $app->($env);
        #    }
        #};
        enable "PeriAHS::CheckAccess", %{$args{args}};

        sub {
            my $env = shift;
            return [
                200,
                ['Content-Type' => 'text/plain'],
                ['Allowed']
            ];
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        subtest $args{name} => sub {
            for my $test (@{$args{requests}}) {
                my $name = $test->{name} //
                    $test->{args}[1].($test->{allowed} ? " not":"")." allowed";
                subtest $name => sub {
                    my $res = $cb->(HTTP::Request->new(@{$test->{args}}));

                    is($res->code, $test->{status} // 200, "status")
                        or diag $res->as_string;

                    if ($test->{allowed}) {
                        is($res->content, "Allowed", "allowed page");
                    } else {
                        like($res->content, qr/403/, "forbidden page");
                    }

                    done_testing;
                };
            }
            done_testing;
        };

    };
}
