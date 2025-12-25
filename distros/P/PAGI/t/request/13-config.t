#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use lib 'lib';
use PAGI::Request;

subtest 'default configuration' => sub {
    my $config = PAGI::Request->config;

    is(ref($config), 'HASH', 'config returns hashref');
    ok($config->{max_body_size} > 0, 'has max_body_size');
    ok($config->{spool_threshold} > 0, 'has spool_threshold');
};

subtest 'configure class defaults' => sub {
    # Save original
    my $original = { %{PAGI::Request->config} };

    PAGI::Request->configure(
        max_body_size   => 5 * 1024 * 1024,
        spool_threshold => 128 * 1024,
    );

    my $config = PAGI::Request->config;
    is($config->{max_body_size}, 5 * 1024 * 1024, 'max_body_size updated');
    is($config->{spool_threshold}, 128 * 1024, 'spool_threshold updated');

    # Restore
    PAGI::Request->configure(%$original);
};

done_testing;
