#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use IO::Async::Loop;
use Net::Async::OpenExchRates;
use Future::AsyncAwait;
use Time::Moment;

require Log::Any::Adapter;
my $log_level = 'info';
Log::Any::Adapter->set( qw(Stdout), log_level => $log_level );
use Log::Any qw($log);

my $loop = IO::Async::Loop->new;
$loop->add( my $exch = Net::Async::OpenExchRates->new(
        app_id => $ENV{APP_ID},
        # Those parameters are set to 1 by default
        # just for extra clarification
        use_cache => 1,
        cache_size => 1024,
        enable_pre_validation => 1,
        respect_api_frequency => 1
    )
);

async sub subscribe {
    my $symbol = shift;
    while (1) {
        my ( $latest, $app_usage, $app_status, $frequency ) = await Future->needs_all(
            $exch->latest(),
            $exch->app_usage(),
            $exch->app_status(),
            $exch->plan_update_frequency(),
        );
        my $timestamp = Time::Moment->from_epoch($latest->{timestamp});
        my $now = Time::Moment->now();
        $log->infof('New Rate for %s (%f) from base %s, last updated at: %s | now: %s',
            $symbol,
            $latest->{rates}{$symbol},
            $latest->{base},
            $timestamp->to_string(),
            $now->to_string(),
        );
        my $wait = $frequency - $timestamp->delta_seconds($now);

        # This logic is built in Net::Async::OpenExchRates
        # When C<respect_api_frequecy> parameter is set
        # logic of returning from cache rather than API request
        # depending on your C<APP_ID> plan update frequency
        $log->infof('Your APP_ID subscription plan update frequency: %ds | waiting for: %d',
            $frequency, $wait
        );

        $log->infof('** Your App Status is: -- %s -- **', $app_status);
        $log->infof('App Usage: ** %s** -> %s', $_, $app_usage->{$_}) for $exch->app_usage_keys()->@*;
        await $loop->delay_future(after => $wait) if $wait > 0;
    }
}

subscribe('CAD')->get;

1;
