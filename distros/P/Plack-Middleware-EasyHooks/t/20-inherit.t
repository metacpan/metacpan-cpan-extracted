#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

use t::Apps qw(%apps);
use t::Middleware::Inherit;

for my $appname (keys %apps) {
    test_psgi(
        app => builder {
            enable "+t::Middleware::Inherit";

            $apps{$appname};
        },
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "/foo" );

            is($t::Middleware::Inherit::path, "/foo", "$appname: Path was collected                (before)");
            is($t::Middleware::Inherit::status, 200,  "$appname: Status code was collected         (after)");
            is($res->content, "FOOBARbaz",            "$appname: Content got uppercased and tailed (filter+tail)");
            is($t::Middleware::Inherit::length, 6,    "$appname: Length was calculated             (finalize)")
        },
    );
}

done_testing( 4 * scalar( keys %apps ) );

1;

