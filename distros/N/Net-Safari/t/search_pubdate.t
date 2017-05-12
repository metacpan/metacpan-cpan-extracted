#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $term = "> 20020101";

my $result = $ua->search( PUBLDATE => $term );

TODO:
{
    local $TODO = "Feature broken in Safari";
    foreach my $book ($result->books) 
    {
        print $book->pubdate . "\n"; next;
        like($book->publisher, qr/$term/i, 
                "Publisher, '" . $book->title 
                . "' contains search term, " . $term . $book->pubdate);
    }

}
