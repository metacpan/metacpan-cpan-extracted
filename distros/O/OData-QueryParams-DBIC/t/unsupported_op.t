#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

my %tests = (
    q~filter=startswith(test, 'hallo')~ => { columns => ['col1'] },
    q~filter=contains(test, 'hallo')~   => { columns => ['col1'] },
);

for my $query_string ( sort keys %tests ) {
    eval {
        my $result = params_to_dbic( $query_string );
    } or do {
        like $@, qr/Unsupported op/;
    };
}

done_testing();
