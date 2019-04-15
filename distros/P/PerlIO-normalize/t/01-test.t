use strict;
use warnings;

use Test::More;
use Encode qw(encode decode);

sub enc {
  return encode "UTF-8", shift;
}
sub dec {
  return decode "UTF-8", shift;
}

sub in {
  my $norm = shift;
  my $buf = enc shift;
  open my $fh, "<:utf8:normalize($norm)", \$buf or return undef;
  return scalar readline $fh;
}

sub out {
  my $norm = shift;
  my $buf = "";
  open my $fh, ">:normalize($norm):utf8", \$buf or return undef;
  print { $fh } shift;
  close $fh;
  return dec $buf;
}

is
  in('NFD', "\N{LATIN CAPITAL LETTER E}\N{COMBINING ACUTE ACCENT}"),
  "\N{LATIN CAPITAL LETTER E}\N{COMBINING ACUTE ACCENT}", enc "NFD on e+acute";

is
  in('NFD', "\N{LATIN CAPITAL LETTER E WITH ACUTE}"),
  "\N{LATIN CAPITAL LETTER E}\N{COMBINING ACUTE ACCENT}", enc "NFD on eacute";

is
  in('NFD', "\x{304C}\x{FF76}"),
  "\x{304B}\x{3099}\x{FF76}", enc "NFD on \x{304C}\x{FF76}";

is
  in('NFC', "\x{304C}\x{FF76}"),
  "\x{304C}\x{FF76}", enc "NFC on \x{304C}\x{FF76}";

is
  in('NFKD', "\x{304C}\x{FF76}"),
  "\x{304B}\x{3099}\x{30AB}", enc "NFKD on \x{304C}\x{FF76}";

is
  in('NFKC', "\x{304C}\x{FF76}"),
  "\x{304C}\x{30AB}", enc "NFKC on \x{304C}\x{FF76}";

is
  out('NFC', "\N{LATIN CAPITAL LETTER E}\N{COMBINING ACUTE ACCENT}"),
  "\N{LATIN CAPITAL LETTER E WITH ACUTE}", enc "NFC writing on e+acute";

is
  out('NFC', "\N{LATIN CAPITAL LETTER E WITH ACUTE}"),
  "\N{LATIN CAPITAL LETTER E WITH ACUTE}", enc "NFC writing on eacute";

is
  out('NFD', "\x{304C}\x{FF76}"),
  "\x{304B}\x{3099}\x{FF76}", enc "NFD writing on \x{304C}\x{FF76}";

is
  out('NFC', "\x{304C}\x{FF76}"),
  "\x{304C}\x{FF76}", enc "NFC writing on \x{304C}\x{FF76}";

is
  out('NFKD', "\x{304C}\x{FF76}"),
  "\x{304B}\x{3099}\x{30AB}", enc "NFKD writing on \x{304C}\x{FF76}";

is
  out('NFKC', "\x{304C}\x{FF76}"),
  "\x{304C}\x{30AB}", enc "NFKC writing on \x{304C}\x{FF76}";




done_testing;
