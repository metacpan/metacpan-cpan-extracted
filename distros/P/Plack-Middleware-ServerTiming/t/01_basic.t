use strict;
use warnings;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;

my $app = builder {
    enable "ServerTiming";
    sub {
        my $env = shift;
        push @{$env->{'psgix.server-timing'}}, ['miss'];
        push @{$env->{'psgix.server-timing'}}, ['db', {dur => 53}];
        push @{$env->{'psgix.server-timing'}}, ['dc', {desc => 'atl'}];
        push @{$env->{'psgix.server-timing'}}, ['da', {dur => 99, desc => 'A B C'}];
        push @{$env->{'psgix.server-timing'}}, ['a', {desc => undef, wrongkey => 1}];
        return [200, ['Content-Type'=>'text/html'], ["Hello"]];
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    is $res->header('Server-Timing'), 'miss, db;dur=53, dc;desc=atl, da;dur=99;desc="A B C", a';
};

done_testing;
