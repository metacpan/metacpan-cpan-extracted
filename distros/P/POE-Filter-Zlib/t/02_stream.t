use Test::More tests => 10;
BEGIN { use_ok('POE::Filter::Zlib::Stream') };
use POE::Filter::Line;
use POE::Filter::Stackable;

my $original = POE::Filter::Zlib::Stream->new();
my $clone = $original->clone();

foreach my $filter ( $original, $clone ) {

  isa_ok( $filter, "POE::Filter::Zlib::Stream" );
  isa_ok( $filter, "POE::Filter" );

  my $teststring = "All the little fishes";
  my $compressed = $filter->put( [ $teststring ] );
  my $answer = $filter->get( [ $compressed->[0] ] );
  is( $teststring, $answer->[0], 'Round trip test' );

}

my $stack = POE::Filter::Stackable->new( Filters =>
	[ 
		POE::Filter::Zlib::Stream->new( deflateopts => { -Level => 9 } ),
		POE::Filter::Line->new(),
	],
);

my @input = ('testing one two three', 'second test', 'third test');

my $out = $stack->put( \@input );
my $back = $stack->get( $out );

while ( my $thing = shift @input ) {
  my $thang = shift @$back;
  is( $thing, $thang, $thing );
}
