#!perl -w
use strict;
use Test::More;
use Plack::Test::Suite;
use HTTP::Request::AsCGI;

use Plack::Handler::CLI;

Plack::Test::Suite->runtests(sub {
    my ($name, $test, $app) = @_;

    note $name;
    my $cb = sub {
        my($req) = @_;

        my $cgi = HTTP::Request::AsCGI->new($req);
        my $c = $cgi->setup;
        Plack::Handler::CLI->new->run($app);
        my $res = $c->response;
        $res->request($req);

        $res;
    };

    $test->($cb);
});

done_testing;
