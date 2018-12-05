#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

my %tests = (
    '$select=col1&$filter=Price le 100'         => [ { Price => { '<=' => 100 } }, { columns => ['col1'] } ],
    '$select=col1&$filter=Price le 100&skip=10' => [ { Price => { '<=' => 100 } }, { columns => ['col1'] } ],
    '$select=col1&$filter=Price le 100&$skip='  => [ { Price => { '<=' => 100 } }, { columns => ['col1'] } ],
    '$select=&$filter=Price le 100&$skip=10'    => [ { Price => { '<=' => 100 } }, { page => 11 } ],
    '$select=&$filter=Price le 100&$skip=10'    => [ { Price => { '<=' => 100 } }, { page => 11 } ],

);

for my $query_string ( sort keys %tests ) {
    my @result = params_to_dbic( $query_string, strict => 1 );
    is_deeply \@result, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
