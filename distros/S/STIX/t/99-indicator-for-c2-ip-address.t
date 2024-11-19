#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX::Common::Bundle;
use STIX::Common::Timestamp;
use STIX::Indicator;

# https://github.com/oasis-open/cti-stix2-json-schemas/blob/master/examples/indicator-for-c2-ip-address.json

my $bundle = STIX::Common::Bundle->new;

my $indicator = STIX::Indicator->new(
    pattern_type    => 'stix',
    created         => STIX::Common::Timestamp->new('2014-05-08T09:00:00'),
    name            => 'IP Address for known C2 channel',
    description     => 'Test description C2 channel.',
    indicator_types => ['malicious-activity'],
    pattern         => "[ipv4-addr:value = '10.0.0.0']",
    valid_from      => STIX::Common::Timestamp->new('2014-05-08T09:00:00'),
);

$bundle->objects->push($indicator);

my $json   = $bundle->to_string;
my @errors = $bundle->validate;

diag $json;

isnt $json, '';

is $bundle->objects->[0]->type, 'indicator';

is @errors, 0;

done_testing();
