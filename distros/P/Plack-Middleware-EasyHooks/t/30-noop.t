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
            enable "Plack::Middleware::EasyHooks";

            $apps{$appname};
        },
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "/foo" );

            is($res->code, 200,         "$appname: Status code was collected         (after)");
            is($res->content, "foobar", "$appname: Content got uppercased and tailed (filter+tail)");
        },
    );
}

done_testing( 2 * scalar( keys %apps ) );


