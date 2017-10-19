package Spp::Tools;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(is_type is_atoms to_ejson from_ejson char_to_ejson atoms flat match name value offline elen epush eappend eunshift ejoin is_atom_name is_sym is_rept is_look is_tillnot is_atom_str is_sub is_return ast_to_table get_rept_time clean_ast clean_atom see_ast is_exported);

use Spp::Builtin;

sub is_type {
  my $str = shift;
  return $str ~~ [
    'Str',  'Int',   'Bool',       'Cursor',
    'Lint', 'Array', 'Ints',       'Hash',
    'Str+', 'Int+',  'StrOrArray', 'Str?',
    'Int?', 'Fn',    'Table',      'Map'
  ];
}

sub is_atoms {
  my $atoms = shift;
  if (is_estr($atoms)) {
    for my $atom (@{ atoms($atoms) }) {
      if (not(is_atom($atom))) { return 0 }
    }
    return 1;
  }
  return 1;
}

sub to_ejson {
  my $json = shift;
  if (is_estr($json)) { return $json }
  my $chars = [];
  my $mode  = 0;
  for my $ch (split '', $json) {
    if ($mode == 0) {
      given ($ch) {
        when ('[') { push @{$chars}, In; }
        when (']') { push @{$chars}, Out; }
        when ('"') { push @{$chars}, Qstr; $mode = 1 }
        default {
          if (is_digit($ch)) {
            push @{$chars}, Qint;
            push @{$chars}, $ch;
            $mode = 2;
          }
        }
      }
    }
    elsif ($mode == 1) {
      given ($ch) {
        when ('"')  { $mode = 0 }
        when ("\\") { $mode = 3 }
        default { push @{$chars}, $ch; }
      }
    }
    elsif ($mode == 2) {
      if ($ch eq ',') { $mode = 0 }
      if ($ch eq ']') { push @{$chars}, Out; $mode = 0 }
      if (is_digit($ch)) { push @{$chars}, $ch; }
    }
    else {
      $mode = 1;
      given ($ch) {
        when ('t') { push @{$chars}, "\t"; }
        when ('r') { push @{$chars}, "\r"; }
        when ('n') { push @{$chars}, "\n"; }
        default    { push @{$chars}, $ch; }
      }
    }
  }
  return join '', @{$chars};
}

sub from_ejson {
  my $estr = shift;
  if (is_str($estr)) { return $estr }
  my $chars = [];
  my $mode  = 0;
  for my $ch (split '', $estr) {
    if ($mode == 0) {
      given ($ch) {
        when (In) { push @{$chars}, '['; }
        when (Qstr) { push @{$chars}, '"'; $mode = 1 }
        when (Qint) { $mode = 2 }
        when (Out) { push @{$chars}, ']'; $mode = 3 }
      }
    }
    elsif ($mode == 1) {
      given ($ch) {
        when (In) { push @{$chars}, '",['; $mode = 0 }
        when (Qstr) { push @{$chars}, '","'; }
        when (Qint) { push @{$chars}, '",'; $mode = 2 }
        when (Out)  { push @{$chars}, '"]'; $mode = 3 }
        default     { push @{$chars}, char_to_ejson($ch); }
      }
    }
    elsif ($mode == 2) {
      given ($ch) {
        when (In)   { push @{$chars}, ',['; $mode = 0 }
        when (Qstr) { push @{$chars}, ',"'; $mode = 1 }
        when (Qint) { push @{$chars}, ','; }
        when (Out)  { push @{$chars}, ']';  $mode = 3 }
        default     { push @{$chars}, $ch; }
      }
    }
    else {
      given ($ch) {
        when (In)   { push @{$chars}, ',['; $mode = 0 }
        when (Qstr) { push @{$chars}, ',"'; $mode = 1 }
        when (Qint) { push @{$chars}, ',';  $mode = 2 }
        when (Out)  { push @{$chars}, ']'; }
      }
    }
  }
  return join '', @{$chars};
}

sub char_to_ejson {
  my $ch = shift;
  given ($ch) {
    when ("\t") { return '\t' }
    when ("\n") { return '\n' }
    when ("\r") { return '\r' }
    when ("\\") { return '\\\\' }
    when ('"')  { return '\"' }
    default     { return $ch }
  }
}

sub atoms {
  my $estr  = shift;
  my $estrs = [];
  my $chars = [];
  my $depth = 0;
  my $mode  = 0;
  for my $ch (split '', $estr) {
    if ($depth == 0) {
      if ($ch eq In) { $depth++ }
    }
    elsif ($depth == 1) {
      given ($ch) {
        when (In) {
          $depth++;
          if ($mode) {
            push @{$estrs}, join '', @{$chars};
            $chars = [];
          }
          $mode = 1;
          push @{$chars}, $ch;
        }
        when (Qstr) {
          if ($mode) {
            push @{$estrs}, join '', @{$chars};
            $chars = [];
          }
          $mode = 1
        }
        when (Qint) {
          if ($mode) {
            push @{$estrs}, join '', @{$chars};
            $chars = [];
          }
          $mode = 1
        }
        when (Out) {
          if ($mode) { push @{$estrs}, join '', @{$chars}; }
        }
        default {
          if ($mode) { push @{$chars}, $ch; }
        }
      }
    }
    else {
      if ($ch eq In)  { $depth++ }
      if ($ch eq Out) { $depth-- }
      push @{$chars}, $ch;
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
    say from_ejson($estr);
    croak("flat less two atom");
  }
  return $atoms->[0], $atoms->[1];
}

sub match {
  my $estr  = shift;
  my $atoms = atoms($estr);
  if (len($atoms) == 0) { error("match with blank") }
  if (len($atoms) == 1) { return $atoms->[0], Blank }
  return $atoms->[0], estr(rest($atoms));
}

sub name {
  my $estr  = shift;
  my $atoms = atoms($estr);
  return $atoms->[0];
}

sub value {
  my $estr  = shift;
  my $atoms = atoms($estr);
  return $atoms->[1];
}

sub offline {
  my $estr  = shift;
  my $atoms = atoms($estr);
  return $atoms->[-1];
}

sub elen {
  my $estr  = shift;
  my $atoms = atoms($estr);
  return len($atoms);
}

sub epush {
  my ($array, $elem) = @_;
  return add(Chop($array), $elem, Out);
}

sub eappend {
  my ($a_one, $a_two) = @_;
  return add(Chop($a_one), rest_str($a_two));
}

sub eunshift {
  my ($elem, $array) = @_;
  return add(In, $elem, rest_str($array));
}

sub ejoin {
  my ($estr, $sub) = @_;
  return join $sub, @{ atoms($estr) };
}

sub is_atom_name {
  my ($atom, $name) = @_;
  if (is_atom($atom)) { return name($atom) eq $name }
  return 0;
}

sub is_sym {
  my $atom = shift;
  return is_atom_name($atom, 'Sym');
}

sub is_rept {
  my $atom = shift;
  return is_atom_name($atom, 'rept');
}

sub is_look {
  my $atom = shift;
  return is_atom_name($atom, 'look');
}

sub is_tillnot {
  my $atom = shift;
  if (is_atom($atom)) {
    given (name($atom)) {
      when ('Till') { return 1 }
      when ('Not')  { return 1 }
    }
  }
  return 0;
}

sub is_atom_str {
  my $atom = shift;
  return is_atom_name($atom, 'Str');
}

sub is_sub {
  my $atom = shift;
  return is_atom_name($atom, 'Sub');
}

sub is_return {
  my $atom = shift;
  return is_atom_name($atom, '->');
}

sub ast_to_table {
  my $ast   = shift;
  my $table = {};
  for my $spec (@{ atoms($ast) }) {
    my ($name, $rule) = flat($spec);
    if (exists $table->{$name}) {
      say "redefine token: <$name>";
    }
    $table->{$name} = $rule;
  }
  return $table;
}

sub get_rept_time {
  my $rept = shift;
  given ($rept) {
    when ('?') { return 0, 1 }
    when ('*') { return 0, -1 }
    default    { return 1, -1 }
  }
}

sub clean_ast {
  my $ast = shift;
  if (is_atom($ast)) { return clean_atom($ast) }
  my $clean_atoms = [];
  for my $atom (@{ atoms($ast) }) {
    push @{$clean_atoms}, clean_atom($atom);
  }
  return estr($clean_atoms);
}

sub clean_atom {
  my $atom = shift;
  my ($name, $value) = flat($atom);
  if (is_str($value))   { return cons($name, $value) }
  if (is_blank($value)) { return cons($name, $value) }
  if (is_atom($value)) {
    return cons($name, clean_atom($value));
  }
  if (is_atoms($value)) {
    return cons($name, clean_ast($value));
  }
  say from_ejson($atom);
  croak("ast data error!");
  return False;
}

sub see_ast {
  my $ast = shift;
  return from_ejson(clean_ast($ast));
}

sub is_exported {
  my $name = shift;
  return not(start_with($name, '_'));
}
1;
