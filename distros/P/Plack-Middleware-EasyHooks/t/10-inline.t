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
                before => sub {
                    my ($env) = @_;

                    $path = $env->{PATH_INFO};
                },
                after => sub {
                    my ($env, $res) = @_;
                    $status = $res->[0];
                },
                filter => sub {
                    my ($env, $chunk) = @_;
                    $env->{length} += length $chunk;

                    return uc($chunk);
                },
                tail => sub {
                    return "baz";
                },
                finalize => sub {
                    my ($env) = @_;

                    $length = $env->{length};
                };

            $apps{$appname};
        },
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "/foo" );

            is($path, "/foo",              "$appname: Path was collected                (before)");
            is($status, 200,               "$appname: Status code was collected         (after)");
            is($res->content, "FOOBARbaz", "$appname: Content got uppercased and tailed (filter+tail)");
            is($length, 6,                 "$appname: Length was calculated             (finalize)")
        },
    );
}

done_testing( 4 * scalar( keys %apps ) );


