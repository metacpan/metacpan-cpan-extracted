package Mylisp::IsAtom;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(is_func is_array
  is_oper is_aindex is_hkey is_call is_else is_list);

use Spp::Builtin;
use Spp::IsAtom;

sub is_list {
   my $atom = shift;
   return is_atom_name($atom, 'List');
}

sub is_array {
   my $atom = shift;
   return is_atom_name($atom, 'Array');
}

sub is_oper {
   my $atom = shift;
   return 1 if is_atom_name($atom, 'Oper');
   if (is_atom_name($atom, 'Sub')) {
      my $name = $atom->[1];
      return 1 if $name ~~ [qw(eq ne lt gt le ge)];
   }
   return 0;
}

sub is_aindex {
   my $atom = shift;
   return is_atom_name($atom, 'Aindex');
}

sub is_hkey {
   my $atom = shift;
   return is_atom_name($atom, 'Hkey');
}

sub is_call {
   my $atom = shift;
   return is_atom_name($atom, 'Call');
}

sub is_else {
   my $atom = shift;
   return (is_sym($atom) && $atom->[1] eq 'else');
}

1;
