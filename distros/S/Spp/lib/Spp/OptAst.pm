package Spp::OptAst;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(opt_spp_ast map_opt_spp_atom opt_spp_atom opt_spp_spec opt_spp_rules opt_spp_group opt_spp_branch opt_spp_atoms opt_spp_kstr opt_spp_cclass opt_spp_char opt_spp_escape_char opt_spp_chclass opt_spp_catom opt_spp_cchar opt_spp_range opt_spp_look gather_spp_tillnot gather_spp_look gather_spp_rept opt_spp_token opt_spp_str opt_spp_expr opt_spp_array);

use Spp::Builtin;
use Spp::Tools;

sub opt_spp_ast {
  my $ast = shift;
  if (is_atom($ast)) { return cons(opt_spp_atom($ast)) }
  return map_opt_spp_atom($ast);
}

sub map_opt_spp_atom {
  my $atoms = shift;
  return estr(
    [map { opt_spp_atom($_) } @{ atoms($atoms) }]);
}

sub opt_spp_atom {
  my $atom = shift;
  my ($name, $value) = flat($atom);
  given ($name) {
    when ('Spec')    { return opt_spp_spec($value) }
    when ('Group')   { return opt_spp_group($value) }
    when ('Branch')  { return opt_spp_branch($value) }
    when ('Cclass')  { return opt_spp_cclass($value) }
    when ('Char')    { return opt_spp_char($value) }
    when ('Str')     { return opt_spp_str($value) }
    when ('String')  { return opt_spp_str($value) }
    when ('Kstr')    { return opt_spp_kstr($value) }
    when ('Chclass') { return opt_spp_chclass($value) }
    when ('Look')    { return opt_spp_look($value) }
    when ('Token')   { return opt_spp_token($value) }
    when ('Expr')    { return opt_spp_expr($value) }
    when ('Array')   { return opt_spp_array($value) }
    default { return cons($name, $value) }
  }
}

sub opt_spp_spec {
  my $atoms = shift;
  my ($token, $rules) = match($atoms);
  my $name      = value($token);
  my $opt_rules = opt_spp_rules($rules);
  return cons($name, $opt_rules);
}

sub opt_spp_rules {
  my $atoms     = shift;
  my $opt_atoms = opt_spp_atoms($atoms);
  if (elen($opt_atoms) == 1) { return name($opt_atoms) }
  return cons('Rules', $opt_atoms);
}

sub opt_spp_group {
  my $atoms     = shift;
  my $opt_atoms = opt_spp_atoms($atoms);
  if (elen($opt_atoms) == 1) { return name($opt_atoms) }
  return cons('Group', $opt_atoms);
}

sub opt_spp_branch {
  my $atoms     = shift;
  my $opt_atoms = opt_spp_atoms($atoms);
  if (elen($opt_atoms) == 1) { return name($opt_atoms) }
  return cons('Branch', $opt_atoms);
}

sub opt_spp_atoms {
  my $atoms = shift;
  return gather_spp_rept(
    gather_spp_look(
      gather_spp_tillnot(map_opt_spp_atom($atoms))
    )
  );
}

sub opt_spp_kstr {
  my $kstr = shift;
  my $str  = rest_str($kstr);
  if (len($str) == 1) { return cons('Char', $str) }
  return cons('Str', $str);
}

sub opt_spp_cclass {
  my $cclass = shift;
  return cons('Cclass', last_char($cclass));
}

sub opt_spp_char {
  my $char = shift;
  return cons('Char', opt_spp_escape_char($char));
}

sub opt_spp_escape_char {
  my $str  = shift;
  my $char = last_char($str);
  given ($char) {
    when ('n') { return "\n" }
    when ('r') { return "\r" }
    when ('t') { return "\t" }
    when ('s') { return 's' }
    default    { return $char }
  }
}

sub opt_spp_chclass {
  my $nodes = shift;
  my $atoms = [];
  my $flip  = 0;
  for my $node (@{ atoms($nodes) }) {
    my ($name, $value) = flat($node);
    if ($name eq 'Flip') { $flip = 1 }
    else {
      my $atom = opt_spp_catom($name, $value);
      push @{$atoms}, $atom;
    }
  }
  if ($flip == 0) { return cons('Chclass', estr($atoms)) }
  return cons('Nclass', estr($atoms));
}

sub opt_spp_catom {
  my ($name, $value) = @_;
  given ($name) {
    when ('Cclass') { return opt_spp_cclass($value) }
    when ('Range')  { return opt_spp_range($value) }
    when ('Char')   { return opt_spp_cchar($value) }
    default { return cons('Cchar', $value) }
  }
}

sub opt_spp_cchar {
  my $char = shift;
  return cons('Cchar', opt_spp_escape_char($char));
}

sub opt_spp_range {
  my $atom = shift;
  return cons('Range', estr([split '-', $atom]));
}

sub opt_spp_look {
  my $estr  = shift;
  my $atoms = atoms($estr);
  my $rept  = $atoms->[0];
  my $char  = value($rept);
  if (len($atoms) == 1) { return cons('rept', $char) }
  return cons('look', $char);
}

sub gather_spp_tillnot {
  my $atoms     = shift;
  my $opt_atoms = [];
  my $flag      = 0;
  my $cache     = '';
  for my $atom (@{ atoms($atoms) }) {
    if ($flag == 0) {
      if (is_tillnot($atom)) { $flag = 1; $cache = $atom }
      else                   { push @{$opt_atoms}, $atom; }
    }
    else {
      if (not(is_tillnot($atom))) {
        my $name = name($cache);
        $cache = cons($name, $atom);
        push @{$opt_atoms}, $cache;
        $flag = 0;
      }
    }
  }
  if ($flag > 0) { error("Till/Not without token!") }
  return estr($opt_atoms);
}

sub gather_spp_look {
  my $atoms     = shift;
  my $opt_atoms = [];
  my $flag      = 0;
  my $cache     = '';
  my $look      = '';
  for my $atom (@{ atoms($atoms) }) {
    if ($flag == 0) {
      if (not(is_look($atom))) { $cache = $atom; $flag = 1 }
    }
    elsif ($flag == 1) {
      if (is_look($atom)) {
        $look = value($atom);
        $flag = 2;
      }
      else { push @{$opt_atoms}, $cache; $cache = $atom }
    }
    else {
      if (not(is_look($atom))) {
        $cache = cons($look, cons($cache, $atom));
        $cache = cons('Look', $cache);
        push @{$opt_atoms}, $cache;
        $flag = 0;
      }
    }
  }
  if ($flag == 1) { push @{$opt_atoms}, $cache; }
  return estr($opt_atoms);
}

sub gather_spp_rept {
  my $atoms     = shift;
  my $opt_atoms = [];
  my $flag      = 0;
  my $cache     = '';
  for my $atom (@{ atoms($atoms) }) {
    if ($flag == 0) {
      if (not(is_rept($atom))) { $cache = $atom; $flag = 1 }
    }
    else {
      if (is_rept($atom)) {
        my $rept = value($atom);
        $cache = cons('Rept', cons($rept, $cache));
        push @{$opt_atoms}, $cache;
        $flag = 0;
      }
      else { push @{$opt_atoms}, $cache; $cache = $atom }
    }
  }
  if ($flag == 1) { push @{$opt_atoms}, $cache; }
  return estr($opt_atoms);
}

sub opt_spp_token {
  my $name = shift;
  my $char = first_char($name);
  if (is_upper($char)) { return cons('Ntoken', $name) }
  if (is_lower($char)) { return cons('Ctoken', $name) }
  return cons('Rtoken', $name);
}

sub opt_spp_str {
  my $atoms     = shift;
  my $opt_atoms = [];
  for my $atom (@{ atoms($atoms) }) {
    my ($name, $value) = flat($atom);
    given ($name) {
      when ('Char') {
        my $char = opt_spp_escape_char($value);
        push @{$opt_atoms}, $char;
      }
      default { push @{$opt_atoms}, $value; }
    }
  }
  my $str = join '', @{$opt_atoms};
  if (len($str) == 1) { return cons('Char', $str) }
  return cons('Str', $str);
}

sub opt_spp_expr {
  my $atoms = shift;
  my ($action, $args) = match($atoms);
  if (is_sub($action)) {
    my $call = value($action);
    if ($call ~~ ['push', 'my']) {
      my $opt_args = map_opt_spp_atom($args);
      my $expr = cons($call, $opt_args);
      return cons('Call', $expr);
    }
    else { error("not implement action: |$call|") }
  }
  my $action_str = from_ejson($action);
  error("Expr not action: $action_str");
}

sub opt_spp_array {
  my $atoms = shift;
  if (is_str($atoms)) { return cons('Array', Blank) }
  my $opt_atoms = map_opt_spp_atom($atoms);
  return cons('Array', $opt_atoms);
}
1;
