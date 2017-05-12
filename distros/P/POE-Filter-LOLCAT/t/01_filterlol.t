use Test::More tests => 25;

use_ok( 'POE::Filter::LOLCAT' );

my $orig = POE::Filter::LOLCAT->new();
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {

  isa_ok( $filter, 'POE::Filter::LOLCAT' );
  isa_ok( $filter, 'POE::Filter' );

  my $YOUR = qr/Y?(?:O|U)?(?:A|R)(?:E|R)?/;
  my $Z    = qr/(?:S|Z)/;

  my @phrases = (
	"can i please have a cheeseburger?",
	"you're right, i want more pickles.",
	"I'm in your bathroom, reading your magazine",
	"i'm in your world, planning your domination",
	"i think that is a nice bucket",
	"hello, i want to ask you a question",
	"I'm in your bed and breakfast, eating your sausages",
	"free parties, events & more! what's happening?  who's going?",
  "I have a bucket.",
  "Thank god I've updated this module."
  );

  my @regexen = (
  qr/(?:I CAN|CAN I) HA$Z CHEEZBURGR\?/,
  qr/$YOUR RITE, I WANT$Z MOAR PICKLE$Z/,
  qr/IM IN $YOUR BATHRO(?:O|U)M, READI?NG?$Z? $YOUR MAGAZINE/,
  qr/IM IN $YOUR WH?(?:U|I)?RR?LD, PLANNI?NG?$Z? $YOUR DOMINASHUN/,
  qr/I THINK THAT (?:AR|I$Z) (?:TEH )?NICE BUKK/,
  qr/O(?:H$Z?)? HAI, I WANT$Z (?:TO?|2) ASK Y?(?:U|OO|OU$Z) (?:Q|K)(?:W|U)ES?(?:J|SH)UN/,
  qr/IM IN $YOUR BED AN BREKKFAST, EATI?NG?$Z? $YOUR SAUSUJ$Z?/,
  qr/FREE PARTIE$Z?, EVENT$Z? & MOAR! WH?UT$Z HAPPENI?NG?$Z?\? HOO$Z GOI?NG?$Z?\?/,
  qr/I HA[SVZ] ?A? BUKK/,
  qr/(?:THN?X|(?:T|F)ANK) CEILING CAT IVE UPDATED THIS MODULE/,
  );

  my $lols = $filter->get( \@phrases );

  like( $_, shift @regexen, "translated: $_" ) for @$lols;

}
