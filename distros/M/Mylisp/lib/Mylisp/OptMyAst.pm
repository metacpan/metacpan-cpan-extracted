package Mylisp::OptMyAst;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(OptMyAst);

use Mylisp::Builtin;
use Mylisp::Estr;

sub OptMyAst {
  my $ast = shift;
  if (is_atom($ast)) {
    return estr(opt_my_atom($ast))
  }
  return opt_my_atoms($ast)
}

sub opt_my_atoms {
  my $atoms = shift;
  return estr_strs([ map { opt_my_atom($_) } @{atoms($atoms)} ])
}

sub opt_my_atom {
  my $atom = shift;
  my ($name,$rest) = match($atom);
  given ($name) {
    when ('Expr') {
      return opt_my_expr($rest)
    }
    when ('Ocall') {
      return opt_my_ocall($rest)
    }
    when ('Array') {
      return opt_my_values($name,$rest)
    }
    when ('Hash') {
      return opt_my_values($name,$rest)
    }
    when ('Pair') {
      return opt_my_pair($rest)
    }
    when ('Aindex') {
      return opt_my_values($name,$rest)
    }
    when ('Arange') {
      return opt_my_values($name,$rest)
    }
    when ('String') {
      return opt_my_string($rest)
    }
    when ('Str') {
      return opt_my_str($rest)
    }
    when ('Lstr') {
      return opt_my_lstr($rest)
    }
    when ('Kstr') {
      return opt_my_kstr($rest)
    }
    when ('Sub') {
      return opt_my_sym($rest)
    }
    when ('Var') {
      return opt_my_sym($rest)
    }
    when ('Scalar') {
      return opt_my_sym($rest)
    }
    when ('Oper') {
      return opt_my_sym($rest)
    }
    default {
      return $atom
    }
  }
}

sub opt_my_expr {
  my $value = shift;
  my ($expr,$off) = flat($value);
  if (is_oper_expr($expr)) {
    return opt_my_infix_op_expr($expr,$off)
  }
  my ($first,$atoms) = match($expr);
  my ($type,$name) = flat($first);
  my $args = opt_my_atoms($atoms);
  if ($type eq 'Oper') {
    return estr($name,$args,$off)
  }
  return opt_my_sub($name,$args,$off)
}

sub is_oper_expr {
  my $expr = shift;
  my $atoms = atoms($expr);
  if (len($atoms) == 3) {
    my $op_atom = $atoms->[1];
    return is_atom_name($op_atom,'Oper')
  }
  return 0
}

sub opt_my_infix_op_expr {
  my ($expr,$off) = @_;
  my $atoms = atoms($expr);
  my $name = value($atoms->[1]);
  my $args = estr($atoms->[0],$atoms->[2]);
  $args = opt_my_atoms($args);
  return estr($name,$args,$off)
}

sub opt_my_sub {
  my ($name,$args,$off) = @_;
  given ($name) {
    when ('struct') {
      return opt_my_struct($args,$off)
    }
    when ('package') {
      return opt_my_package($args,$off)
    }
    when ('use') {
      return opt_my_use($args,$off)
    }
    when ('func') {
      return opt_my_func($args,$off)
    }
    when ('for') {
      return opt_my_for($args,$off)
    }
    default {
      return estr($name,$args,$off)
    }
  }
}

sub opt_my_struct {
  my ($args,$off) = @_;
  my ($type,$hash) = flat($args);
  my $name = value($type);
  if (is_atom_name($hash,'Hash')) {
    my $value = value($hash);
    my $fields = [ map { opt_my_field($_) } @{atoms($value)} ];
    my $struct = estr($name,estr_strs($fields),$off);
    return estr('struct',$struct,$off)
  }
}

sub opt_my_field {
  my $pair = shift;
  my ($key,$rest) = match($pair);
  my ($value,$off) = flat($rest);
  if (is_sym($value)) {
    my $type = value($value);
    return estr($key,$type,$off)
  }
}

sub opt_my_package {
  my ($args,$off) = @_;
  my $ns = value(first(atoms($args)));
  return estr('package',$ns,$off)
}

sub opt_my_use {
  my ($args,$off) = @_;
  my $ns = value(first(atoms($args)));
  return estr('use',$ns,$off)
}

sub opt_my_func {
  my ($args,$off) = @_;
  my $call_exprs = opt_my_call($args);
  return estr('func',$call_exprs,$off)
}

sub opt_my_call {
  my $args = shift;
  my ($name_args,$exprs) = match($args);
  my $opt_args = opt_my_func_args($name_args);
  my $return = first(atoms($exprs));
  if ('->' ne name($return)) {
    my $expr = estr('->',estr(estr('Sym','Nil')));
    $exprs = eunshift($expr,$exprs);
  }
  my $func_exprs = eunshift($opt_args,$exprs);
  return $func_exprs
}

sub opt_my_func_args {
  my $name_args = shift;
  my ($name,$args) = flat($name_args);
  my $opt_args = [ map { opt_my_func_arg($_) } @{atoms($args)} ];
  my $off = off($name_args);
  return estr($name,estr_strs($opt_args),$off)
}

sub opt_my_func_arg {
  my $arg = shift;
  my $value = value($arg);
  my $off = off($arg);
  if (is_arg($arg)) {
    my $names = estr_strs(asplit(':',$value));
    my ($name,$type) = flat($names);
    return estr($name,$type,$off)
  }
  return estr($value,'Str',$off)
}

sub is_arg {
  my $atom = shift;
  return is_atom_name($atom,'Arg')
}

sub opt_my_for {
  my ($args,$off) = @_;
  my ($iter_expr,$rest) = match($args);
  my $iter_atom = opt_my_iter($iter_expr);
  my $exprs = eunshift($iter_atom,$rest);
  return estr('for',$exprs,$off)
}

sub opt_my_iter {
  my $expr = shift;
  my $args = value($expr);
  my ($loop_sym,$iter_atom) = flat($args);
  my $loop = value($loop_sym);
  my $off = off($expr);
  return estr($loop,$iter_atom,$off)
}

sub opt_my_ocall_value {
  my $value = shift;
  my ($sym,$call) = flat($value);
  my $sym_name = value($sym);
  my $call_name = value($call);
  return estr($sym_name,$call_name)
}

sub opt_my_ocall {
  my $rest = shift;
  my ($value,$off) = flat($rest);
  my $opt_value = opt_my_ocall_value($value);
  return estr(':ocall',$opt_value,$off)
}

sub opt_my_pair {
  my $rest = shift;
  my ($args,$off) = flat($rest);
  my $atoms = opt_my_atoms($args);
  my ($key,$value) = flat($atoms);
  return estr(value($key),$value,$off)
}

sub opt_my_values {
  my ($name,$value) = @_;
  my ($args,$off) = flat($value);
  my $atoms = opt_my_atoms($args);
  return estr($name,$atoms,$off)
}

sub opt_my_string {
  my $value = shift;
  my ($string,$off) = flat($value);
  my $chars = [];
  my $strs = [];
  my $mode = 0;
  my $str = substr($string, 1,-1);
  for my $char (@{to_chars($str)}) {
    if ($mode == 0) {
      if ($char eq '$') {
        $mode = 1;
        apush($chars,$char);
      }
      elsif ($char eq Ep) {
        $mode = 3;
        apush($chars,$char);
      }
      else {
        $mode = 2;
        apush($chars,$char);
      }
    }
    elsif ($mode == 1) {
      if (is_name($char)) {
        apush($chars,$char);
      }
      else {
        apush($strs,to_str($chars));
        $chars = [];
        apush($chars,$char);
        if ($char eq '$') {
          $mode = 1;
        }
        elsif ($char eq Ep) {
          $mode = 3;
        }
        else {
          $mode = 2;
        }
      }
    }
    elsif ($mode == 2) {
      if ($char eq '$') {
        apush($strs,to_str($chars));
        $chars = [];
        $mode = 1;
        apush($chars,$char);
      }
      elsif ($char eq Ep) {
        $mode = 3;
        apush($chars,$char);
      }
      else {
        apush($chars,$char);
      }
    }
    else {
      $mode = 2;
      apush($chars,$char);
    }
  }
  apush($strs,to_str($chars));
  return estr('String',estr_strs($strs),$off)
}

sub is_name {
  my $char = shift;
  if (is_alpha($char)) {
    return 1
  }
  if ($char eq '-') {
    return 1
  }
  return 0
}

sub opt_my_str {
  my $value = shift;
  my ($str,$off) = flat($value);
  $str = substr($str, 1,-1);
  return estr('Str',$str,$off)
}

sub opt_my_lstr {
  my $value = shift;
  my ($lstr,$off) = flat($value);
  my $str = substr($lstr, 3,-3);
  return estr('Lstr',$str,$off)
}

sub opt_my_kstr {
  my $value = shift;
  my ($kstr,$off) = flat($value);
  my $str = rest_str($kstr);
  return estr('Str',$str,$off)
}

sub opt_my_sym {
  my $value = shift;
  my ($name,$off) = flat($value);
  given ($name) {
    when ('false') {
      return estr('Bool',$name,$off)
    }
    when ('true') {
      return estr('Bool',$name,$off)
    }
    default {
      return estr('Sym',$name,$off)
    }
  }
}
1;
