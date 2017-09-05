# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::OptSppAst;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(opt_spp_ast);

use 5.012;
no warnings "experimental";
use Spp::Builtin;
use Spp::IsChar;
use Spp::IsAtom;

sub opt_spp_ast {
   my $ast   = shift;
   my $atoms = [];

   # when single spec, data structure is same with multi
   if (is_atom($ast)) {
      my ($name, $spec) = @{$ast};
      if ($name eq 'Spec') {
         return [opt_spp_spec($spec)];
      }
   }
   for my $atom (@{$ast}) {

      # say to_json($atom);
      my ($name, $spec) = @{$atom};
      if ($name eq 'Spec') {
         push @{$atoms}, opt_spp_spec($spec);
      }
   }
   return $atoms;
}

sub opt_spp_spec {
   my $atoms = shift;
   my $token = $atoms->[0];
   die("spec name not token") if !is_token($token);
   my $name      = $token->[1];
   my $rules     = rest($atoms);
   my $opt_rules = opt_spp_rules($rules);
   return [$name, $opt_rules];
}

sub opt_spp_rules {
   my $rules     = shift;
   my $opt_rules = opt_spp_atoms($rules);
   if (len($opt_rules) == 1) {
      return $opt_rules->[0];
   }
   return ['Rules', $opt_rules];
}

sub opt_spp_atoms {
   my $atoms = shift;
   my $opt_atoms = [map { opt_spp_atom($_) } @{$atoms}];
   $opt_atoms = gather_spp_tillnot($opt_atoms);
   $opt_atoms = gather_spp_look($opt_atoms);
   $opt_atoms = gather_spp_rept($opt_atoms);
   return $opt_atoms;
}

sub opt_spp_atom {
   my $atom = shift;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Group')   { return opt_spp_group($value) }
      when ('Branch')  { return opt_spp_branch($value) }
      when ('Lbranch') { return opt_spp_lbranch($value) }
      when ('Cclass')  { return opt_spp_cclass($value) }
      when ('Char')    { return opt_spp_char($value) }
      when ('Str')     { return opt_spp_str($value) }
      when ('String')  { return opt_spp_str($value) }
      when ('Keyword') { return opt_spp_keyword($value) }
      when ('Point')   { return opt_spp_point($value) }
      when ('Chclass') { return opt_spp_chclass($value) }
      when ('Look')    { return opt_spp_look($value) }
      when ('Token')   { return opt_spp_token($value) }
      when ('Expr')    { return opt_spp_expr($value) }
      when ('Sym')     { return opt_spp_sym($value) }
      when ('Array')   { return opt_spp_array($value) }
      when (['Assert', 'Any', 'Till', 'Not', 'Int']) {
         return $atom
      }
      default { die "unknown Spp atom to opt: |$name|" }
   }
}

sub opt_spp_point {
   my $point = shift;
   return ['Char', chr(hex($point))];
}

sub opt_spp_group {
   my $atoms     = shift;
   my $opt_atoms = opt_spp_atoms($atoms);
   if (len($opt_atoms) == 1) {
      return $opt_atoms->[0];
   }
   return ['Group', $opt_atoms];
}

sub opt_spp_branch {
   my $atoms     = shift;
   my $opt_atoms = opt_spp_atoms($atoms);
   return $opt_atoms->[0] if len($opt_atoms) == 1;
   return ['Branch', $opt_atoms];
}

sub opt_spp_lbranch {
   my $atoms     = shift;
   my $opt_atoms = opt_spp_atoms($atoms);
   return $opt_atoms->[0] if len($opt_atoms) == 1;
   return ['Lbranch', $opt_atoms];
}

sub opt_spp_keyword {
   my $keyword = shift;
   my $str     = rest($keyword);
   return ['Char', $str] if len($str) == 1;
   return ['Str', $str];
}

sub opt_spp_cclass {
   my $cclass = shift;
   return ['Cclass', tail($cclass)];
}

sub opt_spp_char {
   my $char = shift;
   return ['Char', opt_spp_escape_char($char)];
}

sub opt_spp_escape_char {
   my $str  = shift;
   my $char = tail($str);
   given ($char) {
      when ('b') { return ' ' }
      when ('f') { return "\f" }
      when ('n') { return "\n" }
      when ('r') { return "\r" }
      when ('t') { return "\t" }
      default    { return $char }
   }
}

sub opt_spp_chclass {
   my $nodes = shift;
   my $atoms = [];
   my $flip  = 0;
   for my $node (@{$nodes}) {
      my ($name, $value) = @{$node};
      if ($name eq 'Flip') { $flip = 1; }
      else {
         my $atom = opt_spp_catom($name, $value);
         push @{$atoms}, $atom;
      }
   }
   if ($flip == 0) { return ['Chclass', $atoms]; }
   return ['Nchclass', $atoms];
}

sub opt_spp_catom {
   my ($name, $value) = @_;
   given ($name) {
      when ('Cclass') { return opt_spp_cclass($value) }
      when ('Range')  { return opt_spp_range($value) }
      when ('Char')   { return opt_spp_char($value) }
      when ('Cchar')  { return ['Char', $value] }
      default         { die("unknown cclass atom $name") }
   }
}

sub opt_spp_range {
   my $range = shift;
   return ['Range', [split('-', $range)]];
}

sub opt_spp_look {
   my $atoms = shift;
   my $rept  = $atoms->[0][1];
   return ['_rept', $rept] if len($atoms) == 1;
   return ['_look', $rept];
}

sub gather_spp_tillnot {
   my $atoms     = shift;
   my @opt_atoms = ();
   my $flag      = 0;
   my $cache     = '';
   for my $atom (@{$atoms}) {
      if ($flag == 0) {
         if (is_tillnot($atom)) {
            $flag  = 1;
            $cache = $atom;
         }
         else {
            push @opt_atoms, $atom;
         }
      }
      else {
         if (!is_tillnot($atom)) {
            my $name = $cache->[0];
            $cache = [$name, $atom];
            push @opt_atoms, $cache;
            $flag = 0;
         }
         else {
            die('Till/Not duplicate');
         }
      }
   }
   if ($flag > 0) { die("Till/Not without token!") }
   return [@opt_atoms];
}

sub gather_spp_look {
   my $atoms     = shift;
   my @opt_atoms = ();
   my $flag      = 0;
   my $cache     = '';
   my $look      = '';
   for my $atom (@{$atoms}) {
      if ($flag == 0) {
         if (is_look($atom)) {
            die("Look token less prefix atom: $atom");
         }
         else {
            $cache = $atom;
            $flag  = 1;
         }
      }
      elsif ($flag == 1) {
         if (is_look($atom)) {
            $look = $atom->[1];
            $flag = 2;
         }
         else {
            push @opt_atoms, $cache;
            $cache = $atom;
         }
      }
      else {
         if (!is_look($atom)) {
            $cache = ['Look', [$look, $cache, $atom]];
            push @opt_atoms, $cache;
            $flag = 0;
         }
         else {
            die("Look token repeat");
         }
      }
   }
   if ($flag > 1) { die('Look without atom!') }
   push @opt_atoms, $cache if $flag == 1;
   return [@opt_atoms];
}

sub gather_spp_rept {
   my $atoms = shift;
   my @opt_atoms;
   my $flag  = 0;
   my $cache = '';
   for my $atom (@{$atoms}) {
      if ($flag == 0) {
         if (is_rept($atom)) {
            die("rept without token");
         }
         else {
            $cache = $atom;
            $flag  = 1;
         }
      }
      else {
         if (is_rept($atom)) {
            my $rept = $atom->[1];
            push @opt_atoms, ['Rept', [$rept, $cache]];
            $flag = 0;
         }
         else {
            push @opt_atoms, $cache;
            $cache = $atom;
         }
      }
   }
   if ($flag == 1) { push @opt_atoms, $cache; }
   return [@opt_atoms];
}

sub opt_spp_token {
   my $name = shift;
   my $char = first($name);
   return ['Ntoken', $name] if is_upper($char);
   return ['Ctoken', $name] if is_lower($char);
   return ['Rtoken', $name] if $char eq '_';
   die("Unknown token: <$name> to Opt");
}

sub opt_spp_expr {
   my $atoms     = shift;
   my $opt_atoms = [map { opt_spp_atom($_) } @{$atoms}];
   my $action    = $opt_atoms->[0];
   if (is_sym($action)) {
      $opt_atoms->[0] = $action->[1];
      return ['Expr', $opt_atoms];
   }
   die("Expr not action: {$action->[1]}");
}

sub opt_spp_sym {
   my $name = shift;
   return ['false'] if $name eq 'false';
   return ['true']  if $name eq 'true';
   return ['Sym', $name];
}

sub opt_spp_array {
   my $atoms = shift;
   return ['Array', []] if is_perl_str($atoms);
   my @opt_atoms = map { opt_spp_atom($_) } @{$atoms};
   return ['Array', [@opt_atoms]];
}

sub opt_spp_str {
   my $atoms     = shift;
   my $opt_atoms = [];
   for my $atom (@{$atoms}) {
      my ($name, $value) = @{$atom};
      given ($name) {
         when ('Schars') { push @{$opt_atoms}, $value }
         when ('Chars')  { push @{$opt_atoms}, $value }
         when ('Char') {
            my $char = opt_spp_escape_char($value);
            push @{$opt_atoms}, $char;
         }
         default { die("unknown string atom: <$name>") }
      }
   }
   my $str = join('', @{$opt_atoms});
   return ['Char', $str] if len($str) == 1;
   return ['Str', join('', @{$opt_atoms})];
}

1;
