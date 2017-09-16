package Mylisp::Stable;

use 5.012;
no warnings "experimental";

use Spp::Builtin;
use Spp::Core;

sub new {
   my ($class, $str) = @_;
   my $self = {
      '.str'     => $str,
      '.pos'     => [1, 1, 1, 1],
      '.stack'   => ['Main'],
      'Main'     => {
         'say'     => 1,
         'die'     => 1,
         'exists'  => 1,
         'print'   => 1,
         '&&'      => 1,
         '||'      => 1,
         'eq'      => 1,
         'ne'      => 1,
         '=='      => 1,
         '!='      => 1,
         '+'       => 1,
         '-'       => 1,
         'x'       => 1,
         '<'       => 1,
         '<='      => 1,
         '>'       => 1,
         '>='      => 1,
         '~~'      => 1,
         'next-if' => 1,
         'last-if' => 1,
         'exit-if' => 1,
         'return'  => 1,
         '>>'      => 1,
         '>>'      => 1,
         'shift'   => 1,
         'join'    => 1,
         'split'   => 1,
         'push'    => 1,
         'not'     => 1,
         'exit'    => 1,
         'map'     => 1,
         'STDIN'   => 1,
         'inc'     => 1,
         'delete'  => 1,
         'rename'  => 1,
         'concat'  => 1,
         'chr'     => 1,
         'hex'     => 1,
         'index'  => 1,
         'substr' => 1,
         'length' => 1,
         'bless'  => 1,
      },
   };
   return bless($self, $class);
}

sub str { 
   my $self = shift;
   return $self->{'.str'};
}

sub pos { 
   my $self = shift;
   return $self->{'.pos'};
}

sub set_pos {
   my ($self, $pos) = @_;
   $self->{'.pos'} = $pos;
}

sub report {
   my ($self, $message) = @_;
   my $str = $self->str;
   my $pos = $self->pos;
   my ($off, $line, $pos, $len) = @{$pos};
   my $line_str = to_end(substr($str, ($off - $pos)));
   my $tip_str = (' ' x $pos) . '^';
   say "line: $line -> $message 
      $line_str
      $tip_str";
      exit();
}

sub stack {
   my $self = shift;
   return $self->{'.stack'};
}

sub ns {
   my $self  = shift;
   my $stack = $self->stack;
   return $stack->[0];
}

sub in_ns {
   my ($self, $ns) = @_;
   unshift @{ $self->stack }, $ns;
   if (exists $self->{$ns}) { return 1 }
   $self->{$ns} = {};
   $self->my_sym_value($ns, 'Package');
}

sub in_class {
   my ($self, $ns) = @_;
   if (exists $self->{$ns}) {
      unshift @{ $self->stack }, $ns;
      return 1;
   }
   $self->{$ns} = {};
   $self->my_sym_value($ns, 'Class');
}

sub in_call {
   my ($self, $ns) = @_;
   $self->{$ns} = {};
   unshift @{ $self->stack }, $ns;
}

sub out_ns {
   my $self = shift;
   shift @{ $self->stack };
}

sub out_call {
   my ($self, $ns) = @_;
   delete $self->{$ns};
   shift @{ $self->stack };
}

sub is_define {
   my ($self, $name) = @_;
   my $stack = $self->stack;
   for my $ns (@{$stack}) {
      return 1 if exists($self->{$ns}{$name});
   }
   return 0;
}

sub my_sym_value {
   my ($self, $name, $value) = @_;
   my $ns = $self->ns;
   if (exists $self->{$ns}{$name}) {
      $self->report("exists symbol define <$name>.");
   }
   $self->{$ns}{$name} = $value;
}

sub get_sym_value {
   my ($self, $name) = @_;
   my $stack = $self->stack;
   for my $ns (@{$stack}) {
      if (exists $self->{$ns}{$name}) {
         return $self->{$ns}{$name};
      }
   }
   $self->report("symbol <$name> not define!");
}

sub is_exists {
   my ($self, $module, $name) = @_;
   if (!exists $self->{$module}) { return 0 }
   my $table = $self->{$module};
   if (!exists $table->{$name}) { return 0 }
   return 1;
}

sub lint_ast {
   my ($self, $ast) = @_;
   $self->initial_lint($ast);
   $self->lint_atoms($ast);
   return 1;
}

## ===================================================
## initial AST
## in ns or class, load module, register func
## ===================================================

sub initial_lint {
   my ($self, $ast) = @_;
   for my $expr (@{$ast}) {
      my ($name, $args, $pos) = @{$expr};
      $self->set_pos($pos);
      given ($name) {
         when ('ns')    { $self->in_ns($args)         }
         when ('class') { $self->in_class($args)      }
         when ('use')   { $self->use_module($args)    }
         when ('func')  { $self->register_func($args) }
         when ('def')   { $self->register_func($args) }
      }
   }
}

## =====================================
# use-module()
# load file according module name, parse and
# opt, only gather all def function name value
# return symbol name list, to import all or select parts
sub use_module {
   my ($self, $args) = @_;
   my $module = $args->[0][1];
   my $load_list = load_module($module);
   if (len($args) == 1) {
      for my $name (@{$load_list}) {
         $self->my_sym_value($name, 'Fn');
      }
      return 1;
   }
   my $slist = $args->[1][1];
   my $names = [ map { $_->[1] } @{$slist} ];
   for my $name (@{$names}) {
      if ($name ~~ $load_list) {
         $self->my_sym_value($name, 'Fn');
      } else {
         $self->report("func: |$name| is not exported!")
      }
   }
}

sub load_module {
   my $module = shift;
   my @dirs = split '::', ($module . '.spp');
   unshift @dirs, 'CPAN';
   my $path = join '/', @dirs ;
   if (not (-e $path)) {
      say "not exists file: $path!";
      exit;
   }
   my $code = read_file($path);
   say "load module: $path";
   my $ast = Mylisp::mylisp_to_ast($code);
   return gather_export_list($ast);
}

sub gather_export_list {
   my $ast = shift;
   my $list = [];
   for my $expr (@{$ast}) {
      my ($name, $args) = @{$expr};
      if ($name eq 'def') {
         my $name = $args->[0][0];
         push @{$list}, $name;
      }
   }
   return $list;
}

## =============================================
## gather local ast func and def name and value
## =============================================
sub register_func {
   my ($self, $expr) = @_;
   my $name = $expr->[0][0];
   $self->my_sym_value($name, 1);
}

## ================================================
## lint atom Function List
## ================================================
sub lint_atom {
   my ($self, $atom) = @_;
   my ($name, $value, $pos) = @{$atom};
   $self->set_pos($pos);
   given ($name) {
      when ('my')     { $self->lint_my($value)    }
      when ('const')  { $self->lint_my($value)    } 
      when ('Sym')    { $self->lint_sym($value)   }
      when ('Call')   { $self->lint_call($value)  }
      when ('Oper')   { $self->lint_call($value)  }
      when ('Ocall')  { $self->lint_ocall($value) }
      when ('Onew')   { $self->lint_onew($value)  }
      when ('func')   { $self->lint_func($value)  }
      when ('def')    { $self->lint_func($value)  }
      when ('fn')     { $self->lint_fn($value)    }
      when ('for')    { $self->lint_for($value)   }
      when ('while')  { $self->lint_while($value) }
      when ('end')    { $self->lint_end($value)   }
      when ('Hash')   { $self->lint_hash($value)  }
      when ('exprs')  { $self->lint_atoms($value) }
      when ('set')    { $self->lint_atoms($value) }
      when ('Aindex') { $self->lint_atoms($value) }
      when ('Hkey')   { $self->lint_atoms($value) }
      when ('Arange') { $self->lint_atoms($value) }
      when ('given')  { $self->lint_atoms($value) }
      when ('when')   { $self->lint_atoms($value) }
      when ('then')   { $self->lint_atoms($value) }
      when ('case')   { $self->lint_atoms($value) }
      when ('if')     { $self->lint_atoms($value) }
      when ('elif')   { $self->lint_atoms($value) }
      when ('else')   { $self->lint_atoms($value) }
      when ('ifelse') { $self->lint_atoms($value) }
      when ('Array')  { $self->lint_atoms($value) }
      when ('return') { $self->lint_atoms($value) }
      when ('Range')  { return 1 }
      when ('Str')    { return 1 }
      when ('Int')    { return 1 }
      when ('Bool')   { return 1 }
      when ('ns')     { return 1 }
      when ('class')  { return 1 }
      when ('use')    { return 1 }
      default { 
         say to_json(clean_ast($atom));
         say "unknown Atom to lint!"; exit();
      }
   }
}

sub lint_atoms {
   my ($self, $atoms) = @_;
   for my $atom (@{$atoms}) {
      $self->lint_atom($atom);
   }
}

## =====================================
## lint-my():
## 
sub lint_my {
   my ($self, $args) = @_;
   my ($sym, $value) = @{$args};
   $self->lint_atom($value);
   if (is_atom_sym($sym)) {
      my $name = $sym->[1];
      if ($value->[0] eq 'Onew') {
         my $expr = $value->[1];
         my $args = $expr->[1];
         my $class_atom = $args->[0];
         my $class_name = $class_atom->[1];
         $self->my_sym_value($name, $class_name);
         return 1;
      }
      $self->my_sym_value($name, 1);
      return 1;
   }
   if (is_atom_name($sym, 'List')) {
      my $syms = $sym->[1];
      $self->lint_list($syms);
      for my $sym (@{$syms}) {
         my $name = $sym->[1];
         $self->my_sym_value($name, 1);
      }
   }
}

sub lint_list {
   my ($self, $list) = @_;
   if (all { is_atom_sym($_) } @{$list}) {
      return 1;
   }
   $self->report("List have no variable!");
}

## ===============================================
## lint symbol
## check if it defined
sub lint_sym {
   my ($self, $sym_name) = @_;
   return 1 if $self->is_define($sym_name);
   if (index($sym_name, '::') > -1) {
      ## const name could exported
      my $module_name = get_module_name($sym_name);
      my ($module, $name) = @{$module_name};
      if (!exists $self->{$module}) {
         $self->report("not exists module: |$module|.");
      }
      my $table = $self->{$module};
      if (!exists $table->{$name}) {
         $self->report("module not exists: |$name|.");
      }
      # register it for next time lint easily
      $self->my_sym_value($sym_name, 1);
   }
   $self->report("undefine symbol: |$sym_name|.");
}

sub get_module_name {
   my $sym_name = shift;
   my $index = rindex($sym_name, '::');
   my $module = substr($sym_name, 0, $index);
   my $name = substr($sym_name, $index + 2);
   return [$module, $name];
}

## ================================================
## lint Call: only Check Symbol if defined
##
sub lint_call {
   my ($self, $atom) = @_;
   my ($name, $args, $pos) = @{$atom};
   $self->set_pos($pos);
   $self->lint_sym($name);
   $self->lint_atoms($args);
}

sub lint_ocall {
   my ($self, $atom) = @_;
   my ($name, $args, $pos) = @{$atom};
   $self->lint_atoms($args);
   $self->set_pos($pos);
   my $object_name = $args->[0][1];
   my $class = $self->get_sym_value($object_name);
   ## if is local function call return 1
   return 1 if $self->is_exists($class, $name);
   # $self->report("Not exists $name in Class: $class.");
}

sub lint_onew {
   my ($self, $atom) = @_;
   my ($name, $args, $pos) = @{$atom};
   $self->lint_atoms($args);
   $self->set_pos($pos);
   my $class = $args->[0][1];
   return 1 if $self->is_exists($class, $name) ;
   # $self->report("Not exists $name in Class: $class.");
}

## =========================================
## Lint Func: in-call lint atoms
## 
sub lint_func {
   my ($self, $args) = @_;
   my $name_args = $args->[0];
   my $exprs = rest($args);
   my $ns  = uuid();
   $self->in_call($ns);
   my $func_args = $name_args->[1];
   for my $arg (@{$func_args}) {
      my $name = $arg->[1];
      $self->my_sym_value($name, 1);
   }
   $self->lint_atoms($exprs);
   $self->out_call($ns);
}

sub lint_fn {
   my ($self, $args) = @_;
   my $fn_args = $args->[0][1];
   my $exprs = rest($args);
   my $ns  = uuid();
   $self->in_call($ns);
   for my $arg (@{$fn_args}) {
      my $name = $arg->[1];
      $self->my_sym_value($name, 1);
   }
   $self->lint_atoms($exprs);
   $self->out_call($ns);
}

sub lint_for {
   my ($self, $args) = @_;
   my ($loop, $iter, $for_exprs) = @{$args};
   $self->lint_atom($iter);
   my $name = $loop->[1];
   my $ns = uuid();
   $self->in_call($ns);
   $self->my_sym_value($name, 1);
   $self->lint_atom($for_exprs);
   $self->out_call($ns);
}

sub lint_while {
   my ($self, $args) = @_;
   my ($cond_expr, $while_exprs) = @{$args};
   $self->lint_atom($cond_expr);
   my $ns = uuid();
   $self->in_call($ns);
   $self->lint_atom($while_exprs);
   $self->out_call($ns);
}

sub lint_end {
   my $self = shift;
   $self->out_ns();
}

sub lint_hash {
   my ($self, $pairs) = @_;
   for my $pair (@{$pairs}) {
      my $value = $pair->[1];
      $self->lint_atom($value);
   }
}

1;
