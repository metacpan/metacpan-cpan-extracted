#!perl -w

use strict;
use Test::More;

use Net::Marathon;

my $test_url = $ENV{MARATHON_URL} || 'http://localhost:8080/';

my $marathon = Net::Marathon->new(url => $test_url, verbose => 0);
my $reason = 'The REST API defined at ' . $test_url . ' does not respond to ping. You can set the env variable MARATHON_URL to tell the tests where to reach a marathon REST API.';
unless ( $marathon->ping ) {
    plan skip_all => $reason;
} else {
    plan tests => 1;
}

ok($marathon->ping, 'marathon responds with "pong" on '. $marathon->get_endpoint('/ping'));
