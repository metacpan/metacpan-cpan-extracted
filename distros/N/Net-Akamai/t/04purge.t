#!/usr/bin/perl -w
use strict;
use warnings;

# to validly test this module you must set these env vars
#NET_AKAMAI_USERNAME -- akamai username with purge access
#NET_AKAMAI_PASSWORD -- akamai password
#NET_AKAMAI_EMAIL -- email to send purge results
#NET_AKAMAI_TESTURL -- a url test to test the purge

use Test::More;

unless ($ENV{NET_AKAMAI_USERNAME} && $ENV{NET_AKAMAI_PASSWORD}
	&& $ENV{NET_AKAMAI_EMAIL} && $ENV{NET_AKAMAI_TESTURL}) {
	plan skip_all => 'set NET_AKAMAI_USERNAME, NET_AKAMAI_PASSWORD, NET_AKAMAI_EMAIL, NET_AKAMAI_TESTURL to enable this test';
}

use_ok( 'Net::Akamai' );

my $data = new Net::Akamai::RequestData(
	user  => $ENV{NET_AKAMAI_USERNAME},
	pwd   => $ENV{NET_AKAMAI_PASSWORD},
	email => $ENV{NET_AKAMAI_EMAIL},
);
isa_ok($data, 'Net::Akamai::RequestData');

my $ap = new Net::Akamai(req_data=>$data);
isa_ok($ap, 'Net::Akamai');

$ap->add_url( $ENV{NET_AKAMAI_TESTURL} );

my $res = $ap->purge();

ok( $res->successful(), 'purge was successful' );

if (!$res->successful()) {
    diag "$res";
}

done_testing;
