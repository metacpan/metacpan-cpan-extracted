package Mylisp::OptAst;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(opt_ast);

use Spp::Builtin;
use Spp::Core;
use Mylisp::Core;

sub opt_ast {
  my $ast = shift;
  if (is_atom($ast)) {
    return [opt_atom($ast)];
  }
  return opt_atoms($ast);
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
    when ('List') { opt_list($value, $pos) }
    when ('Hash') { opt_hash($value, $pos) }
    when ('Pair') { opt_pair($value, $pos) }
    when ('Ocall') { opt_ocall($value, $pos) }
    when ('Aindex') { opt_aindex($value, $pos) }
    when ('Hkey') { opt_hkey($value, $pos) }
    when ('Arange') { opt_arange($value, $pos) }
    when ('Range') { opt_range($value, $pos) }
    when ('Str') { opt_str($value, $pos) }
    when ('String') { opt_string($value, $pos) }
    when ('Char') { opt_char($value, $pos) }
    when ('Chars') { opt_chars($value, $pos) }
    when ('Int') { opt_int($value, $pos) }
    when ('Lstr') { opt_lstr($value, $pos) }
    when ('Kstr') { opt_kstr($value, $pos) }
    when ('Sub')    { opt_sym($value, $pos) }
    when ('Var')    { opt_sym($value, $pos) }
    when ('Oper')   { opt_sym($value, $pos) }
    when ('Scalar') { opt_sym($value, $pos) }
    default {
      say to_json($atom);
      my $line = $pos->[1];
      error("line: $line unknown atom opt!");
    }
  }
}

sub opt_expr {
  my ($expr, $pos) = @_;
  if ((len($expr) == 3) && is_oper($expr->[1])) {
    my $name     = $expr->[1][1];
    my $args     = [$expr->[0], $expr->[2]];
    my $opt_args = opt_atoms($args);
    my $opt_expr = [$name, $opt_args, $pos];
    return opt_oper($opt_expr);
  }
  my $first_atom = $expr->[0];
  my ($type, $name) = @{$first_atom};
  my $args     = rest($expr);
  my $opt_args = opt_atoms($args);
  my $opt_expr = [$name, $opt_args, $pos];
  given ($type) {
    when ('Sub')   { return opt_macro($opt_expr) }
    when ('Oper')  { return opt_oper($opt_expr) }
    when ('Ocall') { return opt_ocall_expr($opt_expr) }
    default {
      my $line = $pos->[1];
      say to_json($expr);
      error("line: $line unknown action: |$type|");
    }
  }
}

sub opt_oper {
  my $expr = shift;
  my ($name, $args, $pos) = @{$expr};
  given ($name) {
    when ('!') {
      my $action = $args->[0][1];
      my $args   = rest($args);
      my $call   = [$action, $args, $pos];
      return ['not', $call, $pos];
    }
    when ('=') { return ['set', $args, $pos] }
    default {
      return ['Oper', $expr, $pos];
    }
  }
}

sub opt_macro {
  my $expr = shift;
  my ($name, $args, $pos) = @{$expr};
  given ($name) {
    when ('module') { opt_module($args, $pos) }
    when ('class') { opt_class($args, $pos) }
    when ('use') { opt_use($args, $pos) }
    when ('func') { opt_func($args, $pos) }
    when ('my') { opt_my($args, $pos) }
    when ('given') { opt_given($args, $pos) }
    when ('when') { opt_when($args, $pos) }
    when ('then') { opt_then($args, $pos) }
    when ('if') { opt_if($args, $pos) }
    when ('elif') { opt_elif($args, $pos) }
    when ('else') { opt_else($args, $pos) }
    when ('for') { opt_for($args, $pos) }
    when ('while') { opt_while($args, $pos) }
    when ('return') { return $expr }
    when ('end')    { return $expr }
    when ('type')   { return $expr }
    default { return ['Call', $expr, $pos] }
  }
}

sub opt_module {
  my ($args, $pos) = @_;
  my $ns = $args->[0][1];
  return ['module', $ns, $pos];
}

sub opt_class {
  my ($args, $pos) = @_;
  my $ns = $args->[0][1];
  return ['class', $args, $pos];
}

sub opt_use {
  my ($args, $pos) = @_;
  if (len($args) == 1) {
    my $ns = $args->[0][1];
    return ['use', $ns, $pos];
  }
  $args->[0][0] = 'Ns';
  $args->[1][0] = 'Slist';
  return ['import', $args, $pos];
}

sub opt_func {
  my ($atoms, $pos)  = @_;
  my ($args,  $rest) = match($atoms);
  my $opt_args = opt_func_args($args);
  my ($return_expr, $exprs) = match($rest);
  my $opt_return = opt_return_expr($return_expr);
  if (len($exprs) == 0) {
    return ['func', [$opt_args, $opt_return], $pos];
  }
  my $func_exprs = [$opt_args, $opt_return, @{$exprs}];
  return ['func', $func_exprs, $pos];
}

sub opt_func_args {
  my $expr = shift;
  my $pos  = $expr->[2];
  if (is_call($expr) or is_oper($expr)) {
    my $name_args = $expr->[1];
    my ($call, $args, $pos) = @{$name_args};
    my $opt_args = [map { opt_arg($_) } @{$args}];
    return [$call, $opt_args, $pos];
  }
  my $line = $pos->[1];
  error("line: $line func args is not expr!");
}

sub opt_arg {
  my $arg      = shift;
  my $pos      = $arg->[2];
  my $line     = $pos->[1];
  my $sym_name = $arg->[1];
  my $index    = index($sym_name, ':');
  if ($index >= 0) {
    my $name = substr($sym_name, 0, $index);
    my $type = substr($sym_name, $index + 1);
    return [$name, $type, $pos];
  }
  say to_json($arg);
  say "line: $line func arg less type info!";
}

sub opt_return_expr {
  my $expr = shift;
  my $pos  = $expr->[2];
  my $line = $pos->[1];
  if (is_oper($expr)) {
    my $return = $expr->[1];
    return $return;
  }
  return $expr;
}

sub is_return {
  my $atom = shift;
  if (is_atom($atom)) {
    return 1 if $atom->[0] eq '->';
  }
  return 0;
}

sub opt_my {
  my ($args, $pos) = @_;
  my $var = $args->[0];
  if (is_atom_array($var)) {
    $args->[0][0] = 'List';
  }
  return ['my', $args, $pos];
}

sub opt_given {
  my ($args, $pos) = @_;
  my $exprs = opt_cond_exprs($args);
  return ['given', $exprs, $pos];
}

sub opt_cond_exprs {
  my $args  = shift;
  my $cond  = $args->[0];
  my $exprs = opt_exprs(rest($args));
  return [$cond, $exprs];
}

sub opt_exprs {
  my $exprs = shift;
  my $pos   = $exprs->[0][2];
  return ['exprs', $exprs, $pos];
}

sub opt_when {
  my ($args, $pos) = @_;
  my $exprs = opt_cond_exprs($args);
  return ['when', $exprs, $pos];
}

sub opt_then {
  my ($args, $pos) = @_;
  my $exprs = opt_exprs($args);
  return ['then', $exprs, $pos];
}

sub opt_if {
  my ($args, $pos) = @_;
  my $exprs = opt_cond_exprs($args);
  return ['if', $exprs, $pos];
}

sub opt_elif {
  my ($args, $pos) = @_;
  my $exprs = opt_cond_exprs($args);
  return ['elif', $exprs, $pos];
}

sub opt_else {
  my ($args, $pos) = @_;
  my $exprs = opt_exprs($args);
  return ['else', $exprs, $pos];
}

sub opt_for {
  my ($args, $pos)  = @_;
  my ($oper, $rest) = match($args);
  if (is_oper($oper)) {
    my $iter  = $oper->[1];
    my $exprs = opt_exprs($rest);
    return ['for', [$iter, $exprs], $pos];
  }
  say "for iter is not (x in \@x)";
}

sub opt_while {
  my ($args, $pos) = @_;
  my $exprs = opt_cond_exprs($args);
  return ['while', $exprs, $pos];
}

sub opt_array {
  my ($atoms, $pos) = @_;
  if (is_str($atoms)) { return ['Array', [], $pos] }
  return ['Array', opt_atoms($atoms), $pos];
}

sub opt_slist {
  my ($atoms, $pos) = @_;
  if (is_str($atoms)) { return ['Slist', [], $pos] }
  return ['Slist', opt_atoms($atoms), $pos];
}

sub opt_list {
  my ($atoms, $pos) = @_;
  return ['List', opt_atoms($atoms), $pos];
}

sub opt_hash {
  my ($pairs, $pos) = @_;
  if (is_str($pairs)) { return ['Hash', [], $pos] }
  return ['Hash', opt_atoms($pairs), $pos];
}

sub opt_pair {
  my ($pair, $pos) = @_;
  my $opt_pair = opt_atoms($pair);
  return ['Pair', $opt_pair, $pos];
}

sub opt_ocall {
  my ($args, $pos) = @_;
  my $atoms = opt_atoms($args);
  my ($sym, $call) = @{$atoms};
  my $name = $call->[1];
  return ['Ocall', [$name, [$sym], $pos], $pos];
}

sub opt_ocall_expr {
  my $expr = shift;
  my ($ocall, $args, $pos) = @{$expr};
  my ($object, $method) = @{$args};
  my $call = $method->[1];
  unshift @{$args}, $object;
  return ['Ocall', [$call, $args, $pos], $pos];
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
    if ($name eq 'from') { $from = $value }
    if ($name eq 'to')   { $to   = $value }
  }
  return ['Range', [$from, $to], $pos];
}

sub opt_str {
  my ($capture_str, $pos) = @_;
  my $str = substr($capture_str, 1, -1);
  return ['Str', $str, $pos];
}

sub opt_string {
  my ($atoms, $pos) = @_;
  if (is_str($atoms)) { return ['Str', '', $pos] }
  return ['String', opt_atoms($atoms), $pos];
}

sub opt_char {
  my ($char, $pos) = @_;
  return ['Char', $char, $pos];
}

sub opt_chars {
  my ($chars, $pos) = @_;
  return ['Str', $chars, $pos];
}

sub opt_int {
  my ($int, $pos) = @_;
  return ['Int', $int, $pos];
}

sub opt_lstr {
  my ($lstr, $pos) = @_;
  my $str = substr($lstr, 3, -3);
  return ['Lstr', $str, $pos];
}

sub opt_kstr {
  my ($kstr, $pos) = @_;
  my $str = substr($kstr, 1);
  return ['Str', $str, $pos];
}

sub opt_sym {
  my ($name, $pos) = @_;
  given ($name) {
    when ('false') { ['Bool', 'false', $pos] }
    when ('true')  { ['Bool', 'true',  $pos] }
    default { ['Sym', $name, $pos] }
  }
}

1;
