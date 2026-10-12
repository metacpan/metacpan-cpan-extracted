#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Logs::Logger';

my $logger = CLASS->new(
    callback => sub { { 'TEST' => { @_ } } },
);

is $logger->emit_record( foo => 123 ) => {
    TEST => { foo => 123 },
} => 'Delegates to callback';

done_testing;
