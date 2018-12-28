#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{SC_TEST_HOST} ) {
    plan(skip_all => 'live test, set $ENV{SC_TEST_HOST} to a true value to run')
}

unless ( $ENV{SC_TEST_USERNAME} ) {
    plan(skip_all => 'live test, set $ENV{SC_TEST_USERNAME} to a true value to run')
}

unless ( $ENV{SC_TEST_PASSWORD} ) {
    plan(skip_all => 'live test, set $ENV{SC_TEST_PASSWORD} to a true value to run')
}

require_ok('Net::SecurityCenter::REST');

my $sc = Net::SecurityCenter::REST->new( $ENV{SC_TEST_HOST} );

isa_ok($sc, 'Net::SecurityCenter::REST');

my $system = $sc->get('/system');

cmp_ok ( $system->{'buildID'}, '>', 0, '/system API response' );

like ( $system->{'version'}, qr/(\d+)\.(\d+)\.(\d+)/, 'SecurityCenter version' );

cmp_ok ($sc->login($ENV{SC_TEST_USERNAME}, $ENV{SC_TEST_PASSWORD}), '==', 1, 'SecurityCenter login');

my $plugin = $sc->get('/plugin/19506');

cmp_ok ($plugin->{'id'}, '==', 19506, 'Nessus Scan Information plugin');

done_testing();
