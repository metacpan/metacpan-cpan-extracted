package Mylisp::OptAstMacro;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(opt_ast_macro);

use Spp::Builtin;
use Spp::Core;
use Mylisp::Core;
use Mylisp::Stable;

sub opt_ast_macro {
   my $ast = shift;
   return opt_atoms($ast);
}

sub opt_atoms {
   my $atoms = shift;
   return [ map { opt_atom($_) } @{$atoms} ];
}

sub opt_atom {
   my $atom = shift;
   my ($name, $args, $pos) = @{$atom};
   given ($name) {
      when ('Oper')  { opt_first_args($atom)  }
      when ('Call')  { opt_first_args($atom)  }
      when ('Ocall') { opt_first_args($atom)  }
      when ('Onew')  { opt_first_args($atom)  }
      when ('Hash')  { opt_hash($args, $pos)  }
      when ('given') { opt_given($args, $pos) }
      when ('case')  { opt_case($args, $pos)  }
      when ('if')    { opt_ifelse($args, $pos)}
      when ('for')   { opt_for($args, $pos)   }
      when ('while') { opt_while($args, $pos) }
      when ('func')  { opt_func($args, $pos)  }
      when ('def')   { opt_def($args, $pos)   }
      when ('fn')    { opt_args($atom) }
      when ('set')   { opt_args($atom) }
      when ('const') { opt_args($atom) }
      when ('my')    { opt_args($atom) }
      when ('return'){ opt_args($atom) }
      when ('Array') { opt_args($atom) }
      when ('ns')    { return $atom }
      when ('class') { return $atom }
      when ('end')   { return $atom }
      when ('use')   { return $atom }
      when ('Aindex'){ return $atom }
      when ('Hkey')  { return $atom }
      when ('Arange'){ return $atom }
      when ('Range') { return $atom }
      when ('Sym')   { return $atom }
      when ('Str')   { return $atom }
      when ('Int')   { return $atom }
      when ('Bool')  { return $atom }
      when ('List')  { return $atom }
      when ('Ns')    { return $atom }
      default {
         say to_json(clean_ast($atom));
         my $line = $pos->[2];
         error("line: $line unknown atom |$name| to opt!");
      }
   }
}

sub opt_first_args {
   my $atom = shift;
   my ($name, $args, $pos) = @{$atom};
   $args->[1] = opt_atoms($args->[1]);
   return [$name, $args, $pos];
}
   
sub opt_args {
   my $atom = shift;
   my ($name, $args, $pos) = @{$atom};
   my $opt_args = opt_atoms($args);
   return [$name, $opt_args, $pos];
}

sub opt_hash {
   my ($pairs, $pos) = @_;
   my $opt_pairs = [];
   for my $pair (@{$pairs}) {
      my ($key, $value, $pos) = @{$pair};
      my $opt_value = opt_atom($value);
      push @{$opt_pairs}, [$key, $opt_value, $pos];
   }
   return ['Hash', $opt_pairs, $pos];
}

sub opt_given {
   my ($args, $pos) = @_;
   my $sym = $args->[0];
   my $flag = 0;
   my $opt_exprs = [];
   for my $atom (@{rest($args)}) {
      if ($flag == -1) {
         error("line: $pos->[1] else branch not end!");
      }
      my ($name, $expr, $pos) = @{$atom};
      given ($name) {
         when ('if') {
            push @{$opt_exprs}, opt_when($expr, $pos);
            $flag = 1;
         }
         when ('else') {
            if ($flag == 1) {
               push @{$opt_exprs}, opt_then($expr, $pos);
               $flag = -1
            } else {
               my $line = $pos->[1];
               error("line: $line less if branch!");
            }
         }
         default {
            my $line = $pos->[1];
            error("line: $line not if/else branch!");
         }
      }
   }
   my $opt_pos = $opt_exprs->[0][2];
   $opt_exprs = ['exprs', $opt_exprs, $opt_pos];
   return ['given', [$sym, $opt_exprs], $pos];
}

sub opt_when {
   my ($args, $pos) = @_;
   my $exprs = opt_cond_exprs($args, $pos);
   return ['when', $exprs, $pos]
}

sub opt_then {
   my ($args, $pos) = @_;
   my $exprs = opt_exprs($args, $pos);
   return ['then', [$exprs], $pos]
}

sub opt_cond_exprs {
   my ($args, $pos) = @_;
   my $exprs = opt_atoms($args);
   my $cond = $exprs->[0];
   my $exprs = rest($exprs);
   return [$cond, ['exprs', $exprs, $pos]];
}

sub opt_exprs {
   my ($args, $pos) = @_;
   my $opt_args = opt_atoms($args);
   return ['exprs', $opt_args, $pos];
}

sub opt_case {
   my ($args, $pos) = @_;
   my $flag = 0;
   my $opt_exprs = [];
   for my $atom (@{$args}) {
      my ($name, $exprs, $pos) = @{$atom};
      if ($flag == -1) {
         my $line = $pos->[1];
         error("line: $line else branch not end!");
      }
      if ($name eq 'if') {
         if ($flag == 0) {
            push @{$opt_exprs}, opt_if($exprs, $pos);
            $flag = 1;
         } elsif ($flag == 1) {
            push @{$opt_exprs}, opt_elif($exprs, $pos);
         }
      }
      elsif ($name eq 'else') {
         if ($flag == 1) {
            push @{$opt_exprs}, opt_else($exprs, $pos);
            $flag = -1;
         } else { 
            my $line = $pos->[1];
            error("line: $line less if expr!") }
      } else {
         my $line = $pos->[1];
         error("line: $line not if/else branch!");
      }
   }
   return ['case', $opt_exprs, $pos];
}

sub opt_if {
   my ($args, $pos) = @_;
   my $exprs = opt_cond_exprs($args, $pos);
   return ['if', $exprs, $pos];
}

sub opt_elif {
   my ($args, $pos) = @_;
   my $exprs = opt_cond_exprs($args, $pos);
   return ['elif', $exprs, $pos];
}

sub opt_else {
   my ($args, $pos) = @_;
   my $exprs = opt_exprs($args, $pos);
   return ['else', [$exprs], $pos]
}

sub opt_ifelse {
   my ($args, $pos) = @_;
   my $cond_atom  = $args->[0];
   my $if_exprs   = [];
   my $else_exprs = [];
   my $flag       = 0;
   for my $atom (@{rest($args)}) {
      if (is_atom_else($atom)) { $flag++; next }
      if ($flag == 0) {
         push @{$if_exprs}, opt_atom($atom);
      } else { 
         push @{$else_exprs}, opt_atom($atom);
      }
   }
   my $if_pos = $if_exprs->[0][2];
   $if_exprs = ['exprs', $if_exprs, $if_pos];
   my $cond_expr = opt_atom($cond_atom);
   if ($flag == 0) {
      my $when_exprs = [$cond_expr, $if_exprs];
      return ['if', $when_exprs, $pos]
   }
   my $else_pos = $else_exprs->[0][2];
   $else_exprs = ['exprs', $else_exprs, $else_pos];
   $if_exprs = [$cond_expr, $if_exprs, $else_exprs];
   return ['ifelse', $if_exprs, $pos]
}

sub opt_for {
   my ($args, $pos) = @_;
   my $iter_args = subarray($args, 0, 2);
   my $iter_expr = opt_iter($iter_args);
   my $for_args = subarray($args, 3);
   my $for_exprs = opt_atoms($for_args);
   my $for_pos = $for_exprs->[0][2];
   $for_exprs = ['exprs', $for_exprs, $for_pos];
   return ['for', [@{$iter_expr}, $for_exprs], $pos];
}

sub opt_iter {
   my $args = shift;
   my $loop_sym = $args->[0];
   my $iter_atom = $args->[-1];
   my $iter_expr = opt_atom($iter_atom);
   if (is_atom_sym($loop_sym)) {
      return [$loop_sym, $iter_expr];
   } else {
      my $line = $loop_sym->[2][1];
      error("line: $line should is sym!");
   }
}

sub opt_while {
   my ($args, $pos) = @_;
   my $cond_atom = $args->[0];
   my $cond_expr = opt_atom($cond_atom);
   my $while_exprs = opt_atoms(rest($args));
   my $while_pos = $while_exprs->[0][2];
   $while_exprs = ['exprs', $while_exprs, $while_pos];
   return ['while', [$cond_expr, $while_exprs], $pos];
}

sub opt_func {
   my ($args, $pos) = @_;
   my $name_args = $args->[0];
   my $func_exprs = opt_atoms(rest($args));
   unshift @{$func_exprs}, $name_args;
   return ['func', $func_exprs, $pos];
}

sub opt_def {
   my ($args, $pos) = @_;
   my $name_args = $args->[0];
   my $func_exprs = opt_atoms(rest($args));
   unshift @{$func_exprs}, $name_args;
   return ['def', $func_exprs, $pos];
}

1;
