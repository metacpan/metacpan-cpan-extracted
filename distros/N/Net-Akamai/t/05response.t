#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

use Net::Akamai::ResponseData;

my @test_cases = (
    [[ 101, 'this is ok' ], [ '101 SUCCESSFUL: this is ok', 1, 0, 1]],
    [[ 200, 'a warn!' ],    [ '200 WARNING: a warn!', 0, 1, 1 ]],
    [[ 333, 'is bad ya' ],  [ '333 REJECTED: is bad ya', 0, 0, 0 ]],
    [[ 421, 'unkown' ],     [ '421 REJECTED: unkown', 0, 0, 0 ]],
);

foreach my $case (@test_cases) {
    my ($input, $output) = @$case;

    my ($result_code, $result_msg) = @$input;
    my $response = Net::Akamai::ResponseData->new(
        result_code => $result_code,
        result_msg  => $result_msg,
    );

    my ($message, $is_successful, $is_warning, $is_accepted) = @$output;
    is( $response->message(), $message, 'message is correct: ' . $message );

    is( "$response", $message, 'stringification worked' );

    ok( ($is_successful ? $response->successful() : !$response->successful()), 'check successful: ' . $is_successful );
    ok( ($is_warning ? $response->warning() : !$response->warning()), 'check warning: ' . $is_warning );
    ok( ($is_accepted ? $response->accepted() : !$response->accepted()), 'check accepted: ' . $is_accepted );
}

done_testing;
