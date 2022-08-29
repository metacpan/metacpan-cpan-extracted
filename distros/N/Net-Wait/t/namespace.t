#!/usr/bin/env perl

use Test2::V0;

require Net::Wait;

is [ sort keys %Net::Wait:: ], [qw(
    BEGIN
    VERSION
    import
)] => 'No unexpected methods in Net::Wait namespace';

done_testing;
