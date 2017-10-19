package Mylisp::OptAst;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(opt_my_ast opt_my_atoms opt_my_atom opt_my_expr is_oper opt_my_infix_op_expr opt_my_oper opt_my_sub opt_my_package opt_my_use opt_my_func opt_my_func_args opt_my_arg opt_my_for opt_my_iter opt_my_my opt_my_ocall_expr opt_my_ocall opt_my_name_value opt_my_array opt_my_hash opt_my_pair opt_my_aindex opt_my_arange opt_my_string opt_my_str opt_my_lstr opt_my_kstr opt_my_chars opt_my_sym);

use Spp::Builtin;
use Spp::Tools;

sub opt_my_ast {
  my $ast = shift;
  if (is_atom($ast)) { return cons(opt_my_atom($ast)) }
  return opt_my_atoms($ast);
}

sub opt_my_atoms {
  my $atoms = shift;
  return estr([map { opt_my_atom($_) } @{ atoms($atoms) }]);
}

sub opt_my_atom {
  my $atom = shift;
  my ($name, $rest) = match($atom);
  given ($name) {
    when ('Expr')   { return opt_my_expr($rest) }
    when ('Ocall')  { return opt_my_ocall($rest) }
    when ('Array')  { return opt_my_array($rest) }
    when ('Hash')   { return opt_my_hash($rest) }
    when ('Pair')   { return opt_my_pair($rest) }
    when ('Aindex') { return opt_my_aindex($rest) }
    when ('Arange') { return opt_my_arange($rest) }
    when ('String') { return opt_my_string($rest) }
    when ('Str')    { return opt_my_str($rest) }
    when ('Lstr')   { return opt_my_lstr($rest) }
    when ('Kstr')   { return opt_my_kstr($rest) }
    when ('Chars')  { return opt_my_chars($rest) }
    when ('Sub')    { return opt_my_sym($rest) }
    when ('Var')    { return opt_my_sym($rest) }
    when ('Scalar') { return opt_my_sym($rest) }
    when ('Oper')   { return opt_my_sym($rest) }
    when ('Char')   { return $atom }
    when ('Ns')     { return $atom }
    when ('Arg')    { return $atom }
    when ('Int')    { return $atom }
    default { error("unknown atom |$name| to opt!") }
  }
}

sub opt_my_expr {
  my $value = shift;
  my ($expr, $pos) = flat($value);
  if (elen($expr) == 3 && is_oper(value($expr))) {
    return opt_my_infix_op_expr($expr, $pos);
  }
  my ($action, $args) = match($expr);
  my ($type,   $name) = flat($action);
  given ($type) {
    when ('Sub') { return opt_my_sub($name, $args, $pos) }
    when ('Oper') { return opt_my_oper($name, $args, $pos) }
    when ('Ocall') {
      return opt_my_ocall_expr($name, $args, $pos)
    }
    default {
      my $atoms = opt_my_atoms($expr);
      return cons('Array', $atoms)
    }
  }
}

sub is_oper {
  my $atom = shift;
  if (is_atom($atom)) {
    my ($name, $value) = flat($atom);
    if ($name eq 'Oper') { return 1 }
    if ($value ~~ ['x', 'eq', 'le', 'ne', 'in']) {
      return 1;
    }
  }
  return 0;
}

sub opt_my_infix_op_expr {
  my ($expr, $pos) = @_;
  my $atoms = atoms($expr);
  my $name  = value($atoms->[1]);
  my $args  = cons($atoms->[0], $atoms->[2]);
  $args = opt_my_atoms($args);
  given ($name) {
    when ('>>') { return cons('eunshift', $args, $pos) }
    when ('<<') { return cons('epush',    $args, $pos) }
    when ('><') { return cons('eappend',  $args, $pos) }
    default     { return cons($name,      $args, $pos) }
  }
}

sub opt_my_oper {
  my ($name, $args, $pos) = @_;
  my $atoms = opt_my_atoms($args);
  return cons($name, $atoms, $pos);
}

sub opt_my_sub {
  my ($name, $args, $pos) = @_;
  given ($name) {
    when ('package') { return opt_my_package($args, $pos) }
    when ('use') { return opt_my_use($args, $pos) }
    when ('func') { return opt_my_func($args, $pos) }
    when ('for') { return opt_my_for($args, $pos) }
    when ('my') { return opt_my_my($args, $pos) }
    default {
      return cons($name, opt_my_atoms($args), $pos)
    }
  }
}

sub opt_my_package {
  my ($args, $pos) = @_;
  my $ns = value(name($args));
  return cons('package', $ns, $pos);
}

sub opt_my_use {
  my ($args, $pos) = @_;
  my $atoms = opt_my_atoms($args);
  my $ns    = value(name($atoms));
  return cons('use', $ns, $pos);
}

sub opt_my_func {
  my ($args, $pos) = @_;
  my $atoms = opt_my_atoms($args);
  my ($name_args, $exprs) = match($atoms);
  my $return = name($exprs);
  if (not(is_return($return))) {
    my $expr = cons('->', cons(cons('Type', 'Str')));
    $exprs = eunshift($expr, $exprs);
  }
  my $opt_args = opt_my_func_args($name_args);
  my $func_exprs = eunshift($opt_args, $exprs);
  return cons('func', $func_exprs, $pos);
}

sub opt_my_func_args {
  my $expr = shift;
  my ($call, $args) = flat($expr);
  my $opt_args = [map { opt_my_arg($_) } @{ atoms($args) }];
  my $pos = offline($expr);
  return cons($call, estr($opt_args), $pos);
}

sub opt_my_arg {
  my $arg = shift;
  my ($name, $value) = flat($arg);
  my $pos  = offline($arg);
  my $line = value(offline($arg));
  if ($name eq 'Arg') {
    my $names    = [split ':', $value];
    my $arg_name = $names->[0];
    my $type     = $names->[1];
    if (is_type($type)) {
      return cons($arg_name, $type, $pos);
    }
    else { say "line: $line unknown type |$type|" }
  }
  if ($name eq 'Sym') { return cons($value, 'Str', $pos) }
  say "line: $line |$name| as func arg!";
}

sub opt_my_for {
  my ($args, $pos) = @_;
  my $atoms = opt_my_atoms($args);
  my ($iter_expr, $rest) = match($atoms);
  my $iter_atom = opt_my_iter($iter_expr);
  my $exprs = eunshift($iter_atom, $rest);
  return cons('for', $exprs, $pos);
}

sub opt_my_iter {
  my $expr = shift;
  my ($in,       $args)      = flat($expr);
  my ($loop_sym, $iter_atom) = flat($args);
  my $loop = value($loop_sym);
  my $pos  = offline($expr);
  return cons($loop, $iter_atom, $pos);
}

sub opt_my_my {
  my ($args, $pos) = @_;
  my $atoms = opt_my_atoms($args);
  my $sym   = name($atoms);
  if (is_sym($sym)) { return cons('my', $atoms, $pos) }
  return cons('our', $atoms, $pos);
}

sub opt_my_ocall_expr {
  my ($ocall, $args, $pos) = @_;
  my ($sym, $call) = flat($ocall);
  my $name = value($call);
  my $opt_args = opt_my_atoms(eunshift($sym, $args));
  return cons($name, $opt_args, $pos);
}

sub opt_my_ocall {
  my $value = shift;
  my ($args, $pos) = flat($value);
  my $opt_args = opt_my_atoms($args);
  my ($sym, $call) = flat($opt_args);
  my $name = value($call);
  return cons($name, cons($sym), $pos);
}

sub opt_my_name_value {
  my ($name, $value) = @_;
  my ($args, $pos)   = flat($value);
  my $atoms = opt_my_atoms($args);
  return cons($name, $atoms, $pos);
}

sub opt_my_array {
  my $value = shift;
  return opt_my_name_value('Array', $value);
}

sub opt_my_hash {
  my $value = shift;
  return opt_my_name_value('Hash', $value);
}

sub opt_my_pair {
  my $value = shift;
  return opt_my_name_value('Pair', $value);
}

sub opt_my_aindex {
  my $value = shift;
  return opt_my_name_value('Aindex', $value);
}

sub opt_my_arange {
  my $value = shift;
  return opt_my_name_value('subarray', $value);
}

sub opt_my_string {
  my $value = shift;
  return opt_my_name_value('String', $value);
}

sub opt_my_str {
  my $value = shift;
  my ($str, $pos) = flat($value);
  $str = substr($str, 1, -1);
  return cons('Str', $str, $pos);
}

sub opt_my_lstr {
  my $value = shift;
  my ($lstr, $pos) = flat($value);
  my $str = substr($lstr, 3, -3);
  return cons('Lstr', $str, $pos);
}

sub opt_my_kstr {
  my $value = shift;
  my ($kstr, $pos) = flat($value);
  my $str = substr($kstr, 1);
  return cons('Str', $str, $pos);
}

sub opt_my_chars {
  my $rest = shift;
  my ($str, $pos) = flat($rest);
  return cons('Str', $str, $pos);
}

sub opt_my_sym {
  my $value = shift;
  my ($name, $pos) = flat($value);
  given ($name) {
    when ('false')  { return cons('Bool', $name, $pos) }
    when ('true')   { return cons('Bool', $name, $pos) }
    when ('Str')    { return cons('Type', $name, $pos) }
    when ('Int')    { return cons('Type', $name, $pos) }
    when ('Hash')   { return cons('Type', $name, $pos) }
    when ('Bool')   { return cons('Type', $name, $pos) }
    when ('Array')  { return cons('Type', $name, $pos) }
    when ('Ints')   { return cons('Type', $name, $pos) }
    when ('Table')  { return cons('Type', $name, $pos) }
    when ('Cursor') { return cons('Type', $name, $pos) }
    when ('Lint')   { return cons('Type', $name, $pos) }
    default         { return cons('Sym',  $name, $pos) }
  }
}
1;
