#!perl
use strict;
use warnings;
use Parse::CPAN::Ratings;
use Test::More tests => 7;

my $ratings
    = Parse::CPAN::Ratings->new( filename => 't/all_ratings_100.csv' );
isa_ok( $ratings, 'Parse::CPAN::Ratings' );

my $rating = $ratings->rating('Archive-Zip');
isa_ok( $rating, 'Parse::CPAN::Ratings::Rating' );
is( $rating->distribution, 'Archive-Zip' );
is( $rating->rating,       "3.8" );
is( $rating->review_count, "6" );

my $undef_rating = $ratings->rating('Not-A-Distribution');
is( $undef_rating, undef );

my @ratings = $ratings->ratings;
is( @ratings, 99 );
