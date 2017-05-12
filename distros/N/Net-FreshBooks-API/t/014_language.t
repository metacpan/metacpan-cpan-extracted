#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::WWW::Mechanize;

use Net::FreshBooks::API;

plan -r 't/config.pl'
    && require( 't/config.pl' )
    && $ENV{FB_LIVE_TESTS}
    ? ( tests => 7 )
    : (
    skip_all => 'Set FB_LIVE_TESTS to true in your %ENV to run live tests' );

my $fb = Net::FreshBooks::API->new(
    {   auth_token   => FBTest->get( 'auth_token' ),
        account_name => FBTest->get( 'account_name' ),
        verbose      => 0,
    }
);

ok $fb, "created the FB object";

isa_ok( $fb->language, "Net::FreshBooks::API::Language" );
my $langs = $fb->language->get_all();
ok( $langs, "got languages" );

foreach my $lang ( @{ $fb->language->get_all() } ) {
    diag $lang->code . ": " . $lang->name;
}

ok( ( scalar @{$langs} != 0 ),
    "languages in test account: " . scalar @{$langs} );
dies_ok( sub { $fb->language->get }, "get not implemented" );
my $list = $fb->language->list;

ok( $list->total, "got total via list: " . $list->total );
ok( $list->pages, "got pages via list: " . $list->pages );
