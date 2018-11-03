#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

my %tests = (
    'skip=10' => { page => 11 },
    'skip=a'  => {},
    ''        => {},
    'skip=3'  => { page => 4 },
);

for my $query_string ( sort keys %tests ) {
    my $result = params_to_dbic( $query_string );
    is_deeply $result, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
