use Test::More tests => 7;
BEGIN { use_ok('POE::Filter::ParseWords') };

my $test = '"This is just a test" "line" "so there"';

my $orig = POE::Filter::ParseWords->new();
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {

  isa_ok( $filter, 'POE::Filter' );
  isa_ok( $filter, 'POE::Filter::ParseWords' );

  my $results = $filter->get( [ $test ] );

  ok( ( $_->[0] eq 'This is just a test' and $_->[1] eq 'line' and $_->[2] eq 'so there' ) , 'Test Get' ) 
	for @$results;

}
