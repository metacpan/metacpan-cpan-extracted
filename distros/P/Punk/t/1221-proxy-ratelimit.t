#!perl
use strict;
use warnings;
use FindBin ();
# Prefer the sibling Hyperman build, as t/1220-ratelimit.t does: the arena and
# ABI v3 land there first and an installed copy may still be v2.
use lib "$FindBin::Bin/../../Hyperman/blib/lib";
use lib "$FindBin::Bin/../../Hyperman/blib/arch";
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# The bug this whole phase exists for, asserted end to end.
#
# rate_limit keys on REMOTE_ADDR, and Hyperman's arena makes the counter EXACT
# across the worker pool rather than per worker. So behind a proxy, where
# REMOTE_ADDR is the proxy for every request, a limit is not merely
# approximate - every client on the internet shares ONE bucket and a 100/min
# rule throttles the entire site at 100/min. With `proxy` declared the same
# app keys on the real client and the buckets separate.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman not available';
    plan skip_all => 'Hyperman ABI < 3 (no arena; build/install the local Hyperman)'
        unless Hyperman->can('_abi_version') && Hyperman::_abi_version() >= 3;
    Hyperman::_abi_selftest();   # maps the shared arena as a side effect
}

# Every run needs its own counter namespace: the arena outlives a single
# app, so a fixed tag would collide with the previous run's budget.
our $TAG = "proxytest$$";

# ---- without `proxy`: one shared bucket ------------------------------------

{
    package Shared;
    use Punk;
    rate_limit limit => 3, window => 60, by => 'ip', tag => "$main::TAG-shared";
    get '/' => sub { $_[0]->text('ok') };
    package main;
}
{
    my $app = Shared->to_app;
    # Three DIFFERENT clients arriving through the same proxy.
    my @st = map {
        hit($app, env => { REMOTE_ADDR         => '10.0.0.1',
                           HTTP_X_FORWARDED_FOR => "203.0.113.$_" })->[0]
    } 1 .. 4;
    is_deeply([ @st[0 .. 2] ], [ 200, 200, 200 ],
              'three distinct clients spend the budget between them');
    is $st[3], 429,
       'the fourth distinct client is refused: one bucket for everybody, '
     . 'which is the failure `proxy` fixes';
}

# ---- with `proxy`: a bucket per real client --------------------------------

{
    package Trusted;
    use Punk;
    proxy;
    rate_limit limit => 3, window => 60, by => 'ip', tag => "$main::TAG-trusted";
    get '/' => sub { $_[0]->text('ok') };
    package main;
}
{
    my $app = Trusted->to_app;
    my @st = map {
        hit($app, env => { REMOTE_ADDR          => '10.0.0.1',
                           HTTP_X_FORWARDED_FOR => "198.51.100.$_" })->[0]
    } 1 .. 4;
    is_deeply(\@st, [ 200, 200, 200, 200 ],
              'four distinct clients through one proxy each get their own budget');

    # and one client can still be limited on its own
    my @same = map {
        hit($app, env => { REMOTE_ADDR          => '10.0.0.1',
                           HTTP_X_FORWARDED_FOR => '198.51.100.77' })->[0]
    } 1 .. 4;
    is_deeply([ @same[0 .. 2] ], [ 200, 200, 200 ],
              'a single client still gets exactly its limit');
    is $same[3], 429, '...and is refused past it';
}

# ---- the forged header cannot buy a fresh budget ---------------------------

# A client that has spent its budget tries to escape it by prepending an
# address of its own. The proxy still appends the address it saw, and the hop
# count reads from the right, so the forgery changes nothing.
{
    package Forge;
    use Punk;
    proxy;
    rate_limit limit => 2, window => 60, by => 'ip', tag => "$main::TAG-forge";
    get '/' => sub { $_[0]->text('ok') };
    package main;
}
{
    my $app = Forge->to_app;
    my $real = '198.51.100.200';

    my @st = map {
        hit($app, env => { REMOTE_ADDR          => '10.0.0.1',
                           HTTP_X_FORWARDED_FOR => $real })->[0]
    } 1 .. 3;
    is_deeply(\@st, [ 200, 200, 429 ], 'the client spends its budget');

    my $spoof = hit($app, env => {
        REMOTE_ADDR          => '10.0.0.1',
        HTTP_X_FORWARDED_FOR => "1.2.3.4, $real",   # client prepended a lie
    });
    is $spoof->[0], 429,
       'prepending a forged entry does not buy a fresh rate-limit bucket';
}

done_testing;
