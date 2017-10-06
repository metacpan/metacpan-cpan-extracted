package Mylisp::Lint;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(new_lint lint_ast);

use YAML::XS qw(Dump);
use Spp::Builtin qw(len first read_file is_str
  to_end to_json clean_ast rest is_array);
use Spp::Core qw(is_sym is_atom_str);

sub new_lint {
  my $code  = shift;
  my $table = {
    '.str'   => $code,
    '.pos'   => [1, 1, 1, 1],
    '.stack' => [],
  };
  return $table;
}

sub set_pos {
  my ($lint, $pos) = @_;
  $lint->{'.pos'} = $pos;
}

sub report {
  my ($lint, $message) = @_;
  my $str = $lint->{'.str'};
  my $pos = $lint->{'.pos'};
  my ($off, $line, $offset, $len) = @{$pos};
  my $line_str = to_end(substr($str, ($off - $offset)));
  my $tip_str = (' ' x $offset) . '^';
  say "line: $line -> $message 
  $line_str
  $tip_str";
  exit();
}

sub stack {
  my $lint = shift;
  return $lint->{'.stack'};
}

sub ns {
  my $lint  = shift;
  my $stack = stack($lint);
  return $stack->[0];
}

sub in_module {
  my ($lint, $ns) = @_;
  unshift @{ stack($lint) }, $ns;

  # puts code together
  # it is impossible to enter have enter
  $lint->{$ns} = {};
  my_sym_value($lint, $ns, ['module']);
}

## class is a namespace like struct or new type
sub in_class {
  my ($lint, $ns) = @_;
  unshift @{ stack($lint) }, $ns;
  $lint->{$ns} = {};
  my_sym_value($lint, $ns, ['class']);
}

sub in_block {
  my ($lint, $ns) = @_;
  $lint->{$ns} = {};
  unshift @{ stack($lint) }, $ns;
}

sub out_ns {
  my $lint = shift;
  shift @{ stack($lint) };
}

sub out_block {
  my ($lint, $ns) = @_;
  delete $lint->{$ns};
  shift @{ stack($lint) };
}

sub is_define {
  my ($lint, $name) = @_;
  my $stack = stack($lint);
  for my $ns (@{$stack}) {
    return 1 if exists($lint->{$ns}{$name});
  }
  return 0;
}

sub my_sym_value {
  my ($lint, $name, $value) = @_;
  my $ns = ns($lint);
  if (exists $lint->{$ns}{$name}) {
    report($lint, "exists symbol define <$name>.");
  }
  $lint->{$ns}{$name} = $value;
}

sub get_sym_value {
  my ($lint, $name) = @_;
  my $stack = stack($lint);
  for my $ns (@{$stack}) {
    if (exists $lint->{$ns}{$name}) {
      return $lint->{$ns}{$name};
    }
  }
  report($lint, "symbol <$name> not define!");
}

sub get_sym_type {
  my ($lint, $name) = @_;
  my $value = get_sym_value($lint, $name);
  return $value->[0];
}

sub get_sym_return_type {
  my ($lint, $name) = @_;
  my $value = get_sym_value($lint, $name);
  if (len($value) == 3) {
    return $value->[1];
  }
  report($lint, "$name is No call");
}

sub is_have {
  my ($lint, $module, $name) = @_;
  if (exists $lint->{$module}{$name}) { return 1 }
  return 0;
}

## ===================================================
## init AST
## in ns or class, load module, register imported func
## register func
## ===================================================

sub lint_ast {
  my ($lint, $ast) = @_;
  init_lint($lint, $ast);

  # return 1;
  lint_atoms($lint, $ast);
  return 1;
}

sub lint_atoms {
  my ($lint, $atoms) = @_;
  for my $atom (@{$atoms}) {

    # say to_json(clean_ast($atom));
    lint_atom($lint, $atom);
  }
}

sub init_lint {
  my ($lint, $ast) = @_;
  for my $expr (@{$ast}) {
    my ($name, $args, $pos) = @{$expr};
    set_pos($lint, $pos);
    given ($name) {
      when ('module') { in_module($lint, $args) }

      # in class not export any func.
      when ('class') { in_class($lint, $args) }
      when ('use') { use_module($lint, $args) }
      when ('import') { import_module($lint, $args) }

      # register func name type
      when ('func') { my_func($lint, $args) }
    }
  }

  # say Dump($lint->{'Cpan::Spp::ToSpp'});
}

## =====================================
# use-module()
# load file according module name, parse and
# opt, gather all func name args type return-type
# return array
# use module would import all exported symbol
sub use_module {
  my ($lint, $module) = @_;
  my $load_list = load_module($module);
  for my $name_value (@{$load_list}) {
    my ($name, $value) = @{$name_value};
    my_sym_value($lint, $name, $value);
  }
}

sub import_module {
  my ($lint, $args) = @_;
  my $module       = $args->[0][1];
  my $load_list    = load_module($module);
  my $slist        = $args->[1][1];
  my $names        = [map { $_->[1] } @{$slist}];
  my @import_names = ();
  for my $name_value (@{$load_list}) {
    my ($name, $value) = @{$name_value};
    push @import_names, $name;
    if ($name ~~ $names) {
      my_sym_value($lint, $name, $value);
    }
  }
  for my $name (@{$names}) {
    next if ($name ~~ [@import_names]);
    say "$name is not imported";
  }
}

sub load_module {
  my $module = shift;
  my @dirs   = split '::', ($module . '.spp');
  my $path   = join '/', @dirs;
  if (not(-e $path)) {
    say "not exists file: $path!";
    exit;
  }
  my $code = read_file($path);

  print "load module: $path\n";
  my $ast = Mylisp::mylisp_to_ast($code);
  return gather_export_list($ast);
}

sub gather_export_list {
  my $ast  = shift;
  my $list = [];
  for my $expr (@{$ast}) {
    my ($name, $args) = @{$expr};
    if ($name eq 'func') {
      my $call = $args->[0][0];
      next if first($call) eq '_';
      my $func_value = get_func_value($args);
      push @{$list}, [$call, $func_value];
    }
    if ($name eq 'my') {
      my ($sym, $value) = @{$args};
      my $name       = $sym->[1];
      my $value_type = $value->[0];
      push @{$list}, [$name, [$value_type]];
    }
  }
  return $list;
}

## =============================================
## [call args] [-> return-type]
##

sub get_func_value {
  my $args        = shift;
  my $call_args   = $args->[0][1];
  my $return_expr = $args->[1];

  # say to_json(clean_ast($return_expr));
  my $args_pattern = get_args_pattern($call_args);
  my $return_type  = get_return_type($return_expr);

  # say to_json([$return_type]);
  return ['Fn', $return_type, $args_pattern];
}

## ==============================================
## pattern Str Array Array is rule
## use type grammar make as rule, use match-rule
## get type str and use type pattern match it
## if match then
sub get_args_pattern {
  my $args = shift;
  return join(' ', map { $_->[1] } @{$args});
}

sub get_return_type {
  my $expr = shift;
  #say to_json([$expr]);
  #if ($expr->[0] ne '->') { return 'None' }
  # say to_json(clean_ast($expr));
  my $args = $expr->[1];
  my $types = [map { $_->[1] } @{$args}];
  if (len($types) == 1) {
    return $types->[0];
  }
  return $types;
}

## =============================================
## gather local ast func and def name and value
## =============================================

sub my_func {
  my ($lint, $args) = @_;
  my $call       = $args->[0][0];
  my $func_value = get_func_value($args);
  my_sym_value($lint, $call, $func_value);
}

## ================================================
## lint atom Function List
## ================================================

sub lint_atom {
  my ($lint, $atom) = @_;
  my ($name, $value, $pos) = @{$atom};
  set_pos($lint, $pos);
  given ($name) {
    when ('func') { lint_func($lint, $value) }
    when ('my') { lint_my($lint, $value) }
    when ('Sym') { lint_sym($lint, $value) }
    when ('Call') { lint_call($lint, $value) }
    when ('Oper') { lint_call($lint, $value) }
    when ('not')  { lint_call($lint, $value) }
    when ('Ocall') { lint_ocall($lint, $value) }
    when ('for') { lint_for($lint, $value) }
    when ('end') { lint_end($lint, $value) }
    when ('return') { lint_return($lint, $value) }
    when ('set') { lint_set($lint, $value) }

    when ('then') { lint_atom($lint, $value) }
    when ('else') { lint_atom($lint, $value) }

    when ('while')  { lint_atoms($lint, $value) }
    when ('Hash')   { lint_atoms($lint, $value) }
    when ('Pair')   { lint_atoms($lint, $value) }
    when ('exprs')  { lint_atoms($lint, $value) }
    when ('Aindex') { lint_atoms($lint, $value) }
    when ('Hkey')   { lint_atoms($lint, $value) }
    when ('Arange') { lint_atoms($lint, $value) }
    when ('given')  { lint_atoms($lint, $value) }
    when ('when')   { lint_atoms($lint, $value) }
    when ('if')     { lint_atoms($lint, $value) }
    when ('elif')   { lint_atoms($lint, $value) }
    when ('Array')  { lint_atoms($lint, $value) }
    when ('String') { lint_atoms($lint, $value) }
    when ('module') { return 1 }
    when ('import') { return 1 }
    when ('Range')  { return 1 }
    when ('Str')    { return 1 }
    when ('Lstr')   { return 1 }
    when ('Int')    { return 1 }
    when ('Bool')   { return 1 }
    when ('Ns')     { return 1 }
    when ('class')  { return 1 }
    when ('use')    { return 1 }
    when ('->')     { return 1 }
    when ('type')   { return 1 }
    default {
      say to_json(clean_ast($atom));
      say "unknown Atom to lint!";
      exit();
    }
  }
}

## =========================================
## Lint Func: in-call lint atoms
##
sub lint_func {
  my ($lint, $args) = @_;

  # return 1 if len($args) == 2;
  my $name_args = $args->[0];
  my $exprs     = rest(rest($args));
  my $ns        = $name_args->[0];
  in_block($lint, $ns);
  my $func_args = $name_args->[1];
  for my $arg (@{$func_args}) {
    my ($name, $type) = @{$arg};
    my_sym_value($lint, $name, [$type]);
  }
  lint_atoms($lint, $exprs);

  # say to_json($args);
  out_block($lint, $ns);
}
## =====================================
## lint-my():
##
sub lint_my {
  my ($lint, $args)  = @_;
  my ($sym,  $value) = @{$args};

  # say 'reach here';
  my $type = get_atom_type($lint, $value);
  lint_atom($lint, $value);

  # say 'reach here';
  if (is_sym($sym)) {
    my $name = $sym->[1];
    if (is_str($type)) {
      my_sym_value($lint, $name, [$type]);
      return 1;
    }

    # say to_json([$value]);
    report($lint, "one sym accept more assign");
  }
  if ($sym->[0] eq 'List') {
    my $syms = $sym->[1];
    lint_list($lint, $syms);
    my $names = [map { $_->[1] } @{$syms}];
    if (is_array($type)) {
      if (len($type) != len($names)) {
        report($lint, "assign amount not same");
      }
      my $index = 0;
      for my $name (@{$names}) {
        my $name_type = $type->[$index];
        my_sym_value($lint, $name, [$name_type]);
        $index++;
      }
    }
  }
}

sub lint_list {
  my ($lint, $list) = @_;
  if (all_is_sym_atom($list)) { return 1 }
  report($lint, "List have no variable!");
}

sub all_is_sym_atom {
  my $list = shift;
  for my $atom (@{$list}) {
    return 0 if !is_sym($atom);
  }
  return 1;
}

## ===============================================
## lint symbol
## check if it defined
sub lint_sym {
  my ($lint, $sym_name) = @_;
  return 1 if is_define($lint, $sym_name);
  if (index($sym_name, '::') > -1) {
    ## const name could exported
    my $module_name = get_module_name($sym_name);
    my ($module, $name) = @{$module_name};
    if (!exists $lint->{$module}) {
      report($lint, "not exists module: |$module|.");
    }
    my $table = $lint->{$module};
    if (!exists $table->{$name}) {
      report($lint, "module not exists: |$name|.");
    }

    # register it for next time lint easily
    my_sym_value($lint, $sym_name, 1);
  }
  report($lint, "undefine symbol: |$sym_name|.");
}

sub get_module_name {
  my $sym_name = shift;
  my $index    = rindex($sym_name, '::');
  my $module   = substr($sym_name, 0, $index);
  my $name     = substr($sym_name, $index + 2);
  return [$module, $name];
}

## ================================================
## lint Call: only Check Symbol if defined
##
sub lint_call {
  my ($lint, $atom) = @_;
  my ($name, $args, $pos) = @{$atom};
  set_pos($lint, $pos);
  lint_sym($lint, $name);
  lint_atoms($lint, $args);
}

sub lint_ocall {
  my ($lint, $atom) = @_;
  my ($name, $args, $pos) = @{$atom};
  lint_atoms($lint, $args);
  set_pos($lint, $pos);
  my $object_name = $args->[0][1];
  my $class = get_sym_value($lint, $object_name);
  ## if is local function call return 1
  return 1 if is_have($lint, $class, $name);

  # report($lint, "Not exists $name in Class: $class.");
}

sub lint_for {
  my ($lint,      $args)      = @_;
  my ($iter_expr, $for_exprs) = @{$args};

  # say "in lint for";
  my $args      = $iter_expr->[1];
  my $name      = $args->[0][1];
  my $iter_atom = $args->[1];

  # say to_json($iter_atom);
  my $type = get_iter_type($lint, $iter_atom);

  # say "go to here: $type";
  my_sym_value($lint, $name, [$type]);
  lint_atom($lint, $for_exprs);
}

sub get_iter_type {
  my ($lint, $atom) = @_;
  my $type = get_atom_type($lint, $atom);
  given ($type) {
    when ('Array')    { return 'Str' }
    when ('Array')    { return 'Str' }
    when ('IntArray') { return 'Int' }
    when ('Hash')     { return 'Str' }
    when ('Str')      { return 'Str' }
    when ('ManyStr')  { return 'Str' }
    when ('ManyInt')  { return 'Int' }
    default {
      report($lint, "type: <$type> could not iter")
    }
  }
}

sub lint_end {
  my $lint = shift;
  out_ns($lint);
}

sub lint_return {
  my ($lint, $args) = @_;
  my $call_name = ns($lint);
  my $call_type = get_sym_return_type($lint, $call_name);
  my @args_types =
    map { get_atom_type($lint, $_) } @{$args};
  my $args_type = join ' ', @args_types;
  if (is_same($call_type, $args_type)) { return 1 }
  my $args_type_str = to_json($args_type);
  my $call_type_str = to_json($call_type);

# report($lint, "return <$args_type_str> != <$call_type_str>");
}

sub is_same {
  my ($call, $args) = @_;
  if (is_str($call)) {
    return $call eq $args;
  }
  my $call_type = join(' ', @{$call});
  return $call_type eq $args;
}

sub lint_set {
  my ($lint, $args)  = @_;
  my ($sym,  $value) = @{$args};
  my $sym_type   = get_atom_type($lint, $sym);
  my $value_type = get_atom_type($lint, $value);
  return 1 if $sym_type eq $value_type;
  report($lint, "assign value is not same with var");
}

sub get_atom_type {
  my ($lint, $atom) = @_;

  # say to_json(clean_ast($atom));
  my ($name, $value) = @{$atom};
  given ($name) {
    when ('Int')    { return $name }
    when ('Str')    { return $name }
    when ('Bool')   { return $name }
    when ('Hash')   { return $name }
    when ('Lstr')   { return 'Str' }
    when ('String') { return 'Str' }
    when ('not')    { return 'Bool' }
    when ('Array') {
      return get_array_type($lint, $value)
    }
    when ('Aindex') {
      return get_aindex_type($lint, $value)
    }
    when ('Hkey') {
      return get_aindex_type($lint, $value)
    }
    when ('Arange') {
      return get_arange_type($lint, $value)
    }
    when ('Call')  { return get_call_type($lint, $value) }
    when ('Oper')  { return get_call_type($lint, $value) }
    when ('Ocall') { return get_call_type($lint, $value) }
    when ('Sym') { return get_sym_type($lint, $value) }
    default {
      report($lint, "Could not get macro type");
    }
  }
}

sub get_array_type {
  my ($lint, $atoms) = @_;
  if (len($atoms) == 0) { return 'Array' }
  my $type = get_atom_type($lint, $atoms->[0]);
  given ($type) {
    when ('Str') { return 'Array' }
    when ('Int') { return 'IntArray' }
    default {
      report($lint, "Mylisp only use IntArray or Array")
    }
  }
}

sub get_aindex_type {
  my ($lint, $args)  = @_;
  my ($sym,  $index) = @{$args};
  my $sym_type = get_sym_type($lint, $sym->[1]);
  my $index_type = get_atom_type($lint, $index);
  given ($sym_type) {

    # spp could use index to substr or subarray
    when ('Str') {
      return 'Str' if $index_type eq 'Int';
      report($lint, "Str index not Int")
    }
    when ('Array') {
      return 'Str' if $index_type eq 'Int';
      report($lint, "Array index not Int")
    }
    when ('IntArray') {
      return 'Int' if $index_type eq 'Int';
      report($lint, "Array index not Int")
    }
    when ('Hash') {
      return 'Str' if $index_type eq 'Str';
      report($lint, 'Hash index is not Str');
    }
    when ('StrHash') {
      return 'Hash' if $index_type eq 'Str';
      report($lint, 'Hash index is not Str');
    }
    when ('Cursor') {
      if (is_atom_str($index)) {
        my $index_name = $index->[1];
        given ($index_name) {
          when ('str') { return 'Str' }
          when ('ns')  { return 'Hash' }
          default      { return 'Int' }
        }
      }
      say to_json($index);
      report($lint, "Cursor field name is not Str");
    }
    when ('Lint') {
      if (is_atom_str($index)) {
        my $index_name = $index->[1];
        given ($index_name) {
          when ('code')  { return 'Str' }
          when ('stack') { return 'Array' }
          when ('st')    { return 'StrHash' }
          when ('pos')   { return 'Str' }
          default        { return 'Int' }
        }
      }
      say to_json($index);
      report($lint, "Cursor field name is not Str");
    }
    default {
      report($lint, "|$sym_type| Could not index!")
    }
  }
}

sub get_arange_type {
  my ($lint, $args) = @_;
  my $sym = $args->[0];
  my $type = get_sym_type($lint, $sym->[1]);
  return $type if end_with($type, 'Array');
  report($lint, "Not Array arange");
}

sub get_call_type {
  my ($lint, $expr) = @_;
  my $call = $expr->[0];

  # my $value = get_sym_value($lint, $call);
  # say to_json($value);
  my $value = get_sym_value($lint, $call);
  if ($value->[0] eq 'Fn') {
    return $value->[1];
  }
  report($lint, "$call is not call name");
}

1;
