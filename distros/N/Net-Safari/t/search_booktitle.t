#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $term = "XML";

my $result = $ua->search( BOOKTITLE => $term ); 


TODO: 
{
    local $TODO = "This feature seems broken in the SafariAPI";
    ok($result->is_success, "Successful search");

    foreach my $book ($result->books) 
    {
        like( $book->title, qr/$term/i,
                "Title, '" . $book->title . "' matches term, $term" );
    }
}
