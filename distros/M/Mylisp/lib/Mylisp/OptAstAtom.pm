package Mylisp::OptAstAtom;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(opt_ast_atom);

use Spp::Builtin;
use Spp::Core;
use Mylisp::Core;
use Mylisp::Stable;

sub opt_ast_atom {
   my $ast = shift;
   if (is_atom($ast)) {
      my $atom = opt_atom($ast);
      return [$atom];
   }
   return opt_atoms($ast);
}

sub opt_atom {
   my $atom = shift;
   my ($name, $value, $pos) = @{$atom};
   given ($name) {
      when ('Expr')   { opt_expr($value, $pos)   }
      when ('Array')  { opt_array($value, $pos)  }
      when ('Hash')   { opt_hash($value, $pos)   }
      when ('Pair')   { opt_pair($value, $pos)   }
      when ('Ocall')  { opt_ocall($value, $pos)  }
      when ('Lcall')  { opt_lcall($value, $pos)  }
      when ('Onew')   { opt_onew($value, $pos)   }
      when ('Aindex') { opt_args($atom) }
      when ('Hkey')   { opt_args($atom) }
      when ('Arange') { opt_args($atom) }
      when ('Range')  { opt_range($value, $pos)  }
      when ('Str')    { opt_str($value, $pos)    }
      when ('String') { opt_string($value, $pos) }
      when ('Kstr')   { opt_kstr($value, $pos)   }
      when ('Sub')    { opt_sym($value, $pos)    }
      when ('Var')    { opt_sym($value, $pos)    }
      when ('Oper')   { opt_sym($value, $pos)    }
      when ('Scalar') { opt_sym($value, $pos)    }
      when ('Char')   { opt_char($value, $pos)   }
      when ('Int')    { return $atom }
      default {
         say to_json($atom);
         my $line = $pos->[1];
         error("line: $line unknown atom opt!");
      }
   }
}

sub opt_expr {
   my ($expr, $pos) = @_;
   if ((len($expr) == 3) && is_atom_oper($expr->[1])) {
      my $name     = $expr->[1][1];
      my $args     = [$expr->[0], $expr->[2]];
      my $opt_args = opt_atoms($args);
      my $opt_expr = [$name, $opt_args, $pos];
      return ['Oper', $opt_expr, $pos];
   }
   my $action = $expr->[0];
   my ($type, $name) = @{$action};
   my $args     = rest($expr);
   my $opt_args = opt_atoms($args);
   my $opt_expr = [$name, $opt_args, $pos];
   given ($type) {
      when ('Oper')  { return ['Oper', $opt_expr, $pos] }
      when ('Sub')   { return opt_macro($opt_expr)      }
      when ('Ocall') { return opt_ocall_expr($opt_expr) }
      when ('Onew')  { return opt_onew_expr($opt_expr)  }
      when ('Lcall') { return opt_lcall_expr($opt_expr) }
      default {
         my $line = $pos->[1];
         error("line: $line unknown Expr action: |$type|");
      }
   }
}

sub opt_macro {
   my $expr = shift;
   my ($name, $args, $pos) = @{$expr};
   given ($name) {
      when ('func')   { opt_func($args, $pos) }
      when ('def')    { opt_def($args, $pos) }
      when ('fn')     { opt_fn($args, $pos) }
      when ('package'){ opt_ns($args, $pos) }
      when ('class')  { opt_class($args, $pos) }
      when ('use')    { opt_use($args, $pos) }
      when ('my')     { opt_my($args, $pos) }
      when ('return') { return $expr }
      when ('set')    { return $expr }
      when ('end')    { return $expr }
      when ('const')  { return $expr }
      when ('for')    { return $expr }
      when ('while')  { return $expr }
      when ('given')  { return $expr }
      when ('case')   { return $expr }
      when ('if')     { return $expr }
      when ('else')   { return $expr }
      default { return ['Call', $expr, $pos] }
   }
}

sub opt_func {
   my ($args, $pos) = @_;
   $args->[0] = $args->[0][1];
   return ['func', $args, $pos];
}

sub opt_def {
   my ($args, $pos) = @_;
   $args->[0] = $args->[0][1];
   return ['def', $args, $pos];
}

sub opt_fn {
   my ($args, $pos) = @_;
   $args->[0][0] = 'List';
   return ['fn', $args, $pos];
}

sub opt_use {
   my ($args, $pos) = @_;
   $args->[0][0] = 'Ns';
   if (len($args) == 1) {
      return ['use', $args, $pos];
   }
   $args->[1][0] = 'Slist';
   return ['use', $args, $pos];
}

sub opt_my {
   my ($args, $pos) = @_;
   my $var = $args->[0];
   if (is_atom_name($var, 'Array')) {
      $args->[0][0] = 'List';
   }
   return ['my', $args, $pos];
}

sub opt_ns {
   my ($args, $pos) = @_;
   $args->[0][0] = 'Ns';
   return ['ns', $args, $pos];
}

sub opt_class {
   my ($args, $pos) = @_;
   $args->[0][0] = 'Ns';
   return ['class', $args, $pos];
}

sub opt_array {
   my ($atoms, $pos) = @_;
   if (is_str($atoms)) { return ['Array', [], $pos] }
   return ['Array', opt_atoms($atoms), $pos];
}

sub opt_hash {
   my ($pairs, $pos) = @_;
   if (is_str($pairs)) { return ['Hash', [], $pos] }
   return ['Hash', opt_atoms($pairs), $pos];
}

sub opt_pair {
   my ($pair, $pos) = @_;
   my ($key, $value) = @{$pair};
   my $opt_key = $key->[1];
   my $opt_value = opt_atom($value);
   return [$opt_key, $opt_value, $pos];
}

sub opt_ocall_expr {
   my $expr = shift;
   my ($ocall, $args, $pos) = @{$expr};
   my $opt_atoms = opt_atoms($ocall);
   my ($object, $method) = @{$opt_atoms};
   unshift @{$args}, $object;
   return ['Ocall', [$method->[1], $args, $pos], $pos];
}

sub opt_ocall {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   my ($object, $method) = @{$opt_atoms};
   return ['Ocall', [$method->[1], [$object]], $pos];
}

sub opt_lcall_expr {
   my $expr = shift;
   my ($lcall, $args, $pos) = @{$expr};
   my $opt_atoms = opt_atoms($lcall);
   my ($first_arg, $call) = @{$opt_atoms};
   unshift @{$args}, $first_arg;
   return ['Call', [$call->[1], $args, $pos], $pos];
}

sub opt_lcall {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   my ($first_arg, $call) = @{$opt_atoms};
   return ['Call', [$call->[1], [$first_arg]], $pos];
}

sub opt_onew_expr {
   my $expr = shift;
   my ($onew, $args, $pos) = @{$expr};
   my $opt_atoms = opt_atoms($onew);
   my ($class, $method) = @{$opt_atoms};
   $class->[0] = 'Ns';
   unshift @{$args}, $class;
   return ['Onew', [$method->[1], $args, $pos], $pos];
}

sub opt_onew {
   my ($args, $pos) = @_;
   my $opt_atoms = opt_atoms($args);
   my ($class, $method) = @{$opt_atoms};
   $class->[0] = 'Ns';
   return ['Onew', [$method->[1], [$class]], $pos];
}

sub opt_args {
   my $atom = shift;
   my ($name, $args, $pos) = @{$atom};
   my $opt_atoms = opt_atoms($args);
   return [$name, $opt_atoms, $pos];
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

sub opt_str {
   my ($capture_str, $pos) = @_;
   my $str = substr($capture_str, 1, -1);
   return ['Str', $str, $pos];
}

sub opt_string {
   my ($atoms, $pos) = @_;
   if (is_str($atoms)) { return ['Str', '', $pos] }
   return ['Str', $atoms, $pos];
}

sub opt_char {
   my ($char, $pos) = @_;
   return ['Str', ['Char', $char, $pos], $char];
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

sub opt_atoms {
   my $atoms = shift;
   return [map { opt_atom($_) } @{$atoms}];
}

1;
