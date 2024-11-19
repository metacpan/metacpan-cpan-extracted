#!perl

use strict;
use warnings;
use v5.10;

use File::Spec;
use STIX::Parser;
use STIX::Util qw(file_read);
use Test::More;

my @TESTS = (
    'indicator-to-campaign-relationship.json',        'indicators-for-C2-with-COA.json',
    'threat-reports/apt1.json',                       'threat-reports/poisonivy.json',
    'indicator-for-c2-ip-address.json',               'interop-objectmarking-test.json',
    'malicious-email-indicator-with-attachment.json', 'infrastructure.json',
);

foreach my $test (@TESTS) {

    my $test_file = File::Spec->catfile('t', 'examples', $test);

    BAIL_OUT(qq{"$test" file not found}) if (!-e $test_file);

    diag "Testing $test";

    my $p    = STIX::Parser->new(file => $test_file);
    my $stix = $p->parse;

    isnt "$stix", '';

    if ($stix->can('type')) {

        my @errors = $stix->validate;
        diag $stix->to_string, "$stix", "@errors" if @errors;

        is @errors, 0;

    }

}

done_testing();
