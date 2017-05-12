# -*- mode: cperl -*-
use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = builder {
    enable "MemoryUsage", callback => sub {
        my ($env, $res, $before, $after, $diff) = @_;
        my $delta = 0;
        $delta += $_ for values %$diff;
        Plack::Util::header_set($res->[1], 'X-MemoryUsage-Delta', $delta);
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
    like $res->header("X-MemoryUsage-Delta"), qr/^[1-9][0-9]+$/;
};

done_testing;
