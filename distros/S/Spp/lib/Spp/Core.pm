package Spp::Core;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(match get_rept_time is_atom_name 
  is_tillnot is_look is_rept is_sym is_atom_str);

use Spp::Builtin qw(is_atom len rest to_json);

sub match {
  my $atoms = shift;
  if (len($atoms) > 1) {
    return $atoms->[0], rest($atoms);
  }
  if (len($atoms) == 1) {
    return $atoms->[0], [];
  }
  say to_json($atoms);
  say "match element less 2"; exit();
}

sub get_rept_time {
   my $rept = shift;
   given ($rept) {
      when ('?')  { return (0,  1) }  
      when ('*')  { return (0, -1) } 
      default { return (1, -1) } 
   }
}

sub is_atom_name {
   my ($atom, $name) = @_;
   return (is_atom($atom) and $atom->[0] eq $name);
}

sub is_tillnot {
   my $s = shift;
   if (is_atom($s)) {
      return 1 if $s->[0] eq 'Till';
      return 1 if $s->[0] eq 'Not';
   }
   return 0;
}

sub is_rept {
   my $atom = shift;
   return is_atom_name($atom, '_rept')
}

sub is_look {
   my $atom = shift;
   return is_atom_name($atom, '_look')
}

sub is_sym {
   my $atom = shift;
   return is_atom_name($atom, 'Sym')
}

sub is_atom_str {
   my $atom = shift;
   return is_atom_name($atom, 'Str')
}

1;
