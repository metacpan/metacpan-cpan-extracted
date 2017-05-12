#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $term = "itbooks.security";
my $match = "Security";
my $result = $ua->search( CATEGORY => $term );

TODO: 
{
    local $TODO = "Safari returning some bad results.";
    foreach my $book ($result->books) 
    {
        ok( $book->subjects, $book->title . " has subjects." );

        my $subjects = join(",", $book->subjects) . "\n";
        like ($subjects, qr/$match/i, "Subjects contain $match"); 
    }
}
