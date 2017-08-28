# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::ToSpp;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(to_spp);

use 5.012;
no warnings "experimental";
use Spp::Tools;
use Spp::IsAtom;

# to str use for trace rule or repl of spp
sub to_spp {
   my $rule = shift;
   return 'false' if is_false($rule);
   return 'true'  if is_true($rule);
   return $rule   if is_chars($rule);
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
      when ('Str')      { return "'" . $value . "'" }
      when ('Char')     { return char_to_spp($value) }
      when ("Cclass")   { return cclass_to_spp($value) }
      when ('Till')     { return till_to_spp($value) }
      when ('Not')      { return not_to_spp($value) }
      when ("Range")    { return range_to_spp($value) }
      when ("Cchar")    { return char_to_spp($value) }
      when ("Expr")     { return expr_to_spp($value) }
      when ("Array")    { return array_to_spp($value) }
      # ['Assert','Ntoken','Ctoken','Schar','Schar','Sym','Int']
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
   my $x_branch = shift;
   return "|" . rules_to_spp($x_branch) . "|";
}

sub lbranch_to_spp {
   my $x_branch = shift;
   return "||" . rules_to_spp($x_branch) . "||";
}

sub rept_to_spp {
   my $rule = shift;
   my ($rept, $atom) = @{$rule};
   return to_spp($atom) . $rept;
}

sub look_to_spp {
   my $rule = shift;
   my ($rept, $atom, $look) = @{$rule};
   return to_spp($atom) . $rept . to_spp($look);
}

sub chclass_to_spp {
   my $x_atoms = shift;
   return "[" . atoms_to_spp($x_atoms) . "]";
}

sub nchclass_to_spp {
   my $x_atoms = shift;
   return "[^" . atoms_to_spp($x_atoms) . "]";
}

sub str_to_spp {
   my $x_str = shift;
   return "'" . $x_str . "'";
}

sub cclass_to_spp {
   my $cclass = shift;
   return "\\" . $cclass;
}

sub char_to_spp {
   my $char = shift;
   given ($char) {
     when ('"')  { return '\\"' }
     when ("\n") { return '\n'  }
     when ("\r") { return '\r'  }
     when ("\t") { return '\t'  }
     when ("\f") { return '\f'  }
     when ("'")  { return "\\'" }
     default { return "'$char'" }
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
   my $x_range = shift;
   return join('-', @{$x_range});
}

sub expr_to_spp {
   my $x_expr = shift;
   return "(" . rules_to_spp($x_expr) . ")";
}

sub array_to_spp {
   my $x_expr = shift;
   return "[" . rules_to_spp($x_expr) . "]";
}

sub map_atoms {
   my $x_atoms = shift;
   return map { to_spp($_) } @{$x_atoms};
}

sub atoms_to_spp {
   my $x_atoms = shift;
   return join('', map_atoms($x_atoms));
}

1;
