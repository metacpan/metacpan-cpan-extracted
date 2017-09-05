package Spp::ToSpp;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(ast_to_spp to_spp);

use 5.012;
no warnings "experimental";
use Spp::Builtin;

sub ast_to_spp {
   my $ast  = shift;
   my @strs = ();
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      my $rule_str = to_spp($rule);
      push @strs, "$name = $rule_str";
   }
   return join(";", @strs);
}

# to str use for trace rule or repl of spp
sub to_spp {
   my $rule = shift;
   my ($name, $value) = @{$rule};
   given ($name) {
      when ('Rules')    { return rules_to_spp($value) }
      when ('Group')    { return group_to_spp($value) }
      when ('Branch')   { return branch_to_spp($value) }
      when ('Lbranch')  { return lbranch_to_spp($value) }
      when ('Rept')     { return rept_to_spp($value) }
      when ('Look')     { return look_to_spp($value) }
      when ("Chclass")  { return chclass_to_spp($value) }
      when ("Nchclass") { return nchclass_to_spp($value) }
      when ('Str')      { return str_to_spp($value) }
      when ('Char')     { return char_to_spp($value) }
      when ("Cclass")   { return cclass_to_spp($value) }
      when ('Till')     { return till_to_spp($value) }
      when ('Not')      { return not_to_spp($value) }
      when ("Range")    { return range_to_spp($value) }
      when ("Cchar")    { return char_to_spp($value) }
      when ("Expr")     { return expr_to_spp($value) }
      when ("Array")    { return array_to_spp($value) }
      when ('Assert')   { return $value }
      when ('Ntoken')   { return $value }
      when ('Ctoken')   { return $value }
      when ('Rtoken')   { return $value }
      when ('Sym')      { return $value }
      when ('Int')      { return $value }
      default           { die "unknown atom to Spp: |$name|" }
   }
}

sub rules_to_spp {
   my $rules = shift;
   return join(' ', map_atoms($rules));
}

sub group_to_spp {
   my $rule = shift;
   return str("{", rules_to_spp($rule), "}");
}

sub branch_to_spp {
   my $branch = shift;
   return "|" . rules_to_spp($branch) . "|";
}

sub lbranch_to_spp {
   my $branch = shift;
   return str("||", rules_to_spp($branch), "||");
}

sub rept_to_spp {
   my $rule = shift;
   my ($rept, $atom) = @{$rule};
   return str(to_spp($atom), $rept);
}

sub look_to_spp {
   my $rule = shift;
   my ($rept, $atom, $look) = @{$rule};
   return str(to_spp($atom), $rept, to_spp($look));
}

sub chclass_to_spp {
   my $atoms = shift;
   return str("[", atoms_to_spp($atoms), "]");
}

sub nchclass_to_spp {
   my $atoms = shift;
   return str("[^", atoms_to_spp($atoms), "]");
}

sub str_to_spp {
   my $str = shift;
   return str("'", $str, "'");
}

sub cclass_to_spp {
   my $cclass = shift;
   return str("\\", $cclass);
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
   return '~' . to_spp($rule);
}

sub not_to_spp {
   my $rule = shift;
   return '!' . to_spp($rule);
}

sub range_to_spp {
   my $range = shift;
   return join('-', @{$range});
}

sub expr_to_spp {
   my $expr = shift;
   return "(" . rules_to_spp($expr) . ")";
}

sub array_to_spp {
   my $expr = shift;
   return "[" . rules_to_spp($expr) . "]";
}

sub map_atoms {
   my $atoms = shift;
   return map { to_spp($_) } @{$atoms};
}

sub atoms_to_spp {
   my $atoms = shift;
   return join('', map_atoms($atoms));
}

1;
