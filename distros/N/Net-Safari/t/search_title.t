#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $search_term = "SAMBA";

my $result = $ua->search( TITLE => $search_term );

foreach my $book ($result->books) 
{
    foreach my $sect ($book->sections)
    {
        like($sect->title, qr/$search_term/i, 
            "Sect title, '" . $sect->title 
            . "' contains search term, " . $search_term);
    }
}

