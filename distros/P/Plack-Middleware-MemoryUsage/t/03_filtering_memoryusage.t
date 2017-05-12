# -*- mode: cperl -*-
use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = builder {
    enable "MemoryUsage",
        packages => ['Plack::Middleware'],
        callback => sub {
            my ($env, $res, $before, $after, $diff) = @_;
            my $packages_count = scalar(keys %$diff);
            Plack::Util::header_set($res->[1], 'X-MemoryUsage-Count', $packages_count);
        };
    sub {
        my $env = shift;
        [ 200, [ 'Content-Type', 'text/plain'], ["ok"] ];
    };
};
test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "ok";
    is $res->header("X-MemoryUsage-Count"), 2;
};

done_testing;
