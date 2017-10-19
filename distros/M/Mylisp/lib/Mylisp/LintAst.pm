package Mylisp::LintAst;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(lint_my_ast init_my_lint use_package load_package load_ast regist_func get_my_atoms_value regist_const lint_my_atoms lint_my_atom lint_my_exprs lint_my_block lint_my_func get_return_type_str arg_type_to_return lint_my_return get_args_type_str lint_my_my lint_my_our lint_my_call lint_my_for lint_my_set lint_my_sym_list lint_my_sym is_define get_atom_type get_sym_type get_call_type get_array_type get_arange_type get_iter_type lint_my_aindex get_aindex_type get_index_type update_pos ns in_package in_ns out_block out_ns set_name_value get_name_value);

use Spp::Builtin;
use Spp::Tools;
use Mylisp::Type;

sub lint_my_ast {
  my $ast = shift;
  my $t   = new_lint();
  print 'load package .. ';
  init_my_lint($t, $ast);
  print "load ok!\n";
  lint_my_atoms($t, $ast);
  return True;
}

sub init_my_lint {
  my ($t, $ast) = @_;
  for my $expr (@{ atoms($ast) }) {
    my ($name, $args) = flat($expr);
    update_pos($t, $expr);
    given ($name) {
      when ('package') { in_package($t, $args) }
      when ('use') { use_package($t, $args) }
      when ('const') { regist_const($t, $args) }
      when ('func') { regist_func($t, $args) }
    }
  }
  return True;
}

sub use_package {
  my ($t, $args) = @_;
  load_package($t, $args);
  my $table = $t->{'st'}{$args};
  for my $name (keys %{$table}) {
    next if start_with($name, '_');
    my $value = $table->{$name};
    set_name_value($t, $name, $value);
  }
  return True;
}

sub load_package {
  my ($t, $package) = @_;
  my $dirs = [split '::', $package];
  my $path = join '/', @{$dirs};
  my $ast_file = add($path, ".spp.estr");
  my $ast = read_file($ast_file);
  load_ast($t, $ast);
  return True;
}

sub load_ast {
  my ($t, $ast) = @_;
  for my $expr (@{ atoms($ast) }) {
    my ($name, $args) = flat($expr);
    update_pos($t, $expr);
    given ($name) {
      when ('package') { in_package($t, $args) }
      when ('func') { regist_func($t, $args) }
      when ('const') { regist_const($t, $args) }
      when ('end') { out_ns($t) }
    }
  }
  return True;
}

sub regist_func {
  my ($t,         $atoms)  = @_;
  my ($name_args, $return) = flat($atoms);
  my $return_type = get_my_atoms_value(value($return));
  my ($name, $args) = flat($name_args);
  if (is_blank($args)) {
    set_name_value($t, $name, $return_type);
  }
  else {
    my $args_type = get_my_atoms_value($args);
    my $value = cons($args_type, $return_type);
    set_name_value($t, $name, $value);
  }
  return True;
}

sub get_my_atoms_value {
  my $atoms = shift;
  my $names = [map { value($_) } @{ atoms($atoms) }];
  return join ' ', @{$names};
}

sub regist_const {
  my ($t,   $args)  = @_;
  my ($sym, $value) = flat($args);
  my $name = value($sym);
  my $value_type = get_atom_type($t, $value);
  set_name_value($t, $name, $value_type);
  return True;
}

sub lint_my_atoms {
  my ($t, $atoms) = @_;
  for my $atom (@{ atoms($atoms) }) {
    lint_my_atom($t, $atom);
  }
  return True;
}

sub lint_my_atom {
  my ($t,    $atom) = @_;
  my ($name, $args) = flat($atom);
  update_pos($t, $atom);
  given ($name) {
    when ('func') { lint_my_func($t, $args) }
    when ('return') { lint_my_return($t, $args) }
    when ('my') { lint_my_my($t, $args) }
    when ('our') { lint_my_our($t, $args) }
    when ('=') { lint_my_set($t, $args) }
    when ('Sym') { lint_my_sym($t, $args) }
    when ('Aindex') { lint_my_aindex($t, $args) }
    when ('for') { lint_my_for($t, $args) }
    when ('while') { lint_my_exprs($t, $args) }
    when ('given') { lint_my_exprs($t, $args) }
    when ('when')  { lint_my_exprs($t, $args) }
    when ('if')    { lint_my_exprs($t, $args) }
    when ('elif')  { lint_my_exprs($t, $args) }
    when ('then') { lint_my_block($t, $args) }
    when ('else') { lint_my_block($t, $args) }
    when ('String') { lint_my_atoms($t, $args) }
    when ('Array')  { lint_my_atoms($t, $args) }
    when ('Hash')   { lint_my_atoms($t, $args) }
    when ('Pair')   { lint_my_atoms($t, $args) }
    when ('end')    { out_ns($t) }
    when ('package') { return True }
    when ('const')   { return True }
    when ('Str')     { return True }
    when ('Lstr')    { return True }
    when ('Int')     { return True }
    when ('Char')    { return True }
    when ('Bool')    { return True }
    when ('Type')    { return True }
    when ('Lint')    { return True }
    when ('Cursor')  { return True }
    when ('use')     { return True }
    when ('->')      { return True }
    default { lint_my_call($t, $name, $args) }
  }
}

sub lint_my_exprs {
  my ($t,         $atoms) = @_;
  my ($cond_atom, $exprs) = match($atoms);
  lint_my_atom($t, $cond_atom);
  lint_my_block($t, $exprs);
  return True;
}

sub lint_my_block {
  my ($t, $exprs) = @_;
  my $uuid = uuid();
  in_ns($t, $uuid);
  lint_my_atoms($t, $exprs);
  out_block($t, $uuid);
  return True;
}

sub lint_my_func {
  my ($t,         $args)  = @_;
  my ($name_args, $rest)  = match($args);
  my ($return,    $atoms) = match($rest);
  my $return_type_str = get_return_type_str($return);
  $t->{'ret'} = $return_type_str;
  my ($call, $func_args) = flat($name_args);
  in_ns($t, $call);
  for my $arg (@{ atoms($func_args) }) {
    my ($name, $type) = flat($arg);
    set_name_value($t, $name, $type);
  }
  lint_my_atoms($t, $atoms);
  out_ns($t);
  return True;
}

sub get_return_type_str {
  my $expr  = shift;
  my $args  = value($expr);
  my $names = [map { value($_) } @{ atoms($args) }];
  my $types = [map { arg_type_to_return($_) } @{$names}];
  return join ' ', @{$types};
}

sub arg_type_to_return {
  my $type = shift;
  given ($type) {
    when ('Str+') { return 'Array' }
    when ('Int+') { return 'Ints' }
    default       { return $type }
  }
}

sub lint_my_return {
  my ($t, $args) = @_;
  my $call          = ns($t);
  my $return_type   = $t->{'ret'};
  my $args_type_str = get_args_type_str($t, $args);
  my $args_pat      = pat_to_type_rule($t, $args_type_str);
  my $match = match_type($t, $args_pat, $return_type);
  lint_my_atoms($t, $args);
  if (is_false($match)) {
    say "return type is not same with call declare";
    say "|$args_type_str| != |$return_type|";
  }
  return True;
}

sub get_args_type_str {
  my ($t, $atoms) = @_;
  my $types = [];
  for my $atom (@{ atoms($atoms) }) {
    push @{$types}, get_atom_type($t, $atom);
  }
  return join ' ', @{$types};
}

sub lint_my_my {
  my ($t,   $args)  = @_;
  my ($sym, $value) = flat($args);
  lint_my_atom($t, $value);
  my $type = get_atom_type($t, $value);
  my $name = value($sym);
  if (is_str($type)) { set_name_value($t, $name, $type) }
  else { report($t, "one sym accept more assign") }
  return True;
}

sub lint_my_our {
  my ($t,     $args)  = @_;
  my ($array, $value) = flat($args);
  lint_my_atom($t, $value);
  my $type = get_atom_type($t, $value);
  my $types = [split ' ', $type];
  my $syms = value($array);
  lint_my_sym_list($t, $syms);
  my ($a, $b) = flat($syms);

  if (len($types) != 2) {
    report($t, "return value not two");
  }
  my $a_name = value($a);
  my $b_name = value($b);
  my $a_type = $types->[0];
  my $b_type = $types->[1];
  set_name_value($t, $a_name, $a_type);
  set_name_value($t, $b_name, $b_type);
  return True;
}

sub lint_my_call {
  my ($t, $name, $args) = @_;
  my $value = get_name_value($t, $name);
  if (is_blank($args)) {
    if (is_estr($value)) {
      report($t, "call |$name| less argument");
    }
    return True;
  }
  if (is_str($value)) {
    report($t, "call |$name| more argument");
  }
  my $call_type_str = name($value);
  lint_my_atoms($t, $args);
  my $args_type_str = get_args_type_str($t, $args);
  my $call_rule = pat_to_type_rule($t, $call_type_str);
  # say see_ast($call_rule);
  my $match = match_type($t, $call_rule, $args_type_str);
  if (is_false($match)) {
    say "|$call_type_str| != |$args_type_str|";
    report($t, "call |$name| args type not same!");
  }
  return True;
}

sub lint_my_for {
  my ($t,         $args)      = @_;
  my ($iter_expr, $exprs)     = match($args);
  my ($name,      $iter_atom) = flat($iter_expr);
  my $type = get_iter_type($t, $iter_atom);
  set_name_value($t, $name, $type);
  lint_my_block($t, $exprs);
}

sub lint_my_set {
  my ($t,   $args)  = @_;
  my ($sym, $value) = flat($args);
  my $sym_type   = get_atom_type($t, $sym);
  my $value_type = get_atom_type($t, $value);
  if ($sym_type ne $value_type) {
    say "|$sym_type| != |$value_type|";
    report($t, "assign type not same with define!");
  }
}

sub lint_my_sym_list {
  my ($t, $list) = @_;
  for my $sym (@{ atoms($list) }) {
    next if is_sym($sym);
    report($t, "Symbol List have no variable!");
  }
}

sub lint_my_sym {
  my ($t, $name) = @_;
  if (not(is_define($t, $name))) {
    report($t, "not defined symbol: |$name|");
  }
}

sub is_define {
  my ($t, $name) = @_;
  my $stack = $t->{'stack'};
  for my $ns (@{$stack}) {
    my $stable = $t->{'st'};
    if (exists $stable->{$ns}{$name}) { return 1 }
  }
  return 0;
}

sub get_atom_type {
  my ($t,    $atom)  = @_;
  my ($name, $value) = flat($atom);
  update_pos($t, $atom);
  given ($name) {
    when ('Type')    { return $value }
    when ('Int')     { return $name }
    when ('Str')     { return $name }
    when ('Bool')    { return $name }
    when ('Hash')    { return $name }
    when ('Char')    { return 'Str' }
    when ('Lstr')    { return 'Str' }
    when ('String')  { return 'Str' }
    when ('Cursor')  { return 'Cursor' }
    when ('Lint')    { return 'Lint' }
    when ('Array')   { return get_array_type($t, $value) }
    when ('Aindex')  { return get_aindex_type($t, $value) }
    when ('Sym')     { return get_sym_type($t, $value) }
    when ('if')      { report($t, "$name as argument") }
    when ('elif')    { report($t, "$name as argument") }
    when ('else')    { report($t, "$name as argument") }
    when ('given')   { report($t, "$name as argument") }
    when ('when')    { report($t, "$name as argument") }
    when ('then')    { report($t, "$name as argument") }
    when ('func')    { report($t, "$name as argument") }
    when ('my')      { report($t, "$name as argument") }
    when ('our')     { report($t, "$name as argument") }
    when ('use')     { report($t, "$name as argument") }
    when ('import')  { report($t, "$name as argument") }
    when ('package') { report($t, "$name as argument") }
    when ('const')   { report($t, "$name as argument") }
    when ('for')     { report($t, "$name as argument") }
    when ('while')   { report($t, "$name as argument") }
    when ('return')  { report($t, "$name as argument") }
    default { return get_call_type($t, $name, $value) }
  }
}

sub get_sym_type {
  my ($t, $name) = @_;
  my $value = get_name_value($t, $name);
  if (is_str($value)) { return $value }
  return 'Fn';
}

sub get_call_type {
  my ($t, $name, $args) = @_;
  my $value = get_name_value($t, $name);
  if (is_str($value)) { return $value }
  return value($value);
}

sub get_array_type {
  my ($t, $args) = @_;
  if (is_blank($args)) { return 'Array' }
  my $sub_type = get_atom_type($t, name($args));
  if ($sub_type eq 'Int') { return 'Ints' }
  return 'Array';
}

sub get_arange_type {
  my ($t, $args) = @_;
  my $sym = name($args);
  my $type = get_atom_type($t, $sym);
  if ($type eq 'Array') { return $type }
  report($t, "Not Array arange");
}

sub get_iter_type {
  my ($t, $atom) = @_;
  my $type = get_atom_type($t, $atom);
  given ($type) {
    when ('Array') { return 'Str' }
    when ('Hash')  { return 'Str' }
    when ('Str')   { return 'Str' }
    when ('Ints')  { return 'Int' }
    when ('Int+')  { return 'Int' }
    when ('Str+')  { return 'Str' }
    default { report($t, "|$type| could not index") }
  }
  return True;
}

sub lint_my_aindex {
  my ($t, $args) = @_;
  lint_my_atoms($t, $args);
  return True;
}

sub get_aindex_type {
  my ($t,   $args)   = @_;
  my ($sym, $indexs) = match($args);
  my $value = get_atom_type($t, $sym);
  for my $index (@{ atoms($indexs) }) {
    my $type = get_atom_type($t, $index);
    my $name = value($index);
    $value = get_index_type($t, $value, $type, $name);
  }
  return $value;
}

sub get_index_type {
  my ($t, $value, $type, $name) = @_;
  given ($value) {
    when ('Array') {
      if ($type eq 'Int') { return 'Str' }
      report($t, "Array index is: $type")
    }
    when ('Ints') {
      if ($type eq 'Int') { return 'Int' }
      report($t, "Ints index is $type")
    }
    when ('Hash') {
      if ($type eq 'Str') { return 'Str' }
      report($t, "Hash index is: |$type|")
    }
    when ('Table') {
      if ($type eq 'Str') { return 'Hash' }
      report($t, "Table index is: |$type|")
    }
    when ('Cursor') {
      if ($type eq 'Str') {
        given ($name) {
          when ('text')    { return 'Str' }
          when ('ns')      { return 'Hash' }
          when ('off')     { return 'Int' }
          when ('depth')   { return 'Int' }
          when ('len')     { return 'Int' }
          when ('line')    { return 'Int' }
          when ('maxline') { return 'Int' }
          when ('maxoff')  { return 'Int' }
          default { report($t, "Cursor !exists $name") }
        }
      }
      report($t, "Cursor index is: |$type|")
    }
    when ('Lint') {
      if ($type eq 'Str') {
        given ($name) {
          when ('offline') { return 'Str' }
          when ('st')      { return 'Table' }
          when ('stack')   { return 'Array' }
          when ('ret')     { return 'Str' }
          when ('parser')  { return 'Hash' }
          when ('cursor')  { return 'Cursor' }
          default { report($t, "Lint !exists $name") }
        }
      }
      report($t, "Lint index is: |$type|")
    }
    default { report($t, "Could not index: $value") }
  }
  return True;
}

sub update_pos {
  my ($t, $atom) = @_;
  $t->{'offline'} = offline($atom);
  return True;
}

sub ns {
  my $t     = shift;
  my $stack = $t->{'stack'};
  return $stack->[0];
}

sub in_package {
  my ($t, $ns) = @_;
  in_ns($t, $ns);
  set_name_value($t, $ns, 'package');
  return True;
}

sub in_ns {
  my ($t, $ns) = @_;
  $t->{'st'}{$ns} = {};
  unshift @{ $t->{'stack'} }, $ns;
  return True;
}

sub out_block {
  my ($t, $ns) = @_;
  out_ns($t);
  my $table = $t->{'st'};
  delete $table->{$ns};
  return True;
}

sub out_ns {
  my $t = shift;
  shift @{ $t->{'stack'} };
  return True;
}

sub set_name_value {
  my ($t, $name, $value) = @_;
  my $ns     = ns($t);
  my $stable = $t->{'st'};
  if (exists $stable->{$ns}{$name}) {
    report($t, "exists symbol define |$name|.");
  }
  $t->{'st'}{$ns}{$name} = $value;
  return True;
}

sub get_name_value {
  my ($t, $name) = @_;
  my $stack = $t->{'stack'};
  for my $ns (@{$stack}) {
    my $stable = $t->{'st'};
    if (exists $stable->{$ns}{$name}) {
      return $t->{'st'}{$ns}{$name};
    }
  }
  report($t, "symbol <$name> not define!");
  return False;
}
1;
