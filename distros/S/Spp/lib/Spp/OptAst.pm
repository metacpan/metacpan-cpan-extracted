package Spp::OptAst;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(opt_spp_ast);

use Spp::Builtin;
use Spp::Core;

sub opt_spp_ast {
   my $ast = shift;
   return [ opt_atom($ast) ] if is_atom($ast);
   return map_opt_atom($ast);
}

sub map_opt_atom {
   my $atoms = shift;
   return [ map { opt_atom($_) } @{$atoms} ];
}

sub opt_atom {
   my $atom = shift;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Spec')    { return opt_spec($value)  }
      when ('Group')   { return opt_group($value) }
      when ('Branch')  { return opt_branch($value) }
      when ('Cclass')  { return opt_cclass($value) }
      when ('Char')    { return opt_char($value) }
      when ('Str')     { return opt_str($value) }
      when ('String')  { return opt_str($value) }
      when ('Kstr')    { return opt_kstr($value) }
      when ('Point')   { return opt_point($value) }
      when ('Chclass') { return opt_chclass($value) }
      when ('Look')    { return opt_look($value) }
      when ('Token')   { return opt_token($value) }
      when ('Expr')    { return opt_expr($value) }
      when ('Sym')     { return opt_sym($value) }
      when ('Array')   { return opt_array($value) }
      when ('Assert')  { return $atom }
      when ('Any')     { return $atom }
      when ('Till')    { return $atom }
      when ('Not')     { return $atom }
      when ('Int')     { return $atom }
      default { error("unknown Spp atom to opt: |$name|") }
   }
}

sub opt_spec {
   my $atoms = shift;
   my $token = $atoms->[0];
   my $name  = $token->[1];
   my $rules = rest($atoms);
   return [$name, opt_rules($rules)];
}

sub opt_rules {
   my $rules     = shift;
   my $opt_rules = opt_atoms($rules);
   return $opt_rules->[0] if len($opt_rules) == 1;
   return ['Rules', $opt_rules];
}

sub opt_atoms {
   my $atoms = shift;
   my $opt_atoms = map_opt_atom($atoms);
   $opt_atoms = gather_tillnot($opt_atoms);
   $opt_atoms = gather_look($opt_atoms);
   $opt_atoms = gather_rept($opt_atoms);
   return $opt_atoms;
}

sub opt_point {
   my $point = shift;
   return ['Char', chr(hex($point))];
}

sub opt_group {
   my $atoms     = shift;
   my $opt_atoms = opt_atoms($atoms);
   return $opt_atoms->[0] if len($opt_atoms) == 1;
   return ['Group', $opt_atoms];
}

sub opt_branch {
   my $atoms     = shift;
   my $opt_atoms = opt_atoms($atoms);
   return $opt_atoms->[0] if len($opt_atoms) == 1;
   return ['Branch', $opt_atoms];
}

sub opt_kstr {
   my $kstr = shift;
   my $str  = substr($kstr, 1);
   return ['Char', $str] if len($str) == 1;
   return ['Str', $str];
}

sub opt_cclass {
   my $cclass = shift;
   return ['Cclass', substr($cclass, -1)];
}

sub opt_char {
   my $char = shift;
   return ['Char', opt_escape_char($char)];
}

sub opt_escape_char {
   my $str  = shift;
   my $char = substr($str, -1);
   given ($char) {
      when ('b') { return ' ' }
      when ('f') { return "\f" }
      when ('n') { return "\n" }
      when ('r') { return "\r" }
      when ('t') { return "\t" }
      default    { return $char }
   }
}

sub opt_chclass {
   my $nodes = shift;
   my $atoms = [];
   my $flip  = 0;
   for my $node (@{$nodes}) {
      my ($name, $value) = @{$node};
      if ($name eq 'Flip') { $flip = 1; }
      else {
         my $atom = opt_catom($name, $value);
         push @{$atoms}, $atom;
      }
   }
   if ($flip == 0) { return ['Chclass', $atoms]; }
   return ['Nchclass', $atoms];
}

sub opt_catom {
   my ($name, $value) = @_;
   given ($name) {
      when ('Cclass') { return opt_cclass($value) }
      when ('Range')  { return opt_range($value) }
      when ('Char')   { return opt_char($value) }
      when ('Cchar')  { return ['Char', $value] }
      default         { die("unknown cclass atom $name") }
   }
}

sub opt_range {
   my $range = shift;
   return ['Range', [split('-', $range)]];
}

sub opt_look {
   my $atoms = shift;
   my $rept  = $atoms->[0][1];
   return ['_rept', $rept] if len($atoms) == 1;
   return ['_look', $rept];
}

sub gather_tillnot {
   my $atoms     = shift;
   my @opt_atoms = ();
   my $flag      = 0;
   my $cache     = '';
   for my $atom (@{$atoms}) {
      if ($flag == 0) {
         if (is_atom_tillnot($atom)) {
            $flag  = 1;
            $cache = $atom;
         } else {
            push @opt_atoms, $atom;
         }
      }
      else {
         if (!is_atom_tillnot($atom)) {
            my $name = $cache->[0];
            $cache = [$name, $atom];
            push @opt_atoms, $cache;
            $flag = 0;
         } else {
            die('Till/Not duplicate');
         }
      }
   }
   if ($flag > 0) { die("Till/Not without token!") }
   return [@opt_atoms];
}

sub gather_look {
   my $atoms     = shift;
   my @opt_atoms = ();
   my $flag      = 0;
   my $cache     = '';
   my $look      = '';
   for my $atom (@{$atoms}) {
      if ($flag == 0) {
         if (is_atom_name($atom, '_look')) {
            die("Look token less prefix atom: $atom");
         } else {
            $cache = $atom;
            $flag  = 1;
         }
      } elsif ($flag == 1) {
         if (is_atom_name($atom, '_look')) {
            $look = $atom->[1];
            $flag = 2;
         } else {
            push @opt_atoms, $cache;
            $cache = $atom;
         }
      } else {
         if (!is_atom_name($atom, '_look')) {
            $cache = ['Look', [$look, $cache, $atom]];
            push @opt_atoms, $cache;
            $flag = 0;
         } else {
            die("Look token repeat");
         }
      }
   }
   if ($flag > 1) { die('Look without atom!') }
   push @opt_atoms, $cache if $flag == 1;
   return [@opt_atoms];
}

sub gather_rept {
   my $atoms = shift;
   my @opt_atoms;
   my $flag  = 0;
   my $cache = '';
   for my $atom (@{$atoms}) {
      if ($flag == 0) {
         if (is_atom_name($atom, '_rept')) {
            die("rept without token");
         }
         else {
            $cache = $atom;
            $flag  = 1;
         }
      }
      else {
         if (is_atom_name($atom, '_rept')) {
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

sub opt_token {
   my $name = shift;
   my $char = first($name);
   return ['Ntoken', $name] if is_char_upper($char);
   return ['Ctoken', $name] if is_char_lower($char);
   return ['Rtoken', $name] if $char eq '_';
   die "Unknown token: <$name> to Opt";
}

sub opt_expr {
   my $atoms     = shift;
   my $opt_atoms = map_opt_atom($atoms);
   my $action    = $opt_atoms->[0];
   if (is_atom_sym($action)) {
      $opt_atoms->[0] = $action->[1];
      return ['Expr', $opt_atoms];
   }
   die "Expr not action: {$action->[1]}";
}

sub opt_sym {
   my $name = shift;
   return ['false'] if $name eq 'false';
   return ['true']  if $name eq 'true';
   return ['Sym', $name];
}

sub opt_array {
   my $atoms = shift;
   return ['Array', []] if is_str($atoms);
   my $opt_atoms = map_opt_atom($atoms);
   return ['Array', $opt_atoms];
}

sub opt_str {
   my $atoms     = shift;
   my $opt_atoms = [];
   for my $atom (@{$atoms}) {
      my ($name, $value) = @{$atom};
      given ($name) {
         when ('Schars') { push @{$opt_atoms}, $value }
         when ('Chars')  { push @{$opt_atoms}, $value }
         when ('Char') {
            my $char = opt_escape_char($value);
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
