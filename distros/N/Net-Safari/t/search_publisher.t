#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $term = "O'Reilly";

my $result = $ua->search( PUBLISHER => $term );

foreach my $book ($result->books) 
{
        like($book->publisher, qr/$term/i, 
            "Publisher, '" . $book->title 
            . "' contains search term, " . $term );
}

