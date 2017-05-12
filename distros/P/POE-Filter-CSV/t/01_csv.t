use strict;
use warnings;
use Test::More tests => 10;
BEGIN { use_ok('POE::Filter::CSV') };

my $test = '"This is just a test",line,"so there"';

my $filter = POE::Filter::CSV->new();

isa_ok( $filter, 'POE::Filter::CSV' );
isa_ok( $filter, 'POE::Filter' );

ok( defined $filter, 'Create Filter');

my $results = $filter->get( [ $test ] );

ok( ( $_->[0] eq 'This is just a test' and $_->[1] eq 'line' and $_->[2] eq 'so there' ), 'Test Get' ) 
   for @$results;

my $answer = $filter->put( $results );

ok( $_ eq $test, 'Test put' ) for @$answer;

my $clone = $filter->clone();

isa_ok( $clone, 'POE::Filter::CSV' );
isa_ok( $clone, 'POE::Filter' );

my $results2 = $clone->get( [ $test ] );

ok( ( $_->[0] eq 'This is just a test' and $_->[1] eq 'line' and $_->[2] eq 'so there' ), 'Test Get' )
   for @$results2;

my $answer2 = $clone->put( $results2 );
ok( $_ eq $test, 'Test put' ) for @$answer2;
