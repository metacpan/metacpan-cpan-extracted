#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

use t::Apps qw(%apps);

for my $appname (keys %apps) {
    my $path;
    my $length;
    my $status;

    test_psgi(
        app => builder {
            enable "Plack::Middleware::EasyHooks",
                after => sub {
                    my ($env, $res) = @_;

                    $res->[0] = 203;
                    Plack::Util::header_remove($res->[1], "My-Second-Header");
                    Plack::Util::header_set($res->[1], "My-Third-Header", 3);
                };

            $apps{$appname};
        },
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "/foo" );

            is($res->code, 203,               "$appname: Status code was changed (inline)");
            ok(
                $res->header("My-First-Header") eq "1" &&
                $res->header("My-Third-Header") eq "3" &&
                !defined( $res->header("My-Second-Header") ),
                "$appname: Headers was changed (inline)"
            );
        },
    );

    test_psgi(
        app => builder {
            enable "Plack::Middleware::EasyHooks",
                after => sub {
                    my ($env, $res) = @_;

                    return [ 
                        203,
                        [
                            "My-First-Header" => Plack::Util::header_get($res->[1], "My-First-Header"),
                            "My-Third-Header" => 3,
                        ],
                        $res->[2]
                    ];
                };

            $apps{$appname};
        },
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "/foo" );

            is($res->code, 203,               "$appname: Status code was changed (overwrite)");
            ok(
                $res->header("My-First-Header") eq "1" &&
                $res->header("My-Third-Header") eq "3" &&
                !defined( $res->header("My-Second-Header") ),
                "$appname: Headers was changed (overwrite)"
            );
        },
    );
}

done_testing( 4 * scalar( keys %apps ) );


