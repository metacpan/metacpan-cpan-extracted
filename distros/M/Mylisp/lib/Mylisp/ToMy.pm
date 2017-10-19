package Mylisp::ToMy;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(ast_to_my atoms_to_my atoms_to_mys atom_to_my oper_to_my name_to_my func_to_my args_to_my aindex_to_my for_to_my our_to_my str_to_my string_to_my array_to_my hash_to_my is_kstr tidy_my);

use Spp::Builtin;
use Spp::Tools;

sub ast_to_my {
  my $ast = shift;
  my $str = atoms_to_my($ast);
  return tidy_my($str);
}

sub atoms_to_my {
  my $atoms = shift;
  my $strs = [map { atom_to_my($_) } @{ atoms($atoms) }];
  return join ' ', @{$strs};
}

sub atoms_to_mys {
  my $atoms = shift;
  return estr([map { atom_to_my($_) } @{ atoms($atoms) }]);
}

sub atom_to_my {
  my $atom = shift;
  my ($name, $args) = flat($atom);
  if (
    $name ~~ [
      '!=', '&&', '+',  '-',  '<',  '<<', '<=', '==',
      '>',  '=',  '>=', '>>', '><', 'eq', 'in', 'le',
      'ne', 'x',  '||'
    ]
    )
  {
    return oper_to_my($name, $args);
  }
  given ($name) {
    when ('func')    { return func_to_my($args) }
    when ('Aindex')  { return aindex_to_my($args) }
    when ('Str')     { return str_to_my($args) }
    when ('String')  { return string_to_my($args) }
    when ('Array')   { return array_to_my($args) }
    when ('Hash')    { return hash_to_my($args) }
    when ('for')     { return for_to_my($args) }
    when ('our')     { return our_to_my($args) }
    when ('package') { return "(package $args)" }
    when ('use')     { return "(use $args)" }
    when ('Sym')     { return $args }
    when ('Int')     { return $args }
    when ('Ns')      { return $args }
    when ('Bool')    { return $args }
    when ('Char')    { return $args }
    when ('Type')    { return $args }
    when ('end')     { return '(end)' }
    default { return name_to_my($name, $args) }
  }
}

sub oper_to_my {
  my ($name, $args) = @_;
  my $strs = atoms_to_mys($args);
  my $str = ejoin($strs, " $name ");
  return "($str)";
}

sub name_to_my {
  my ($name, $args) = @_;
  my $str = atoms_to_my($args);
  return "($name $str)";
}

sub func_to_my {
  my $atoms = shift;
  my ($name_args, $exprs) = match($atoms);
  my ($name,      $args)  = flat($name_args);
  my $args_str  = args_to_my($args);
  my $exprs_str = atoms_to_my($exprs);
  return "(func ($name $args_str) $exprs_str)";
}

sub args_to_my {
  my $args = shift;
  my $strs = [];
  for my $arg (@{ atoms($args) }) {
    my ($name, $type) = flat($arg);
    push @{$strs}, "$name:$type";
  }
  return join ' ', @{$strs};
}

sub aindex_to_my {
  my $args = shift;
  my $strs = atoms_to_mys($args);
  my ($name, $indexs) = match($strs);
  my $indexs_str = ejoin($indexs, '][');
  return "$name\[$indexs_str]";
}

sub for_to_my {
  my $args = shift;
  my ($iter_expr, $exprs)     = match($args);
  my ($loop,      $iter_atom) = flat($iter_expr);
  my $iter_str  = atom_to_my($iter_atom);
  my $exprs_str = atoms_to_my($exprs);
  return "(for ($loop in $iter_str) $exprs_str)";
}

sub our_to_my {
  my $args = shift;
  my $strs = atoms_to_mys($args);
  my ($slist, $value) = flat($strs);
  return "(my $slist $value)";
}

sub str_to_my {
  my $str = shift;
  if (is_kstr($str)) { return ":$str" }
  return "'$str'";
}

sub string_to_my {
  my $string = shift;
  my $strs   = [map { value($_) } @{ atoms($string) }];
  my $str    = join '', @{$strs};
  return "\"$str\"";
}

sub array_to_my {
  my $array     = shift;
  my $atoms     = atoms_to_mys($array);
  my $atoms_str = ejoin($atoms, ' ');
  return "[$atoms_str]";
}

sub hash_to_my {
  my $pairs      = shift;
  my $pairs_strs = [];
  for my $pair (@{ atoms($pairs) }) {
    my ($name, $key_value) = flat($pair);
    my $pair_strs = atoms_to_mys($key_value);
    my ($key, $value) = flat($pair_strs);
    push @{$pairs_strs}, "$key => $value";
  }
  my $pairs_str = join ', ', @{$pairs_strs};
  return "{$pairs_str}";
}

sub is_kstr {
  my $str = shift;
  for my $char (split '', $str) {
    next if is_alpha($char);
    return 0;
  }
  return 1;
}
sub tidy_my { my $str = shift; return $str }
1;
