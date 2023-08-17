#!perl
use utf8;
use Test::More;
use MsOffice::Word::HTML::Writer;
use Encode qw/encode decode/;

my $utf8   = "tué dans l’œuf";
my $cp1252 = encode("windows-1252", $utf8);
my $mixed  = "native string: $cp1252, utf8 string: $utf8";

my %expected_content_for_charset = (
  "windows-1252" => qr/native string: tué dans l’œuf, utf8 string: tué dans l&#8217;&#339;uf/,
  "utf-8"        => qr/native string: tué dans l\222\234uf, utf8 string: tué dans l’œuf/,
 );


while (my ($charset, $expected) = each %expected_content_for_charset) {
qr/native: tué dans l’œuf, utf8: tué dans l&#8217;&#339;uf/,

  my $doc = MsOffice::Word::HTML::Writer->new(charset => $charset);
  $doc->write($mixed);
  my $content = $doc->content;
  
  open my $fh, ">", \my $file_in_memory;
  $doc->save_as($fh);

  my $decoded_file = decode($charset, $file_in_memory);
  like $decoded_file, $expected, "$charset doc";
  $doc->save_as("04_mixed_encoding_$charset.doc") if $ENV{MWHW_SAVE_TEST_DOCS};
}

done_testing;







