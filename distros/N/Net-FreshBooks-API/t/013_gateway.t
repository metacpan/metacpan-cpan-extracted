#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Net::FreshBooks::API;
use Test::WWW::Mechanize;

plan -r 't/config.pl'
    && require( 't/config.pl' )
    && $ENV{FB_LIVE_TESTS}
    ? ( tests => 6 )
    : (
    skip_all => 'Set FB_LIVE_TESTS to true in your %ENV to run live tests' );

my $test_email = FBTest->get( 'test_email' ) || die;

# create the FB object
my $fb = Net::FreshBooks::API->new(
    {   auth_token   => FBTest->get( 'auth_token' ),
        account_name => FBTest->get( 'account_name' ),
        verbose      => 0,
    }
);
ok $fb, "created the FB object";

my $gateways = $fb->gateway->get_all();
ok( $gateways, "got gateways" );
ok( ( scalar @{$gateways} == 0 ), "no gateways in test account" );
dies_ok( sub { $fb->gateway->get }, "get not implemented" );
my $list = $fb->gateway->list;

ok( !$list->total, "no total via list: " . $list->total );
ok( !$list->pages, "no pages via list: " . $list->pages );
