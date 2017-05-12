#!/usr/bin/env perl

use strict;
use Test::More;

use Net::FreshBooks::API;

plan -r 't/config.pl'
    && require( 't/config.pl' )
    && $ENV{FB_LIVE_TESTS}
    ? ( tests => 3 )
    : (
    skip_all => 'Set FB_LIVE_TESTS to true in your %ENV to run live tests' );

ok FBTest->get( 'auth_token' ) && FBTest->get( 'account_name' ),
    "Could get auth_token and account_name";

my $fb = Net::FreshBooks::API->new(
    {   auth_token   => FBTest->get( 'auth_token' ),
        account_name => FBTest->get( 'account_name' ),
        verbose      => 0,
    }
);
ok $fb, "created the FB object";

ok $fb->ping, "Could ping the Freshbooks server";
