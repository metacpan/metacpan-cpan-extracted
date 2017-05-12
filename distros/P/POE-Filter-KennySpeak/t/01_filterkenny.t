use Test::More tests => 37;

use_ok( 'POE::Filter::KennySpeak' );

my $orig = POE::Filter::KennySpeak->new();
my $clone = $orig->clone();

foreach my $filter ( $orig, $clone ) {

  isa_ok( $filter, 'POE::Filter::KennySpeak' );
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

  my @isms = (
"mmfmmmppp mff pfmpmfmppmmmfmmmpp mfpmmmfpmmpp mmm mmfmfpmppmppfmmmppmmpfmfpffmfmmpppff?",
"ffmppffmf'pffmpp pffmffmfmmfpfmp, mff fppmmmpppfmp ppmppfpffmpp pfmmffmmfpmppmfmppfmm.",
"Mff'ppm mffppp ffmppffmfpff mmpmmmfmpmfppffppfppfppm, pffmppmmmmpmmffpppmfm ffmppffmfpff ppmmmmmfmmmmffpmffpppmpp",
"mff'ppm mffppp ffmppffmfpff fppppfpffpmfmpm, pfmpmfmmmppppppmffpppmfm ffmppffmfpff mpmppfppmmffpppmmmfmpmffppfppp",
"mff fmpmfpmffppppmp fmpmfpmmmfmp mfffmm mmm pppmffmmfmpp mmpfmfmmfpmpmppfmp",
"mfpmpppmfpmfppf, mff fppmmmpppfmp fmpppf mmmfmmpmp ffmppffmf mmm pfpfmfmppfmmfmpmffppfppp",
"Mff'ppm mffppp ffmppffmfpff mmpmppmpm mmmpppmpm mmppffmppmmmpmpmpfmmmfmmfmp, mppmmmfmpmffpppmfm ffmppffmfpff fmmmmmfmffmmmmmmfmmppfmm",
"mpfpffmppmpp pfmmmmpfffmpmffmppfmm, mppfpmmpppppfmpfmm & ppmppfpffmpp! fppmfpmmmfmp'fmm mfpmmmpfmpfmmpppppmffpppmfm?  fppmfpppf'fmm mfmppfmffpppmfm?",
  );

  my $kennyisms = $filter->get( \@phrases );

  ok( $_ eq shift @isms, "$_" ) for @$kennyisms;

  my $passthru = $filter->put( $kennyisms );
  
  ok( $_ eq shift @phrases, "$_" ) for @$passthru;
}
