#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

my %tests = (
    'select=col1'        => { columns => ['col1'] },
    'select='            => {},
    ''                   => {},
    'select=col1,col2'   => { columns => ['col1','col2'] },
    'select=col1 ,col2'  => { columns => ['col1','col2'] },
    'select=col1, col2'  => { columns => ['col1','col2'] },
    'select=col1 , col2' => { columns => ['col1','col2'] },
);

for my $query_string ( sort keys %tests ) {
    my $result = params_to_dbic( $query_string );
    is_deeply $result, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
