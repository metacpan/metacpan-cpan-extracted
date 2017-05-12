#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $term = "web services";

my $result = $ua->search( NOTE => $term );

TODO: 
{
    local $TODO = "Safari returning some bad results.";
    foreach my $book ($result->books) 
    {
        foreach my $sect ($book->sections)
        {
            like($sect->extract, qr/$term/i, 
                    "Extract contains search term, " . $term);
        }
    }
}
