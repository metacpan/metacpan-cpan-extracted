#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

my %tests = (
    'orderby=username'         => { order_by => [ {-asc => 'me.username'} ] },
    'orderby=username asc'     => { order_by => [ {-asc => 'me.username'} ] },
    'orderby=username &test=1' => { order_by => [ {-asc => 'me.username'} ] },
    ''                         => {},

    'orderby=t/username asc, userid'             => { order_by => [ {-asc => 't.username'}, {-asc => 'me.userid'} ] },
    'orderby=username asc, t/userid asc'         => { order_by => [ {-asc => 'me.username'}, {-asc => 't.userid'} ] },
    'orderby=a/username%20asc,%20a/userid%20asc' => { order_by => [ {-asc => 'a.username'}, {-asc => 'a.userid'} ] },
    'orderby=username%20asc%20,%20userid%20asc'  => { order_by => [ {-asc => 'me.username'}, {-asc => 'me.userid'} ] },
    'orderby=username desc, userid'              => { order_by => [ {-desc => 'me.username'}, {-asc => 'me.userid'} ] },
    'orderby=username desc, userid desc'         => { order_by => [ {-desc => 'me.username'}, {-desc => 'me.userid'} ] },
    'orderby=username%20desc,%20userid%20desc'   => { order_by => [ {-desc => 'me.username'}, {-desc => 'me.userid'} ] },
    'orderby=username, userid asc'               => { order_by => [ {-asc => 'me.username'}, {-asc => 'me.userid'} ] },
    'orderby=username, userid ASC'               => { order_by => [ {-asc => 'me.username'}, {-asc => 'me.userid'} ] },
    'orderby=username , userid asc'              => { order_by => [ {-asc => 'me.username'}, {-asc => 'me.userid'} ] },
    'orderby=username , userid desc'             => { order_by => [ {-asc => 'me.username'}, {-desc => 'me.userid'} ] },
    'orderby=username , userid DESC'             => { order_by => [ {-asc => 'me.username'}, {-desc => 'me.userid'} ] },
    'orderby=username , userid hallo'            => { order_by => [ {-asc => 'me.username'}, {-asc => 'me.userid'} ] },
    'orderby=username,userid'                    => { order_by => [ {-asc => 'me.username'}, {-asc => 'me.userid'} ] },
);

for my $query_string ( sort keys %tests ) {
    my $result = params_to_dbic( $query_string, me => 1 );
    is_deeply $result, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
