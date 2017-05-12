#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $result = $ua->search( ISBN  => '059600415X' ); 

ok( ($result->books)[0]->title eq "Regular Expression Pocket Reference",
    "Title checks out." );


