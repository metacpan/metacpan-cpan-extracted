package Mylisp::Estr;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_true is_false is_bool is_str is_estr is_atom is_atoms is_blank estr estr_atom estr_strs estr_ints estr_int json_to_estr estr_to_json char_to_json atoms flat match _name name value off elen erest epush eappend eunshift is_atom_name is_sym clean_ast clean_atom);

use Mylisp::Builtin;
sub is_true {
  my $str = shift;
  return $str eq True;
}
sub is_false {
  my $str = shift;
  return $str eq False;
}
sub is_bool {
  my $str = shift;
  if (is_true($str)) {
    return 1;
  }
  if (is_false($str)) {
    return 1;
  }
  return 0;
}
sub is_str {
  my $str = shift;
  my $char = first_char($str);
  return ord($char) > 6;
}
sub is_estr {
  my $str = shift;
  return first_char($str) eq In;
}
sub is_atom {
  my $atom = shift;
  if (first_char($atom) eq In) {
    if (substr($atom, 1, 1) eq Qstr) {
      return 1;
    }
  }
  return 0;
}
sub is_atoms {
  my $atoms = shift;
  if (is_estr($atoms)) {
    for my $atom (@{atoms($atoms)}) {
      if (not(is_atom($atom))) {
        return 0;
      }
    }
    return 1;
  }
  return 1;
}
sub is_blank {
  my $str = shift;
  return $str eq Blank;
}
sub estr {
  my @args = @_;
  my $estr = to_str([ map { estr_atom($_) } @args ]);
  return add(In,$estr,Out);
}
sub estr_atom {
  my $atom = shift;
  if (is_estr($atom)) {
    return $atom;
  }
  if (is_str($atom)) {
    return add(Qstr,$atom);
  }
  croak("|$atom| not estr or str or int!");
  return False;
}
sub estr_strs {
  my $array = shift;
  my $estr = to_str([ map { estr_atom($_) } @{$array} ]);
  return add(In,$estr,Out);
}
sub estr_ints {
  my $ints = shift;
  my $estrs = [];
  for my $int (@{$ints}) {
    apush($estrs,estr_int($int));
  }
  return add(In,to_str($estrs),Out);
}
sub estr_int {
  my $int = shift;
  return add(Qint,int_to_str($int));
}
sub json_to_estr {
  my $json = shift;
  if (is_estr($json)) {
    return $json;
  }
  my $chars = [];
  my $mode = 0;
  for my $ch (@{to_chars($json)}) {
    if ($mode == 0) {
      given ($ch) {
        when ('[') {
          apush($chars,In);
        }
        when (']') {
          apush($chars,Out);
        }
        when ('"') {
          apush($chars,Qstr);
          $mode = 1;
        }
        default {
          if (is_digit($ch)) {
            apush($chars,Qint);
            apush($chars,$ch);
            $mode = 2;
          }
        }
      }
    }
    elsif ($mode == 1) {
      given ($ch) {
        when ('"') {
          $mode = 0;
        }
        when (Ep) {
          $mode = 3;
        }
        default {
          apush($chars,$ch);
        }
      }
    }
    elsif ($mode == 2) {
      if ($ch eq ',') {
        $mode = 0;
      }
      if ($ch eq ']') {
        apush($chars,Out);
        $mode = 0;
      }
      if (is_digit($ch)) {
        apush($chars,$ch);
      }
    }
    else {
      $mode = 1;
      given ($ch) {
        when ('t') {
          apush($chars,"\t");
        }
        when ('r') {
          apush($chars,"\r");
        }
        when ('n') {
          apush($chars,"\n");
        }
        default {
          apush($chars,$ch);
        }
      }
    }
  }
  return to_str($chars);
}
sub estr_to_json {
  my $estr = shift;
  if (is_str($estr)) {
    return $estr;
  }
  my $chars = [];
  my $mode = 0;
  for my $ch (@{to_chars($estr)}) {
    if ($mode == 0) {
      given ($ch) {
        when (In) {
          apush($chars,'[');
        }
        when (Qstr) {
          apush($chars,'"');
          $mode = 1;
        }
        when (Qint) {
          $mode = 2;
        }
        when (Out) {
          apush($chars,']');
          $mode = 3;
        }
      }
    }
    elsif ($mode == 1) {
      given ($ch) {
        when (In) {
          apush($chars,'",[');
          $mode = 0;
        }
        when (Qstr) {
          apush($chars,'","');
        }
        when (Qint) {
          apush($chars,'",');
          $mode = 2;
        }
        when (Out) {
          apush($chars,'"]');
          $mode = 3;
        }
        default {
          apush($chars,char_to_json($ch));
        }
      }
    }
    elsif ($mode == 2) {
      given ($ch) {
        when (In) {
          apush($chars,',[');
          $mode = 0;
        }
        when (Qstr) {
          apush($chars,',"');
          $mode = 1;
        }
        when (Qint) {
          apush($chars,',');
        }
        when (Out) {
          apush($chars,']');
          $mode = 3;
        }
        default {
          apush($chars,$ch);
        }
      }
    }
    else {
      given ($ch) {
        when (In) {
          apush($chars,',[');
          $mode = 0;
        }
        when (Qstr) {
          apush($chars,',"');
          $mode = 1;
        }
        when (Qint) {
          apush($chars,',');
          $mode = 2;
        }
        when (Out) {
          apush($chars,']');
        }
      }
    }
  }
  return to_str($chars);
}
sub char_to_json {
  my $ch = shift;
  given ($ch) {
    when ("\t") {
      return '\t';
    }
    when ("\n") {
      return '\n';
    }
    when ("\r") {
      return '\r';
    }
    when (Ep) {
      return '\\\\';
    }
    when ('"') {
      return '\"';
    }
    default {
      return $ch;
    }
  }
}
sub atoms {
  my $estr = shift;
  my $estrs = [];
  my $chars = [];
  my $depth = 0;
  my $mode = 0;
  for my $ch (@{to_chars($estr)}) {
    if ($depth == 0) {
      if ($ch eq In) {
        $depth++;;
      }
    }
    elsif ($depth == 1) {
      given ($ch) {
        when (In) {
          $depth++;;
          if ($mode) {
            apush($estrs,to_str($chars));
            $chars = [];
          }
          $mode = 1;
          apush($chars,$ch);
        }
        when (Qstr) {
          if ($mode) {
            apush($estrs,to_str($chars));
            $chars = [];
          }
          $mode = 1;
        }
        when (Qint) {
          if ($mode) {
            apush($estrs,to_str($chars));
            $chars = [];
          }
          $mode = 1;
        }
        when (Out) {
          if ($mode) {
            apush($estrs,to_str($chars));
          }
        }
        default {
          if ($mode) {
            apush($chars,$ch);
          }
        }
      }
    }
    else {
      if ($ch eq In) {
        $depth++;;
      }
      if ($ch eq Out) {
        $depth --;
      }
      apush($chars,$ch);
    }
  }
  return $estrs;
}
sub flat {
  my $estr = shift;
  if (is_str($estr)) {
    croak("Str: |$estr| could not flat!");
  }
  my $atoms = atoms($estr);
  if (len($atoms) < 2) {
    croak("flat less two atom");
  }
  return $atoms->[0],$atoms->[1];
}
sub match {
  my $estr = shift;
  my $atoms = atoms($estr);
  if (len($atoms) == 0) {
    error("match with blank");
  }
  if (len($atoms) == 1) {
    return $atoms->[0],Blank;
  }
  return $atoms->[0],estr_strs(rest($atoms));
}
sub _name {
  my $estr = shift;
  my $name = first(atoms($estr));
  if (is_atom($name)) {
    croak("(name ..) with atoms");
  }
  return $name;
}
sub name {
  my $estr = shift;
  my $chars = [];
  my $str = substr($estr, 2);
  for my $char (@{to_chars($str)}) {
    if (ord($char) > 6) {
      apush($chars,$char);
    }
    else {
      return to_str($chars);
    }
  }
}
sub value {
  my $estr = shift;
  my $atoms = atoms($estr);
  return $atoms->[1];
}
sub off {
  my $estr = shift;
  my $atoms = atoms($estr);
  return tail($atoms);
}
sub elen {
  my $estr = shift;
  my $atoms = atoms($estr);
  return len($atoms);
}
sub erest {
  my $estr = shift;
  return estr_strs(rest(atoms($estr)));
}
sub epush {
  my ($estr,$elem) = @_;
  return add(cut($estr),$elem,Out);
}
sub eappend {
  my ($a_one,$a_two) = @_;
  return add(cut($a_one),rest_str($a_two));
}
sub eunshift {
  my ($elem,$array) = @_;
  return add(In,$elem,rest_str($array));
}
sub is_atom_name {
  my ($atom,$name) = @_;
  if (is_atom($atom)) {
    return name($atom) eq $name;
  }
  return 0;
}
sub is_sym {
  my $atom = shift;
  return is_atom_name($atom,'Sym');
}
sub clean_ast {
  my $ast = shift;
  if (is_atom($ast)) {
    return clean_atom($ast);
  }
  my $clean_atoms = [];
  for my $atom (@{atoms($ast)}) {
    apush($clean_atoms,clean_atom($atom));
  }
  return estr_strs($clean_atoms);
}
sub clean_atom {
  my $atom = shift;
  my ($name,$value) = flat($atom);
  if (is_str($value)) {
    return estr($name,$value);
  }
  if (is_blank($value)) {
    return estr($name,$value);
  }
  if (is_atom($value)) {
    return estr($name,clean_atom($value));
  }
  return estr($name,clean_ast($value));
}
1;
