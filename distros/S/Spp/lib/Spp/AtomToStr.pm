package Spp::AtomToStr;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(atom_to_str chclass_to_str match_log_to_str);

use 5.020;
use experimental qw(switch autoderef);
use Spp::Tools;

sub strchar_to_str {
  my $char = shift;
  given ($char) {
    when ("\n") { return '\\n'  }
    when ("\t") { return '\\t'  }
    when ("\r") { return '\\r'  }
    when ("\\") { return '\\\\' }
    when ("'")  { return "\\'"  }
    default { return $char }
  }
}

sub atoms_to_strs {
  my $atoms = shift;
  my $strs = [];
  for my $atom (values $atoms) {
    push $strs, atom_to_str($atom);
  }
  return $strs;
}

# spp would eval atom one by one
# so exprs after eval would became one value
sub atoms_to_str {
  my $atoms = shift;
  my $strs = atoms_to_strs($atoms);
  return host_join($strs, ' ');
}

sub pair_to_str {
  my $pair = shift;
  my $strs = atoms_to_strs($pair);
  return host_join($strs, ' => ');
}

sub atom_to_str {
  my $atom = shift;
  my ($type, $value) = @{ $atom };
  return atoms_to_str($atom) if is_array($type);
  given ($type) {
    when ('dot')     { return $value }
    when ('any')     { return $value }
    when ('nil')     { return $value }
    when ('bool')    { return $value }
    when ('sym')     { return $value }
    when ('context') { return $value }
    when ('assert')  { return $value }
    when ('cclass')  { return $value }
    when ('int')     { return $value }
    when ('ctoken')  { return "<$value>" }
    when ('rtoken')  { return "<.$value>" }
    when ('gtoken')  { return "<!$value>" }
    when ('str')     { return str_to_str($value) }
    when ('array')   { return array_to_str($value) }
    when ('hash')    { return hash_to_str($value) }
    when ('string')  { return string_to_str($value) }
    when ('lambda')  { return lambda_to_str($value) }
    when ('list')    { return list_to_str($value) }
    when ('exprs')   { return atoms_to_str($value) }
    when ('char')    { return char_to_str($value) }
    when ('rule')    { return rule_to_str($value) }
    when ('token')   { return atoms_to_str($value) }
    when ('group')   { return group_to_str($value) }
    when ('branch')  { return branch_to_str($value) }
    when ('lbranch') { return lbranch_to_str($value) }
    when ('rept')    { return rept_to_str($value) }
    when ('look')    { return look_to_str($value) }
    when ('strs')    { return strs_to_str($value) }
    when ('alias')   { return alias_to_str($value) }
    when ('chclass') { return chclass_to_str($value) }
    when ('action')  { return atoms_to_strs($value) }
    default { error("Unknown atom to str: $type") }
  }
}

sub str_to_str {
  my $str = shift;
  my $chars = [];
  for my $char (split('', $str)) {
    push $chars, strchar_to_str($char);
  }
  my $str_str = host_join($chars);
  return "'$str'";
}

sub array_to_str {
  my $values = shift;
  my $strs = atoms_to_strs($values);
  my $array_str = host_join($strs, ',');
  return "[$array_str]";
}

sub hash_to_str {
  my $hash = shift;
  my $strs = [];
  for my $pair (values $hash) {
    push $strs, pair_to_str($pair);
  }
  my $hash_str = host_join($strs, ',');
  return "{$hash_str}";
}

sub string_to_str {
  my $atoms = shift;
  my $strs = [];
  for my $atom (values $atoms) {
    if ($atom->[0] eq 'str') {
      push $strs, $atom->[1];
    } else {
      push $strs, atom_to_str($atom);
    }
  }
  return host_join($strs);
}

sub lambda_to_str {
  my $value = shift;
  my ($args, $exprs) = @{$value};
  my $args_str = atoms_to_str($args);
  my $exprs_str = atom_to_str($exprs);
  return "(def ($args_str) $exprs_str)";
}

sub list_to_str {
  my $atoms = shift;
  my $list_str = atoms_to_str($atoms);
  return "($list_str)";
}

sub char_to_str {
  my $char = shift;
  given ($char) {
    when ("\n") { return '\\n' }
    when ("\t") { return '\\t' }
    when ("\r") { return '\\r' }
    default { return "\\$char" }
  }
}

sub rule_to_str {
  my $atom = shift;
  my $atom_str = atom_to_str($atom);
  return ":{ $atom_str }";
}

sub group_to_str {
  my $tokens = shift;
  my @strs;
  for my $token (values $tokens) {
    push @strs, atom_to_str($token);
  }
  my $group_str = join ' ', @strs;
  return "( $group_str )";
}

sub lbranch_to_str {
  my $branches = shift;
  my @strs;
  for my $token (@{$branches}) {
    push @strs, atom_to_str($token);
  }
  my $branch_str = join ' | ', @strs;
  return $branch_str;
}

sub branch_to_str {
  my $branches = shift;
  my @strs;
  for my $token (@{$branches}) {
    push @strs, atom_to_str($token);
  }
  my $branch_str = join ' || ', @strs;
  return $branch_str;
}

sub rept_to_str {
   my $rept = shift;
   my $atom_str = atom_to_str($rept->[0]);
   my $rept_str = $rept->[-1][-1];
   return $atom_str . $rept_str;
}

sub look_to_str {
   my $look = shift;
   my $rept_str = rept_to_str($look);
   my $look_str = atom_to_str($look->[2]);
   return "$rept_str $look_str";
}

sub strs_to_str {
  my $atoms = shift;
  my $strs_str = join ' ', @{$atoms};
  return "< $strs_str >";
}

sub alias_to_str {
  my $atoms = shift;
  my ($alias_name, $atom) = @{$atoms};
  my $atom_str = atom_to_str($atom);
  return "<$alias_name>=$atom_str";
}

sub chclass_to_str {
  my $atoms = shift;
  my @chclass_list;
  for my $atom (values $atoms) {
    if (type($atom) eq 'flip') {
      push @chclass_list, '^';
    } else {
      push @chclass_list, $atom->[1];
    }
  }
  my $chclass_str = join '', @chclass_list;
  return "[$chclass_str]";
}

sub match_log_to_str {
  my $cursor = shift;
  my $len = $cursor->{LEN};
  my $match_str = $cursor->{STR};
  my $stack = $cursor->{LOG};
  for my $log (values $stack) {
    my ($flag, $atom, $pos) = @{$log};
    my $sub_str = substr($match_str, $pos, $pos + 30);
    my $rule_str = atom_to_str($atom);
    my $sub_rule_str = sprintf('%-30.30s', $rule_str);
    say "$flag | $sub_rule_str |$sub_str| [$pos, $len]";
  }
}

1;
