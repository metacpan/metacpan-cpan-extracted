#!/usr/bin/env perl

use v5.36;
use Test::More;

eval { require CHI; 1 }
    or plan skip_all => 'CHI is required for testing CHI store';

use PAGI::FastAPI::RateLimit::Driver::CHI;

subtest 'CHI driver initialisation and basic tracking' => sub {
    my $chi = CHI->new(
        driver => 'Memory',
        global => 1,
    );

    my $driver = PAGI::FastAPI::RateLimit::Driver::CHI->new( chi => $chi );
    isa_ok( $driver, 'PAGI::FastAPI::RateLimit::Driver::CHI' );

    # 1. First request
    my $count1 = $driver->increment_async( 'client_1', 60 )->get;
    is( $count1, 1, 'First hit count is 1' );

    # 2. Second request
    my $count2 = $driver->increment_async( 'client_1', 60 )->get;
    is( $count2, 2, 'Second hit count is 2' );

    # 3. Get current count without incrementing
    my $get_count = $driver->get_async( 'client_1' )->get;
    is( $get_count, 2, 'get_async returns current hit count' );

    # 4. Reset counter
    $driver->reset_async( 'client_1' )->get;
    my $after_reset = $driver->get_async( 'client_1' )->get;
    is( $after_reset, 0, 'Count is 0 after reset' );
};

done_testing;
