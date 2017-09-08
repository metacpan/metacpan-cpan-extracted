package Spp::IsChar;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  is_char_space is_char_upper is_char_lower is_char_digit is_char_xdigit
  is_char_alpha is_char_words is_char_hspace is_char_vspace
);

use 5.012;    # no 5.012 no smart-match
no warnings "experimental";

sub is_char_space {
   my $r = shift;
   return $r ~~ ["\n", "\t", "\r", ' '];
}

sub is_char_upper {
   my $r = shift;
   return $r ~~ ['A' .. 'Z'];
}

sub is_char_lower {
   my $r = shift;
   return $r ~~ ['a' .. 'z'];
}

sub is_char_digit {
   my $r = shift;
   return $r ~~ ['0' .. '9'];
}

sub is_char_xdigit {
   my $char = shift;
   return 1 if is_char_digit($char);
   return 1 if $char ~~ ['a' .. 'f'];
   return 1 if $char ~~ ['A' .. 'F'];
   return 0;
}

sub is_char_alpha {
   my $r = shift;
   return $r ~~ ['a' .. 'z', 'A' .. 'Z', '_'];
}

sub is_char_words {
   my $r = shift;
   return $r ~~ ['0' .. '9', 'a' .. 'z', 'A' .. 'Z', '_'];
}

sub is_char_hspace {
   my $r = shift;
   return $r ~~ [' ', "\t"];
}

sub is_char_vspace {
   my $r = shift;
   return $r ~~ ["\r", "\n"];
}

1;
