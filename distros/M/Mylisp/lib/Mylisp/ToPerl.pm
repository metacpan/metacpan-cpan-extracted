package Mylisp::ToPerl;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(ast_to_perl ast_to_perl_repl atoms_to_perl atoms_to_perls join_perl_exprs atom_to_perl struct_to_perl type_to_perl aindex_to_perl index_to_perl while_to_perl cond_exprs_to_perl exprs_to_perl given_to_perl when_to_perl then_to_perl if_to_perl elif_to_perl else_to_perl for_to_perl iter_to_perl func_to_perl args_to_perl my_to_perl our_to_perl const_to_perl list_to_perl return_to_perl use_to_perl slist_to_perl string_to_perl array_to_perl hash_to_perl pair_to_perl lstr_to_perl str_to_perl bool_to_perl sym_to_perl get_perl_head_str package_to_perl get_export_str oper_to_perl call_to_perl split_to_perl map_to_perl grep_to_perl join_to_perl push_to_perl unshift_to_perl exists_to_perl key_to_perl delete_to_perl char_to_perl);

use Spp::Builtin;
use Spp::Tools;

sub ast_to_perl {
  my $ast       = shift;
  my $head_str  = get_perl_head_str($ast);
  my $exprs_str = atoms_to_perl($ast);
  my $perl_str  = add($head_str, $exprs_str);
  return tidy_perl($perl_str);
}

sub ast_to_perl_repl {
  my $ast = shift;
  return atoms_to_perl($ast);
}

sub atoms_to_perl {
  my $atoms = shift;
  my $strs  = atoms_to_perls($atoms);
  return join_perl_exprs($strs);
}

sub atoms_to_perls {
  my $atoms = shift;
  return estr(
    [map { atom_to_perl($_) } @{ atoms($atoms) }]);
}

sub join_perl_exprs {
  my $exprs    = shift;
  my $strs     = [];
  my $end_char = ';';
  for my $expr (@{ atoms($exprs) }) {
    if ($end_char ~~ [';', '}']) { push @{$strs}, $expr; }
    else { push @{$strs}, ';'; push @{$strs}, $expr; }
    $end_char = last_char($expr);
  }
  return join ' ', @{$strs};
}

sub atom_to_perl {
  my $atom = shift;
  my ($name, $args) = flat($atom);
  given ($name) {
    when ('Aindex')  { return aindex_to_perl($args) }
    when ('while')   { return while_to_perl($args) }
    when ('for')     { return for_to_perl($args) }
    when ('given')   { return given_to_perl($args) }
    when ('when')    { return when_to_perl($args) }
    when ('then')    { return then_to_perl($args) }
    when ('if')      { return if_to_perl($args) }
    when ('elif')    { return elif_to_perl($args) }
    when ('else')    { return else_to_perl($args) }
    when ('func')    { return func_to_perl($args) }
    when ('my')      { return my_to_perl($args) }
    when ('our')     { return our_to_perl($args) }
    when ('const')   { return const_to_perl($args) }
    when ('use')     { return use_to_perl($args) }
    when ('return')  { return return_to_perl($args) }
    when ('String')  { return string_to_perl($args) }
    when ('Array')   { return array_to_perl($args) }
    when ('Hash')    { return hash_to_perl($args) }
    when ('Lstr')    { return lstr_to_perl($args) }
    when ('Str')     { return str_to_perl($args) }
    when ('Char')    { return char_to_perl($args) }
    when ('Bool')    { return bool_to_perl($args) }
    when ('Sym')     { return sym_to_perl($args) }
    when ('Type')    { return type_to_perl($args) }
    when ('Cursor')  { return struct_to_perl($args) }
    when ('Lint')    { return struct_to_perl($args) }
    when ('strings') { return struct_to_perl($args) }
    when ('Int')     { return $args }
    when ('Ns')      { return $args }
    when ('package') { return ' ' }
    when ('end')     { return '1;' }
    default {
      my $strs = atoms_to_perls($args);
      return oper_to_perl($name, $strs)
    }
  }
}

sub struct_to_perl {
  my $args = shift;
  return atoms_to_perl($args);
}

sub type_to_perl {
  my $value = shift;
  given ($value) {
    when ('Int')    { return '0' }
    when ('Str')    { return "''" }
    when ('Bool')   { return '1' }
    when ('Array')  { return '[]' }
    when ('Hash')   { return '{} ' }
    when ('Table')  { return '{}' }
    default         { croak("unknown type |$value|") }
  }
  return True;
}

sub aindex_to_perl {
  my $args = shift;
  my $strs = atoms_to_perls($args);
  my ($name, $indexs) = match($strs);
  my $indexs_strs =
    [map { index_to_perl($_) } @{ atoms($indexs) }];
  my $str = join '', @{$indexs_strs};
  return "$name\->$str ";
}

sub index_to_perl {
  my $index = shift;
  my $char  = last_char($index);
  if (is_digit($char)) { return "[$index]" }
  return "{$index}";
}

sub while_to_perl {
  my $args = shift;
  my $str  = cond_exprs_to_perl($args);
  return "while $str";
}

sub cond_exprs_to_perl {
  my $args = shift;
  my $strs = atoms_to_perls($args);
  my ($cond, $exprs_strs) = match($strs);
  my $exprs_str = exprs_to_perl($exprs_strs);
  if (first_char($cond) eq chr(40)) {
    return "$cond $exprs_str";
  }
  return "($cond) $exprs_str";
}

sub exprs_to_perl {
  my $strs = shift;
  my $str  = join_perl_exprs($strs);
  return "{ $str }";
}

sub given_to_perl {
  my $args = shift;
  my $str  = cond_exprs_to_perl($args);
  return "given $str";
}

sub when_to_perl {
  my $args = shift;
  my $str  = cond_exprs_to_perl($args);
  return "when $str";
}

sub then_to_perl {
  my $args = shift;
  my $str  = atoms_to_perl($args);
  return "default { $str }";
}

sub if_to_perl {
  my $exprs = shift;
  my $str   = cond_exprs_to_perl($exprs);
  return "if $str";
}

sub elif_to_perl {
  my $exprs = shift;
  my $str   = cond_exprs_to_perl($exprs);
  return "elsif $str";
}

sub else_to_perl {
  my $exprs = shift;
  my $str   = atoms_to_perl($exprs);
  return "else { $str }";
}

sub for_to_perl {
  my $args = shift;
  my ($iter_expr, $exprs) = match($args);
  my $iter_str  = iter_to_perl($iter_expr);
  my $exprs_str = atoms_to_perl($exprs);
  return "for $iter_str { $exprs_str } ";
}

sub iter_to_perl {
  my $expr = shift;
  my ($loop, $iter_atom) = flat($expr);
  my $iter = value($iter_atom);
  if ($iter eq '@args') { return "my $loop ($iter)" }
  my $iter_char = first_char($iter);
  my $iter_str  = atom_to_perl($iter_atom);
  given ($iter_char) {
    when ('$') { return "my $loop (split '', $iter_str)" }
    when ('%') { return "my $loop (keys %{$iter_str})" }
    default    { return "my $loop (\@{$iter_str})" }
  }
}

sub func_to_perl {
  my $atoms = shift;
  my ($args,   $rest)      = match($atoms);
  my ($return, $exprs)     = match($rest);
  my ($call,   $func_args) = flat($args);
  my $args_str = args_to_perl($func_args);
  if (not(is_atom_name($return, '->'))) { $exprs = $rest }
  my $exprs_strs = atoms_to_perls($exprs);
  my $exprs_str  = join_perl_exprs($exprs_strs);
  my $name       = sym_to_perl($call);
  return "sub $name { $args_str $exprs_str }";
}

sub args_to_perl {
  my $args = shift;
  if (is_blank($args)) { return ' ' }
  my $strs = [map { sym_to_perl($_) }
      @{ [map { name($_) } @{ atoms($args) }] }];
  my $str = join ', ', @{$strs};
  if (len($strs) == 1) {
    if ($str eq '@args') { return "my $str = \@_;" }
    return "my $str = shift;";
  }
  return "my ($str) = \@_;";
}

sub my_to_perl {
  my $args = shift;
  my ($sym, $value) = flat($args);
  my $value_str = atom_to_perl($value);
  my $name      = atom_to_perl($sym);
  return "my $name = $value_str";
}

sub our_to_perl {
  my $args = shift;
  my ($sym, $value) = flat($args);
  my $value_str = atom_to_perl($value);
  my $list      = value($sym);
  my $list_str  = list_to_perl($list);
  return "my $list_str = $value_str";
}

sub const_to_perl {
  my $args = shift;
  my $strs = atoms_to_perls($args);
  my ($name, $value_str) = flat($strs);
  return "our $name = $value_str";
}

sub list_to_perl {
  my $list = shift;
  my $strs = atoms_to_perls($list);
  my $str  = ejoin($strs, ', ');
  return "($str)";
}

sub return_to_perl {
  my $args = shift;
  my $strs = atoms_to_perls($args);
  my $str  = ejoin($strs, ', ');
  return "return $str";
}
sub use_to_perl { my $args = shift; return "use $args;" }

sub slist_to_perl {
  my $list  = shift;
  my $names = [map { value($_) } @{ atoms($list) }];
  my $strs  = [map { sym_to_perl($_) } @{$names}];
  my $str   = join ' ', @{$strs};
  return "qw($str)";
}

sub string_to_perl {
  my $atoms = shift;
  my $strs  = [];
  for my $atom (@{ atoms($atoms) }) {
    my ($type, $value) = flat($atom);
    given ($type) {
      when ('Sym') {
        my $name = sym_to_perl($value);
        push @{$strs}, $name;
      }
      default { push @{$strs}, $value; }
    }
  }
  my $str = join '', @{$strs};
  return "\"$str\"";
}

sub array_to_perl {
  my $array     = shift;
  my $atoms     = atoms_to_perls($array);
  my $atoms_str = ejoin($atoms, ', ');
  return "[$atoms_str]";
}

sub hash_to_perl {
  my $pairs = shift;
  my $strs  = [];
  for my $pair (@{ atoms($pairs) }) {
    my ($name, $args) = flat($pair);
    if ($name eq 'Pair') {
      push @{$strs}, pair_to_perl($args);
    }
  }
  my $str = join ', ', @{$strs};
  return "{$str} ";
}

sub pair_to_perl {
  my $pair = shift;
  my $strs = atoms_to_perls($pair);
  return ejoin($strs, ' => ');
}

sub lstr_to_perl {
  my $str = shift;
  return "<<'EOF'\n$str\nEOF\n";
}
sub str_to_perl { my $str = shift; return "'$str'" }

sub bool_to_perl {
  my $bool = shift;
  if ($bool eq 'true') { return '1' }
  return '0';
}

sub sym_to_perl {
  my $name  = shift;
  my $chars = [];
  if ($name eq '@args') { return $name }
  for my $char (split '', $name) {
    given ($char) {
      when ('-') { push @{$chars}, '_'; }
      when ('@') { push @{$chars}, '$'; }
      when ('%') { push @{$chars}, '$'; }
      default    { push @{$chars}, $char; }
    }
  }
  return join '', @{$chars};
}

sub get_perl_head_str {
  my $exprs      = shift;
  my $func_names = [];
  my $head_str   = 'str';
  for my $expr (@{ atoms($exprs) }) {
    my ($name, $value) = flat($expr);
    if ($name eq 'package') {
      $head_str = package_to_perl($value);
    }
    if ($name eq 'func') {
      push @{$func_names}, name(name($value));
    }
  }
  my $export_str = get_export_str($func_names);
  return add($head_str, $export_str);
}

sub package_to_perl {
  my $ns          = shift;
  my $package_str = "package $ns;";
  my $head_str    = <<'EOF'


    use 5.012;
    no warnings 'experimental';

    use Exporter;
    our @ISA = qw(Exporter);
EOF
    ;
  return add($package_str, $head_str);
}

sub get_export_str {
  my $names = shift;
  my $export_names = [grep { is_exported($_) } @{$names}];
  my $perl_names =
    [map { sym_to_perl($_) } @{$export_names}];
  my $names_str = join ' ', @{$perl_names};
  return "our \@EXPORT = qw($names_str);\n\n";
}

sub oper_to_perl {
  my ($name, $strs) = @_;
  if (
    $name ~~ [
      '=',  '+',  '-',  '==', '>=', '!=', '>',  '<',
      '<=', '&&', '||', '~~', 'gt', 'ge', 'lt', 'x',
      'eq', 'le', 'ne', 'in'
    ]
    )
  {
    my $oper_str = ejoin($strs, " $name ");
    return "$oper_str";
  }
  return call_to_perl($name, $strs);
}

sub call_to_perl {
  my ($name, $strs) = @_;
  my $str = ejoin($strs, ', ');
  given ($name) {
    when ('split')   { return split_to_perl($strs) }
    when ('map')     { return map_to_perl($strs) }
    when ('grep')    { return grep_to_perl($strs) }
    when ('join')    { return join_to_perl($strs) }
    when ('push')    { return push_to_perl($strs) }
    when ('unshift') { return unshift_to_perl($strs) }
    when ('exists')  { return exists_to_perl($strs) }
    when ('delete')  { return delete_to_perl($strs) }
    when ('say')     { return "say $str" }
    when ('print')   { return "print $str" }
    when ('chop')    { return "Chop($str)" }
    when ('inc')     { return "$str++" }
    when ('dec')     { return "$str --" }
    when ('stdin')   { return "<STDIN>" }
    when ('shift')   { return "shift \@{$str};" }
    when ('nextif')  { return "next if $str" }
    when ('exitif')  { return "exit() if $str" }
    default {
      my $action = sym_to_perl($name);
      return "$action($str)"
    }
  }
}

sub split_to_perl {
  my $strs = shift;
  if (elen($strs) == 1) {
    my $array = name($strs);
    return "split '', $array";
  }
  my ($list, $sub_str) = flat($strs);
  return "[ split $sub_str, $list ]";
}

sub map_to_perl {
  my $strs = shift;
  my ($fn, $array) = flat($strs);
  return "[ map { $fn(\$_) } \@{$array} ]";
}

sub grep_to_perl {
  my $strs = shift;
  my ($fn, $array) = flat($strs);
  return "[ grep { $fn(\$_) } \@{$array} ]";
}

sub join_to_perl {
  my $strs  = shift;
  my $array = name($strs);
  if (elen($strs) == 1) { return "join '', \@{$array} " }
  my $char = value($strs);
  return "join $char, \@{$array};";
}

sub push_to_perl {
  my $strs = shift;
  my ($array, $elem) = flat($strs);
  return "push \@{$array}, $elem;";
}

sub unshift_to_perl {
  my $strs = shift;
  my ($array, $elem) = flat($strs);
  return "unshift \@{$array}, $elem;";
}

sub exists_to_perl {
  my $strs = shift;
  my ($hash, $keys) = match($strs);
  my $keys_str = join '',
    @{ [map { key_to_perl($_) } @{ atoms($keys) }] };
  return "exists $hash\->$keys_str";
}
sub key_to_perl { my $key = shift; return "{$key}" }

sub delete_to_perl {
  my $strs = shift;
  my ($hash, $key) = flat($strs);
  return "delete $hash\->{$key};";
}

sub char_to_perl {
  my $args      = shift;
  my $last_char = last_char($args);
  given ($last_char) {
    when ('n')  { return '"\n"' }
    when ('t')  { return '"\t"' }
    when ('r')  { return '"\r"' }
    when ("\\") { return '"\\\\"' }
    when ("'")  { return '"\'"' }
    default     { return "'$last_char'" }
  }
}
1;
