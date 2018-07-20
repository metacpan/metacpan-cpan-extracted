use Test::More tests => 9;

use_ok( 'POE::Filter::ThruPut' );

my $orig = POE::Filter::ThruPut->new();
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {

  isa_ok( $filter, 'POE::Filter::ThruPut' );
  isa_ok( $filter, 'POE::Filter' );

  my @phrases = (
	"can i please have a cheeseburger?",
	"you're right, i want more pickles.",
	"I'm in your bathroom, reading your magazine",
	"i'm in your world, planning your domination",
	"i think that is a nice bucket",
	"hello, i want to ask you a question",
	"I'm in your bed and breakfast, eating your sausages",
	"free parties, events & more! what's happening?  who's going?",
  );

  my $received = $filter->get( \@phrases );
  is(length($received->[0]),$filter->recv(),'Lengths match');
  my $passthru = $filter->put($received);
  is(length($passthru->[0]),$filter->send(),'Lengths match');
}
