package Spp::IsChar;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  is_space is_upper is_lower is_digit is_xdigit
  is_alpha is_words is_hspace is_vspace
);

use 5.012;    # no 5.012 no smart-match
no warnings "experimental";

sub is_space {
   my $r = shift;
   return $r ~~ ["\n", "\t", "\r", ' '];
}

sub is_upper {
   my $r = shift;
   return $r ~~ ['A' .. 'Z'];
}

sub is_lower {
   my $r = shift;
   return $r ~~ ['a' .. 'z'];
}

sub is_digit {
   my $r = shift;
   return $r ~~ ['0' .. '9'];
}

sub is_xdigit {
   my $char = shift;
   return 1 if is_digit($char);
   return 1 if $char ~~ ['a' .. 'f'];
   return 1 if $char ~~ ['A' .. 'F'];
   return 0;
}

sub is_alpha {
   my $r = shift;
   return $r ~~ ['a' .. 'z', 'A' .. 'Z', '_'];
}

sub is_words {
   my $r = shift;
   return $r ~~ ['0' .. '9', 'a' .. 'z', 'A' .. 'Z', '_'];
}

sub is_hspace {
   my $r = shift;
   return $r ~~ [' ', "\t"];
}

sub is_vspace {
   my $r = shift;
   return $r ~~ ["\r", "\n"];
}

1;
