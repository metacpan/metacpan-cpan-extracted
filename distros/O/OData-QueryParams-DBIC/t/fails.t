#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use OData::QueryParams::DBIC;

my %tests = (
    'atop=10' => {},
    ''        => {},
);

for my $query_string ( sort keys %tests ) {
    my $result = params_to_dbic( $query_string );
    is_deeply $result, $tests{$query_string}, 'Query: ' . $query_string;
}

dies_ok { params_to_dbic( bless {}, 'CGI' ) };

done_testing();

