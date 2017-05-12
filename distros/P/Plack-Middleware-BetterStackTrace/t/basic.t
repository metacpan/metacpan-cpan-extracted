# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Test::More;
use Plack::Middleware::BetterStackTrace;
use Plack::Test;
use HTTP::Request::Common;

my $traceapp = Plack::Middleware::BetterStackTrace->wrap(
    sub { die "orz" },
    no_print_errors => 1
);
my $app = sub {
    my $env = shift;
    my $ret = $traceapp->($env);
    like $env->{'plack.stacktrace.text'}, qr/orz/;
    return $ret;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    $req->header(Accept => "text/html,*/*");
    my $res = $cb->($req);

    ok $res->is_error;
    is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
    like $res->content, qr/<title>orz/;
};

done_testing;
