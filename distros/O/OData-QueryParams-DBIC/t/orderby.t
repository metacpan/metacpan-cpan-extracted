#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

my %tests = (
    'orderby=username'     => { order_by => [ {-asc => 'username'} ] },
    'orderby=username asc' => { order_by => [ {-asc => 'username'} ] },
    ''                     => {},

    'orderby=username asc, userid'              => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username asc, userid asc'          => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username%20asc,%20userid%20asc'    => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username%20asc%20,%20userid%20asc' => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username desc, userid'             => { order_by => [ {-desc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username desc, userid desc'        => { order_by => [ {-desc => 'username'}, {-desc => 'userid'} ] },
    'orderby=username%20desc,%20userid%20desc'  => { order_by => [ {-desc => 'username'}, {-desc => 'userid'} ] },
    'orderby=username, userid asc'              => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username , userid asc'             => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
    'orderby=username , userid desc'            => { order_by => [ {-asc => 'username'}, {-desc => 'userid'} ] },
    'orderby=username,userid'                   => { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] },
);

for my $query_string ( sort keys %tests ) {
    my $result = params_to_dbic( $query_string );
    is_deeply $result, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
