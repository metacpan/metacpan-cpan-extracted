package Spp::IsAtom;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  is_atom is_atom_name is_false is_match is_true is_bool
  is_atom_sym is_atom_token is_atom_rept is_atom_look
  is_atom_tillnot is_atom_str is_atom_expr);

use Spp::Builtin;

sub is_atom {
   my $x = shift;
   return (is_array($x) and is_str($x->[0]));
}

sub is_atom_name {
   my ($atom, $name) = @_;
   return (is_atom($atom) and $atom->[0] eq $name);
}

sub is_false {
   my $atom = shift;
   return is_atom_name($atom, 'false');
}

sub is_match {
   my $atom = shift;
   return not(is_false($atom));
}

sub is_true {
   my $atom = shift;
   return is_atom_name($atom, 'true');
}

sub is_bool {
   my $atom = shift;
   return (is_false($atom) or is_true($atom));
}

sub is_atom_sym {
   my $atom = shift;
   return is_atom_name($atom, 'Sym');
}

sub is_atom_token {
   my $atom = shift;
   return is_atom_name($atom, 'Token');
}

sub is_atom_rept {
   my $atom = shift;
   return is_atom_name($atom, '_rept');
}

sub is_atom_look {
   my $atom = shift;
   return is_atom_name($atom, '_look');
}

sub is_atom_tillnot {
   my $s = shift;
   if (is_atom($s)) {
      return 1 if $s->[0] eq 'Till';
      return 1 if $s->[0] eq 'Not';
   }
   return 0;
}

sub is_atom_str {
   my $atom = shift;
   return is_atom_name($atom, 'Str');
}

sub is_atom_expr {
   my $atom = shift;
   return is_atom_name($atom, 'Expr');
}

1;
