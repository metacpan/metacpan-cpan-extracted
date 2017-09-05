package Mylisp::OptAst;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(opt_mylisp_ast);

use 5.012;
no warnings "experimental";
use Spp::Builtin;
use Spp::IsAtom;
use Mylisp::IsAtom;

## ast is array of expr-atom
sub opt_mylisp_ast {
   my $ast = shift;
   ## mylisp is some exprs or one
   if (is_expr($ast)) {
      my $pos = $ast->[2];
      my $expr = opt_expr($ast->[1], $pos);
      return [$expr];
   }
   return opt_atoms($ast);
}

sub opt_expr {
   my ($expr, $pos) = @_;
   ## (a > 1) => (> a 1)
   if (len($expr) == 3 && is_oper($expr->[1])) {
      my $oper     = $expr->[1];
      my $name     = $oper->[1];
      my $args     = [$expr->[0], $expr->[2]];
      my $opt_args = opt_atoms($args);
      return ['Oper', [$name, $opt_args, $pos], $pos];
   }
   my $action = $expr->[0];
   my ($type, $name) = @{$action};
   my $args     = rest($expr);
   my $opt_args = opt_atoms($args);
   my $opt_expr = [$name, $opt_args, $pos];
   given ($type) {
      when ('Macro') { opt_macro($opt_expr) }
      when ('Oper')  { ['Oper', $opt_expr, $pos] }
      when ('Sub')   { ['Call', $opt_expr, $pos] }
      default        { say "unknown action: |$type|"; }
   }
}

sub opt_macro {
   my ($expr) = @_;
   my ($name, $args, $pos) = @{$expr};
   given ($name) {
      when ('package') { opt_package($args, $pos) }
      when ('class') { opt_class($args, $pos) }
      when ('end') { opt_end($args, $pos) }
      when ('export') { opt_export($args, $pos) }
      when ('use') { opt_use($args, $pos) }
      when ('import') { opt_import($args, $pos) }
      when ('my') { opt_my($args, $pos) }
      when ('return') { opt_return($args, $pos) }
      default {$expr}
   }
}

sub opt_package {
   my ($args, $pos) = @_;
   my $package = $args->[0];
   $package->[0] = 'Space';
   return ['package', $package, $pos];
}

sub opt_class {
   my ($args, $pos) = @_;
   my $class = $args->[0];
   $class->[0] = 'Space';
   return ['class', $class, $pos];
}

sub opt_end {
  my ($args, $pos) = @_;
  my $module = $args->[0];
  $module->[0] = 'Space';
  return ['end', $module, $pos];
}

sub opt_export {
   my ($args, $pos) = @_;
   my $list = $args->[0];
   return ['export', $list, $pos];
}

sub opt_use {
   my ($args, $pos) = @_;
   my $class = $args->[0];
   $class->[0] = 'Space';
   return ['use', $class, $pos];
}

sub opt_import {
   my ($args,  $pos)  = @_;
   my ($class, $list) = @{$args};
   $class->[0] = 'Space';
   return ['import', [$class, $list], $pos];
}

sub opt_my {
   my ($args, $pos) = @_;
   my $sym_array = $args->[0];
   if (is_array($sym_array)) {
      $sym_array->[0] = 'List';
      $args->[0]      = $sym_array;
   }
   return ['my', $args, $pos];
}

sub opt_return {
   my ($args, $pos) = @_;
   if (len($args) == 1) {
      return ['return', $args->[0], $pos];
   }
   ['return', ['List', $args, $pos], $pos];
}

sub opt_atoms {
   my $atoms = shift;
   return [map { opt_atom($_) } @{$atoms}];
}

sub opt_atom {
   my $atom = shift;
   my ($name, $value, $pos) = @{$atom};
   given ($name) {
      when ('Expr') { opt_expr($value, $pos) }
      when ('Array') { opt_array($value, $pos) }
      when ('Slist') { opt_slist($value, $pos) }
      when ('Hash') { opt_hash($value, $pos) }
      when ('Pair') { opt_pair($value, $pos) }
      when ('Str')    { opt_str($value, $pos) }
      when ('String') { opt_str($value, $pos) }
      when ('Ocall') { opt_ocall($value, $pos) }
      when ('Aindex') { opt_aindex($value, $pos) }
      when ('Hkey') { opt_hkey($value, $pos) }
      when ('Arange') { opt_arange($value, $pos) }
      when ('Range') { opt_range($value, $pos) }
      when ('Sub')    { opt_sym($value, $pos) }
      when ('Var')    { opt_sym($value, $pos) }
      when ('Oper')   { opt_sym($value, $pos) }
      when ('Scalar') { opt_sym($value, $pos) }
      when ('Macro')  { opt_sym($value, $pos) }
      when ('Mstr') { opt_mstr($value, $pos) }
      when ('Char') { opt_char($value, $pos) }
      when ('Keyword') { opt_keyword($value, $pos) }
      when ('Chars')  { ['Str', $value, $pos] }
      when ('Schars') { ['Str', $value, $pos] }
      when ('Int')    { return $atom }
      default { say "unknown atom to opt: |$name|" }
   }
}

sub opt_keyword {
   my ($keyword, $pos) = @_;
   my $str = rest($keyword);
   ['Str', $str, $pos];
}

sub opt_char {
   my ($char, $pos) = @_;
   ['Str', opt_escape_char($char), $pos];
}

sub opt_escape_char {
   my ($str) = @_;
   my $char = tail($str);
   given ($char) {
      when ('n') { return "\n" }
      when ('r') { return "\r" }
      when ('t') { return "\t" }
      when ('b') { return '' }
      when ('s') { return " " }
      default    { return $char }
   }
}

sub opt_sym {
   my ($name, $pos) = @_;
   given ($name) {
      when ('false') { ['Bool', 'false', $pos] }
      when ('true')  { ['Bool', 'true',  $pos] }
      default { ['Sym', $name, $pos] }
   }
}

sub opt_array {
   my ($atoms, $pos) = @_;
   if (is_perl_str($atoms)) {
      return ['Array', [], $pos];
   }
   ['Array', opt_atoms($atoms), $pos];
}

sub opt_slist {
   my ($atoms, $pos) = @_;
   my $opt_atoms = opt_atoms($atoms);
   return ['Slist', $opt_atoms, $pos];
}

sub opt_hash {
   my ($atoms, $pos) = @_;
   if (is_perl_str($atoms)) {
      return ['Hash', [], $pos];
   }
   ['Hash', opt_atoms($atoms), $pos];
}

sub opt_pair {
   my ($pair, $pos) = @_;
   ['Pair', opt_atoms($pair), $pos];
}

sub opt_str {
   my ($atoms, $pos) = @_;
   if (is_perl_str($atoms)) {
      return ['Str', '', $pos];
   }
   my $opt_atoms = opt_atoms($atoms);
   return $opt_atoms->[0] if len($opt_atoms) == 1;
   return ['String', $opt_atoms, $pos];
}

sub opt_mstr {
   my ($str, $pos) = @_;
   $str = substr($str, 3, -3);
   return ['Mstr', $str, $pos];
}

sub opt_ocall {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   my ($sym, $call) = @{$opt_atoms};
   return ['Ocall', [$call->[1], $sym], $pos];
}

sub opt_aindex {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   return ['Aindex', $opt_atoms, $pos];
}

sub opt_hkey {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   return ['Hkey', $opt_atoms, $pos];
}

sub opt_arange {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   return ['Arange', $opt_atoms, $pos];
}

sub opt_range {
   my ($range, $pos) = @_;
   my $from = 0;
   my $to   = 0;
   for my $atom (@{$range}) {
      my ($name, $value) = @{$atom};
      if ($name eq 'From') { $from = $value }
      if ($name eq 'To')   { $to   = $value }
   }
   return ['Range', [$from, $to], $pos];
}

1;
