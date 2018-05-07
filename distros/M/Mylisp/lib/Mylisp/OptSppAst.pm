package Mylisp::OptSppAst;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(OptSppAst);

use Mylisp::Builtin;
use Mylisp::Estr;

sub OptSppAst {
  my $ast = shift;
   if (is_atom($ast)) {
    return estr(opt_spp_atom($ast));
  }
  return map_opt_spp_atom($ast);
}

sub map_opt_spp_atom {
  my $atoms = shift;
   return estr_strs([ map { opt_spp_atom($_) } @{atoms($atoms)} ]);
}

sub opt_spp_atom {
  my $atom = shift;
   my ($name,$value) = flat($atom);
  given ($name) {
    when ('Spec') {
      return opt_spp_spec($value);
    }
    when ('Rule') {
      return opt_spp_spec($value);
    }
    when ('Group') {
      return opt_spp_group($value);
    }
    when ('Branch') {
      return opt_spp_branch($value);
    }
    when ('Cclass') {
      return opt_spp_cclass($value);
    }
    when ('Char') {
      return opt_spp_char($value);
    }
    when ('Str') {
      return opt_spp_str($value);
    }
    when ('String') {
      return opt_spp_str($value);
    }
    when ('Kstr') {
      return opt_spp_kstr($value);
    }
    when ('Chclass') {
      return opt_spp_chclass($value);
    }
    when ('Rept') {
      return opt_spp_rept($value);
    }
    when ('Token') {
      return opt_spp_token($value);
    }
    when ('Expr') {
      return opt_spp_expr($value);
    }
    when ('Array') {
      return opt_spp_array($value);
    }
    when ('Blank') {
      return opt_spp_blank($value);
    }
    when ('Assert') {
      return estr($name,$value);
    }
    when ('Till') {
      return estr($name,$value);
    }
    when ('Any') {
      return estr($name,$value);
    }
    default {
      say "unknown Spp atom: |$name| to Opt";
      return estr($name,$value);
    }
  }
}

sub opt_spp_spec {
  my $atoms = shift;
   my ($token,$rules) = match($atoms);
  my $name = value($token);
  my $opt_rules = opt_spp_rules($rules);
  return estr($name,$opt_rules);
}

sub opt_spp_rules {
  my $atoms = shift;
   my $opt_atoms = opt_spp_atoms($atoms);
  if (elen($opt_atoms) == 1) {
    return substr($opt_atoms, 1,-1);
  }
  return estr('Rules',$opt_atoms);
}

sub opt_spp_group {
  my $atoms = shift;
   my $opt_atoms = opt_spp_atoms($atoms);
  if (elen($opt_atoms) == 1) {
    return substr($opt_atoms, 1,-1);
  }
  return estr('Group',$opt_atoms);
}

sub opt_spp_branch {
  my $atoms = shift;
   my $opt_atoms = opt_spp_atoms($atoms);
  if (elen($opt_atoms) == 1) {
    return substr($opt_atoms, 1,-1);
  }
  return estr('Branch',$opt_atoms);
}

sub opt_spp_atoms {
  my $atoms = shift;
   return gather_spp_rept(gather_spp_till(map_opt_spp_atom($atoms)));
}

sub opt_spp_kstr {
  my $kstr = shift;
   my $str = rest_str($kstr);
  if (len($str) == 1) {
    return estr('Char',$str);
  }
  return estr('Str',$str);
}

sub opt_spp_cclass {
  my $cclass = shift;
   return estr('Cclass',last_char($cclass));
}

sub opt_spp_char {
  my $char = shift;
   return estr('Char',opt_spp_ep($char));
}

sub opt_spp_ep {
  my $str = shift;
   my $char = last_char($str);
  given ($char) {
    when ('n') {
      return "\n";
    }
    when ('r') {
      return "\r";
    }
    when ('t') {
      return "\t";
    }
    default {
      return $char;
    }
  }
}

sub opt_spp_chclass {
  my $nodes = shift;
   my $atoms = [];
  my $flip = 0;
  for my $node (@{atoms($nodes)}) {
    my ($name,$value) = flat($node);
    if ($name eq 'Flip') {
      $flip = 1;
    }
    else {
      my $atom = opt_spp_catom($name,$value);
      apush($atoms,$atom);
    }
  }
  if ($flip == 0) {
    return estr('Chclass',estr_strs($atoms));
  }
  return estr('Nclass',estr_strs($atoms));
}

sub opt_spp_catom {
  my ($name,$value) = @_;
   given ($name) {
    when ('Cclass') {
      return opt_spp_cclass($value);
    }
    when ('Range') {
      return opt_spp_range($value);
    }
    when ('Char') {
      return opt_spp_cchar($value);
    }
    default {
      return estr('Cchar',$value);
    }
  }
}

sub opt_spp_cchar {
  my $char = shift;
   return estr('Cchar',opt_spp_ep($char));
}

sub opt_spp_range {
  my $atom = shift;
   return estr('Range',estr_strs(asplit('-',$atom)));
}

sub opt_spp_rept {
  my $estr = shift;
   return estr('rept',$estr);
}

sub gather_spp_till {
  my $atoms = shift;
   my $opt_atoms = [];
  my $flag = 0;
  for my $atom (@{atoms($atoms)}) {
    if ($flag == 0) {
      if (is_till($atom)) {
        $flag = 1;
      }
      else {
        apush($opt_atoms,$atom);
      }
    }
    else {
      if (not(is_till($atom))) {
        apush($opt_atoms,estr('Till',$atom));
        $flag = 0;
      }
    }
  }
  if ($flag > 0) {
    error("Till without token!");
  }
  return estr_strs($opt_atoms);
}

sub is_till {
  my $atom = shift;
   if (is_atom_name($atom,'Till')) {
    return 1;
  }
  return 0;
}

sub gather_spp_rept {
  my $atoms = shift;
   my $opt_atoms = [];
  my $flag = 0;
  my $cache = '';
  for my $atom (@{atoms($atoms)}) {
    if ($flag == 0) {
      if (not(is_rept($atom))) {
        $cache = $atom;
        $flag = 1;
      }
    }
    else {
      if (is_rept($atom)) {
        my $rept = value($atom);
        $cache = estr('Rept',estr($rept,$cache));
        apush($opt_atoms,$cache);
        $flag = 0;
      }
      else {
        apush($opt_atoms,$cache);
        $cache = $atom;
      }
    }
  }
  if ($flag == 1) {
    apush($opt_atoms,$cache);
  }
  return estr_strs($opt_atoms);
}

sub is_rept {
  my $atom = shift;
   return is_atom_name($atom,'rept');
}

sub opt_spp_token {
  my $name = shift;
   my $char = first_char($name);
  if (is_upper($char)) {
    return estr('Ntoken',$name);
  }
  if (is_lower($char)) {
    return estr('Ctoken',$name);
  }
  return estr('Rtoken',$name);
}

sub opt_spp_str {
  my $string = shift;
   my $chars = [];
  my $mode = 0;
  my $value = substr($string, 1,-1);
  for my $char (@{to_chars($value)}) {
    if ($mode == 0) {
      if ($char eq Ep) {
        $mode = 1;
      }
      else {
        apush($chars,$char);
      }
    }
    else {
      $mode = 0;
      apush($chars,opt_spp_ep($char));
    }
  }
  my $str = to_str($chars);
  if (len($str) == 1) {
    return estr('Char',$str);
  }
  return estr('Str',$str);
}

sub opt_spp_expr {
  my $atoms = shift;
   my ($action,$args) = match($atoms);
  if (is_atom_name($action,'Sub')) {
    my $call = value($action);
    if ($call ~~ ['push','my']) {
      my $opt_args = map_opt_spp_atom($args);
      my $expr = estr($call,$opt_args);
      return estr('Call',$expr);
    }
    else {
      croak("not implement action: |$call|");
    }
  }
  my $action_str = estr_to_json($action);
  croak("Expr not action: $action-str");
  return '';
}

sub opt_spp_array {
  my $atoms = shift;
   if (is_str($atoms)) {
    return estr('Array',Blank);
  }
  my $opt_atoms = map_opt_spp_atom($atoms);
  return estr('Array',$opt_atoms);
}

sub opt_spp_blank {
  my $blank = shift;
   return estr('Blank','b');
}
1;
