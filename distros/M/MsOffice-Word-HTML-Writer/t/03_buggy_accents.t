#!perl
use utf8;
use Test::More;
use MsOffice::Word::HTML::Writer;

# prior to v1.09, MsWord would open these documents as Japanese !


make_doc("03_buggy_accents_default_utf8.doc");
make_doc("03_buggy_accents_cp1252.doc", charset => "windows-1252");


sub make_doc {
  my ($filename, %options) = @_;

  my $doc = MsOffice::Word::HTML::Writer->new(%options);
  $doc->write("<p>ééèèéèéèèééèççççàààààà</p>") for 1..2;
  $doc->write("<p>ACCUSÉ DE RÉCEPTION</p>");
  $doc->write("<p>tué dans l’oeuf</p>");
  my $content = $doc->content;
  like $content, qr/ACCUSÉ/, "content accusé for $filename";
  $doc->save_as($filename) if $ENV{MWHW_SAVE_TEST_DOCS};
}

done_testing;


