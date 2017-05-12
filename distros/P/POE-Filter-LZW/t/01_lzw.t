use Test::More tests => 10;
BEGIN { use_ok('POE::Filter::LZW') };
use POE::Filter::Line;
use POE::Filter::Stackable;

my $orig = POE::Filter::LZW->new();
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {

isa_ok( $filter, "POE::Filter::LZW" );
isa_ok( $filter, "POE::Filter" );

my $teststring = "All the little fishes";
my $compressed = $filter->put( [ $teststring ] );
my $answer = $filter->get( [ $compressed->[0] ] );
ok( $teststring eq $answer->[0], 'Round trip test' );

}

my $stack = POE::Filter::Stackable->new( Filters =>
	[ 
		POE::Filter::LZW->new(),
		POE::Filter::Line->new(),
	],
);

my @input = ('testing one two three', 'second test', 'third test');

my $out = $stack->put( \@input );
my $back = $stack->get( $out );

while ( my $thing = shift @input ) {
  my $thang = shift @$back;
  ok( $thing eq $thang, $thing );
}
