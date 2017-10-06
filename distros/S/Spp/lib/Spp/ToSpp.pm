package Spp::ToSpp;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(ast_to_spp);

use Spp::Builtin qw(to_json clean_ast);
use Spp::Estr qw(to_estr atoms flat);

sub ast_to_spp {
   my $ast  = shift;
   my $estr = to_estr(to_json(clean_ast($ast)));
   # say $estr;
   # say from_estr($estr);
   my @strs = ();
   for my $spec (atoms($estr)) {
      my ($name, $rule) = flat($spec);
      my $rule_str = atom_to_spp($rule);
      push @strs, "$name = $rule_str";
   }
   return join(';', @strs);
}

sub map_atoms {
   my $atoms = shift;
   return map { atom_to_spp($_) } atoms($atoms);
}

sub atoms_to_spp {
   my $atoms = shift;
   return join('', map_atoms($atoms));
}

sub atom_to_spp {
   my $rule = shift;
   my ($name, $value) = flat($rule);
   given ($name) {
      when ('Rules')    { return rules_to_spp($value) }
      when ('Group')    { return group_to_spp($value) }
      when ('Branch')   { return branch_to_spp($value) }
      when ('Rept')     { return rept_to_spp($value) }
      when ('Look')     { return look_to_spp($value) }
      when ('Char')     { return char_to_spp($value) }
      when ("Cclass")   { return cclass_to_spp($value) }
      when ("Cchar")    { return char_to_spp($value) }
      when ("Chclass")  { return chclass_to_spp($value) }
      when ("Nchclass") { return nchclass_to_spp($value) }
      when ("Range")    { return range_to_spp($value) }
      when ('Str')      { return str_to_spp($value) }
      when ('Not')      { return not_to_spp($value) }
      when ('Till')     { return till_to_spp($value) }
      when ("Expr")     { return expr_to_spp($value) }
      when ("Array")    { return array_to_spp($value) }
      default { return $value }
   }
}

sub rules_to_spp {
   my $rules = shift;
   return join(' ', map_atoms($rules));
}

sub group_to_spp {
   my $rule = shift;
   return "{" . rules_to_spp($rule) . "}";
}

sub branch_to_spp {
   my $branch = shift;
   return "|" . rules_to_spp($branch) . "|";
}

sub rept_to_spp {
   my $rule = shift;
   my ($rept, $atom) = flat($rule);
   return atom_to_spp($atom) . $rept;
}

sub look_to_spp {
   my $rule = shift;
   my ($rept, $atom_look) = flat($rule);
   my ($atom, $look) = flat($atom_look);
   my $atom_spp = atom_to_spp($atom);
   my $look_spp = atom_to_spp($look);
   return $atom_spp . $rept . $look_spp;
}

sub chclass_to_spp {
   my $atoms = shift;
   return "[" . atoms_to_spp($atoms) . "]";
}

sub nchclass_to_spp {
   my $atoms = shift;
   return "[^" . atoms_to_spp($atoms) . "]";
}

sub str_to_spp {
   my $str = shift;
   return "'" . $str . "'";
}

sub cclass_to_spp {
   my $cclass = shift;
   return "\\" . $cclass;
}

sub char_to_spp {
   my $char = shift;
   given ($char) {
      when ('"')  { return '\\"' }
      when ("\n") { return '\n' }
      when ("\r") { return '\r' }
      when ("\t") { return '\t' }
      when ("'")  { return "\\'" }
      default     { return "'$char'" }
   }
}

sub till_to_spp {
   my $rule = shift;
   return '~' . atom_to_spp($rule);
}

sub not_to_spp {
   my $rule = shift;
   return '!' . atom_to_spp($rule);
}

sub range_to_spp {
   my $range = shift;
   return join('-', atoms($range));
}

sub expr_to_spp {
   my $expr = shift;
   return "(" . rules_to_spp($expr) . ")";
}

sub array_to_spp {
   my $expr = shift;
   return "[" . rules_to_spp($expr) . "]";
}

1;
