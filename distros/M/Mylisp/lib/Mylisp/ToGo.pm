package Mylisp::ToGo;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(ast_to_go atoms_to_go join_go_exprs atoms_to_gos atom_to_go not_to_go oper_to_go call_to_go substr_to_go push_to_go unshift_to_go shift_to_go my_to_go const_to_go our_to_go slist_to_go array_to_go package_to_go use_to_go ns_to_go func_to_go name_args_to_go arg_to_go return_expr_to_go for_to_go iter_to_go while_to_go if_to_go elif_to_go else_to_go cond_expr_to_go given_to_go when_to_go then_to_go aindex_to_go struct_to_go field_to_go lstr_to_go str_to_go string_to_go clean_go_string return_to_go name_to_go sym_to_go type_to_go type_declare_to_go char_to_go);

use Spp::Builtin;
use Spp::Tools;
sub ast_to_go { my $ast = shift; return atoms_to_go($ast) }

sub atoms_to_go {
  my $atoms = shift;
  my $strs  = atoms_to_gos($atoms);
  return join_go_exprs($strs);
}

sub join_go_exprs {
  my $exprs = shift;
  my $strs  = [];
  my $count = 0;
  for my $expr (@{ atoms($exprs) }) {
    $count++;
    if ($count == 1) { push @{$strs}, $expr; }
    else {
      if (not(start_with($expr, 'else'))) {
        push @{$strs}, ';';
      }
      push @{$strs}, $expr;
    }
  }
  return join '', @{$strs};
}

sub atoms_to_gos {
  my $atoms = shift;
  return estr([map { atom_to_go($_) } @{ atoms($atoms) }]);
}

sub atom_to_go {
  my $atom = shift;
  my ($name, $args) = flat($atom);
  given ($name) {
    when ('package') { return package_to_go($args) }
    when ('use')     { return use_to_go($args) }
    when ('func')    { return func_to_go($args) }
    when ('given')   { return given_to_go($args) }
    when ('for')     { return for_to_go($args) }
    when ('while')   { return while_to_go($args) }
    when ('if')      { return if_to_go($args) }
    when ('elif')    { return elif_to_go($args) }
    when ('else')    { return else_to_go($args) }
    when ('given')   { return given_to_go($args) }
    when ('when')    { return when_to_go($args) }
    when ('then')    { return then_to_go($args) }
    when ('return')  { return return_to_go($args) }
    when ('my')      { return my_to_go($args) }
    when ('our')     { return our_to_go($args) }
    when ('const')   { return const_to_go($args) }
    when ('not')     { return not_to_go($args) }
    when ('Aindex')  { return aindex_to_go($args) }
    when ('Sym')     { return sym_to_go($args) }
    when ('Hash')    { return struct_to_go($args) }
    when ('Lstr')    { return lstr_to_go($args) }
    when ('Str')     { return str_to_go($args) }
    when ('Char')    { return char_to_go($args) }
    when ('String')  { return string_to_go($args) }
    when ('Array')   { return array_to_go($args) }
    when ('Type')    { return $args }
    when ('Int')     { return $args }
    when ('Bool')    { return $args }
    when ('end')     { return ' ' }
    default {
      my $strs = atoms_to_gos($args);
      return oper_to_go($name, $strs)
    }
  }
}

sub not_to_go {
  my $args = shift;
  my $str  = atoms_to_go($args);
  return "!$str";
}

sub oper_to_go {
  my ($name, $strs) = @_;
  given ($name) {
    when ('gt')  { return ejoin($strs, '>') }
    when ('ge')  { return ejoin($strs, '>=') }
    when ('lt')  { return ejoin($strs, '<') }
    when ('eq')  { return ejoin($strs, '==') }
    when ('le')  { return ejoin($strs, '<=') }
    when ('ne')  { return ejoin($strs, '!=') }
    when ('add') { return ejoin($strs, '+') }
    when ('=')   { return ejoin($strs, '=') }
    when ('+')   { return ejoin($strs, '+') }
    when ('-')   { return ejoin($strs, '-') }
    when ('==')  { return ejoin($strs, '==') }
    when ('>=')  { return ejoin($strs, '>=') }
    when ('!=')  { return ejoin($strs, '!=') }
    when ('>')   { return ejoin($strs, '>') }
    when ('<')   { return ejoin($strs, '<') }
    when ('<=')  { return ejoin($strs, '<=') }
    when ('&&')  { return ejoin($strs, '&&') }
    when ('||')  { return ejoin($strs, '||') }
    when ('push')    { return push_to_go($strs) }
    when ('unshift') { return unshift_to_go($strs) }
    default { return call_to_go($name, $strs) }
  }
}

sub call_to_go {
  my ($name, $strs) = @_;
  my $str = ejoin($strs, ',');
  given ($name) {
    when ('~~')     { return "IsIn($str)" }
    when ('>>')     { return "Eunshift($str)" }
    when ('<<')     { return "Epush($str)" }
    when ('><')     { return "Eappend($str)" }
    when ('shift')  { return shift_to_go($str) }
    when ('Cursor') { return "&Cursor$str" }
    when ('Lint')   { return "&Lint$str" }
    when ('Hash')   { return "Hash$str" }
    when ('exitif') { return "if $str { Exit() }" }
    when ('nextif') { return "if $str { continue }" }
    when ('inc')    { return "$str += 1" }
    when ('dec')    { return "$str -= 1" }
    when ('croak')  { return "panic($str)" }
    when ('substr') { return substr_to_go($strs) }
    default {
      $name = sym_to_go($name);
      return "$name($str)"
    }
  }
}

sub substr_to_go {
  my $strs = shift;
  if (elen($strs) == 2) {
    my ($name, $from) = flat($strs);
    return "$name\[$from:]";
  }
  if (elen($strs) == 3) {
    my ($name, $rest) = match($strs);
    my ($from, $to)   = flat($rest);
    if ($to eq '1') { return "$name\[$from]" }
    return "$name\[$from:len($name)$to]";
  }
}

sub push_to_go {
  my $strs = shift;
  my ($array, $elem) = flat($strs);
  return "$array = append($array, $elem)";
}

sub unshift_to_go {
  my $strs = shift;
  my ($array, $elem) = flat($strs);
  return "$array = append(Array{$elem}, $array...)";
}

sub shift_to_go {
  my $str = shift;
  return "$str = $str\[1:]";
}

sub my_to_go {
  my $args = shift;
  my $strs = atoms_to_gos($args);
  my ($sym, $value) = flat($strs);
  if (is_type($value)) {
    my $value_str = type_to_go($value);
    return "var $sym $value";
  }
  return "$sym := $value";
}

sub const_to_go {
  my $args = shift;
  my $strs = atoms_to_gos($args);
  my ($sym, $value) = flat($strs);
  return "const $sym = $value";
}

sub our_to_go {
  my $args = shift;
  my ($slist, $value) = flat($args);
  my $slist_str = slist_to_go(value($slist));
  my $value_str = atom_to_go($value);
  return "$slist_str := $value_str";
}

sub slist_to_go {
  my $syms  = shift;
  my $names = atoms_to_gos($syms);
  return ejoin($names, ',');
}

sub array_to_go {
  my $args = shift;
  my $strs = atoms_to_gos($args);
  my $str  = ejoin($strs, ',');
  return "Array{$str}";
}

sub package_to_go {
  my $ns   = shift;
  my $name = ns_to_go($ns);
  return "package $name";
}

sub use_to_go {
  my $ns    = shift;
  my $names = [split '::', $ns];
  my $name  = join '/', @{$names};
  return "import . \"$name\"";
}

sub ns_to_go {
  my $ns = shift;
  return tail([split '::', $ns]);
}

sub func_to_go {
  my $args = shift;
  my ($name_args, $rest)  = match($args);
  my ($return,    $exprs) = match($rest);
  my $args_str   = name_args_to_go($name_args);
  my $return_str = return_expr_to_go($return);
  my $exprs_str  = atoms_to_go($exprs);
  return "func $args_str $return_str { $exprs_str }";
}

sub name_args_to_go {
  my $name_args = shift;
  my ($name, $args) = flat($name_args);
  my $args_str = join ',',
    @{ [map { arg_to_go($_) } @{ atoms($args) }] };
  $name = sym_to_go($name);
  return "$name($args_str)";
}

sub arg_to_go {
  my $arg = shift;
  my ($name, $type) = flat($arg);
  my $name_str = name_to_go($name);
  my $type_str = type_declare_to_go($type);
  return "$name_str $type_str";
}

sub return_expr_to_go {
  my $expr     = shift;
  my $args     = value($expr);
  my $types    = [map { value($_) } @{ atoms($args) }];
  my $go_types = [map { type_declare_to_go($_) } @{$types}];
  my $str      = join ',', @{$go_types};
  if (len($types) == 1) { return $str }
  return "($str)";
}

sub for_to_go {
  my $args = shift;
  my ($iter_atom, $exprs) = match($args);
  my $iter_str  = iter_to_go($iter_atom);
  my $exprs_str = atoms_to_go($exprs);
  return "for $iter_str $exprs_str }";
}

sub iter_to_go {
  my $atom = shift;
  my ($loop_name, $iter_atom) = flat($atom);
  my $loop = sym_to_go($loop_name);
  my $iter = atom_to_go($iter_atom);
  if (is_sym($iter_atom)) {
    my $char = first_char(value($iter_atom));
    given ($char) {
      when ('$') {
        return "_, c := range $iter { $loop := string(c);"
      }
      when ('%') { return "$loop, _ := range $iter { " }
      default    { return "_, $loop := range $iter { " }
    }
  }
  return "_, $loop := range $iter { ";
}

sub while_to_go {
  my $args = shift;
  my ($guide_atom, $exprs) = match($args);
  my $guide_str = atom_to_go($guide_atom);
  my $exprs_str = atoms_to_go($exprs);
  return "for $guide_str { $exprs_str }";
}

sub if_to_go {
  my $args     = shift;
  my $args_str = cond_expr_to_go($args);
  return "if $args_str";
}

sub elif_to_go {
  my $args     = shift;
  my $args_str = cond_expr_to_go($args);
  return "else if $args_str";
}

sub else_to_go {
  my $args     = shift;
  my $args_str = atoms_to_go($args);
  return "else { $args_str }";
}

sub cond_expr_to_go {
  my $args = shift;
  my ($cond_atom, $exprs) = match($args);
  my $cond_str  = atom_to_go($cond_atom);
  my $exprs_str = atoms_to_go($exprs);
  return "$cond_str { $exprs_str }";
}

sub given_to_go {
  my $args = shift;
  my $str  = cond_expr_to_go($args);
  return "switch $str";
}

sub when_to_go {
  my $args = shift;
  my ($cond_atom, $exprs) = match($args);
  my $cond_str  = atom_to_go($cond_atom);
  my $exprs_str = atoms_to_go($exprs);
  return "case $cond_str: $exprs_str";
}

sub then_to_go {
  my $args     = shift;
  my $args_str = atoms_to_go($args);
  return "default: $args_str";
}

sub aindex_to_go {
  my $args = shift;
  my $strs = atoms_to_gos($args);
  my ($sym, $indexs) = match($strs);
  my $index_str = ejoin($indexs, '][');
  return "$sym\[$index_str]";
}

sub struct_to_go {
  my $pairs = shift;
  my $strs  = [];
  for my $pair (@{ atoms($pairs) }) {
    my ($name, $args) = flat($pair);
    if ($name eq 'Pair') {
      push @{$strs}, field_to_go($args);
    }
  }
  my $str = join ', ', @{$strs};
  return "{ $str }";
}

sub field_to_go {
  my $pair = shift;
  my ($key, $value) = flat($pair);
  my $key_str   = value($key);
  my $value_str = atom_to_go($value);
  return "$key_str: $value_str";
}
sub lstr_to_go { my $args = shift; return "`$args`" }
sub str_to_go  { my $str  = shift; return "`$str`" }

sub string_to_go {
  my $args  = shift;
  my $chars = [];
  my $syms  = [];
  for my $atom (@{ atoms($args) }) {
    if (is_sym($atom)) {
      push @{$chars}, '%s';
      push @{$syms},  atom_to_go($atom);
    }
    else { push @{$chars}, value($atom); }
  }
  my $str_expr = join '', @{$chars};
  my $format = clean_go_string($str_expr);
  if (len($syms) > 0) {
    my $syms_str = join ',', @{$syms};
    return "Sprintf(\"$format\", $syms_str)";
  }
  return "\"$format\"";
}

sub clean_go_string {
  my $str   = shift;
  my $chars = [];
  my $mode  = 0;
  for my $char (split '', $str) {
    if ($mode == 0) {
      if ($char eq '\\') { $mode = 1 }
      else               { push @{$chars}, $char; }
    }
    else {
      given ($char) {
        when ('n')  { return '\n' }
        when ('r')  { return '\r' }
        when ('t')  { return '\t' }
        when ('"')  { return '\"' }
        when ("\\") { return '\\' }
        default     { return $char }
      }
      $mode == 0;
    }
  }
  return join '', @{$chars};
}

sub return_to_go {
  my $args = shift;
  my $strs = [map { atom_to_go($_) } @{ atoms($args) }];
  my $str  = join ',', @{$strs};
  return "return $str";
}

sub name_to_go {
  my $name  = shift;
  my $chars = [];
  for my $char (split '', $name) {
    if   (is_alpha($char)) { push @{$chars}, $char; }
    else                   { push @{$chars}, '_'; }
  }
  return join '', @{$chars};
}

sub sym_to_go {
  my $name       = shift;
  my $first_char = first_char($name);
  if ($first_char ~~ ['$', '@', '%']) {
    return name_to_go($name);
  }
  if ($name ~~ ['len', 'append']) { return $name }
  my $chars = [];
  my $mode  = 0;
  for my $char (split '', $name) {
    next if $char eq '$';
    if ($mode == 0) {
      $mode = 1;
      push @{$chars}, uc($char);
    }
    else {
      if ($char eq '-') { $mode = 0 }
      else              { push @{$chars}, $char; }
    }
  }
  return join '', @{$chars};
}

sub type_to_go {
  my $str = shift;
  given ($str) {
    when ('Str')   { return 'string' }
    when ('Int')   { return 'int' }
    when ('Bool')  { return 'bool' }
    when ('Array') { return 'Array' }
    when ('Ints')  { return '[]int{}' }
    when ('Hash')  { return 'Hash{}' }
    when ('Table') { return 'Table{}' }
    default        { error("unknown type: |$str| to go") }
  }
  return True;
}

sub type_declare_to_go {
  my $str = shift;
  given ($str) {
    when ('Str')    { return 'string' }
    when ('Str+')   { return '...string' }
    when ('Str?')   { return 'string' }
    when ('Int')    { return 'int' }
    when ('Bool')   { return 'Bool' }
    when ('Array')  { return '[]string' }
    when ('Ints')   { return '[]int' }
    when ('Hash')   { return 'map[string]string' }
    when ('Cursor') { return '*Cursor' }
    when ('Lint')   { return '*Lint' }
    default { error("unknown type: |$str| declare") }
  }
  return True;
}

sub char_to_go {
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
