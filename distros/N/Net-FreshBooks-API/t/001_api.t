#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use Net::FreshBooks::API;

my $fb = Net::FreshBooks::API->new(
    {   auth_token   => 'auth_token',
        account_name => 'account_name',
    }
);

ok $fb, "created the FB object";

is $fb->service_url->as_string,
    'https://account_name.freshbooks.com/api/2.1/xml-in',
    "Service URL as expected";

my $ua = $fb->ua;
ok $ua, "got the useragent";
like $ua->agent, qr{Net::FreshBooks::API \(v\d+\.\d{2}\)},
    "agent string correctly set";

is_deeply(
    [   $ua->get_basic_credentials(
            $fb->auth_realm, $fb->service_url, undef
        )
    ],
    [ $fb->auth_token, '' ],
    "check that the correct credentials will be used"
);

is_deeply(
    [ $ua->get_basic_credentials( '', $fb->service_url, undef ) ],
    [ $fb->auth_token, '' ],
    "check that the correct credentials will be used (with no realm)"
);

my $bad_name
    = Net::FreshBooks::API->new( account_name => 'GYZEGuMPPyz3IFvhP8dOv' );
ok( !$bad_name->account_name_ok, "invalid service url is not found" );

my $good_name
    = Net::FreshBooks::API->new( account_name => 'netfreshbooksapi' );

SKIP: {
    skip 'live tests not enabled', 1, unless $ENV{FB_LIVE_TESTS};
    ok( $good_name->account_name_ok, "valid service url is found" );
}
