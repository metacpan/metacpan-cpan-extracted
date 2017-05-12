#!/usr/bin/perl
use strict;
# t/search_isbn.t - search by isbn 

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok( 'Net::Safari' ); }

my $ua = Net::Safari->new();

my $first = "Tony";
my $last  = "Stubblebine";

run_search($last, $last);
run_search("$first $last", $last);
run_search("$last, $first", $last);

sub run_search {
    my $term = shift;
    my $match = shift;

    my $result = $ua->search( AUTHOR => $term ); 

    ok($result->is_success, "Successful search for '$term'");

    ok(($result->books)[0]->authors, "Book has authors");

    foreach my $book ($result->books) 
    {
        my $authors = join ( ",", 
                map { $_->fullname; } $book->authors );

        like( $authors, qr/$match/i, "Authors, '$authors', includes $match" );
    }

}
