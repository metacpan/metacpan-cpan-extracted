package Mylisp::Core;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(is_atom_oper is_atom_else change_sufix);

use File::Basename qw(fileparse);
use Spp::Builtin qw(is_array to_json is_str len);
use Spp::Core qw(is_atom_name is_atom_sym);

sub is_atom_oper {
   my $atom = shift;
   if (is_atom_name($atom, 'Oper')) { return 1 }
   if (is_atom_name($atom, 'Sub')) {
      my $name = $atom->[1];
      return 1 if ($name ~~ [qw(x eq ne lt gt le ge)]);
   }
   return 0;
}

sub is_atom_else {
   my $atom = shift;
   if (is_atom_sym($atom)) {
      return 1 if $atom->[1] eq 'else';
   }
   return 0;
}

sub change_sufix {
   my ($file, $from_sufix, $to_sufix) = @_;
   my @sufix = ($from_sufix);
   my ($name, $path) = fileparse($file, @sufix);
   return $path . $name . $to_sufix;
}

1;
