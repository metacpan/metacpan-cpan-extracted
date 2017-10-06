package Spp::Estr;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(to_estr from_estr
atoms flat cons efirst esecond
etail elen epush eappend eunshift);

use Spp::Builtin;

sub to_estr {
  my $json = shift;
  my @chars = ();
  # 0: array mode
  # 1: str-mode
  # 2: int-mode
  # 3: str escape mode
  my $mode = 0;
  for my $ch (split '', $json) {
    if ($mode == 0) {
      if ($ch eq '[') { push @chars, In }
      elsif ($ch eq ']') {
        push @chars, Out;
      }
      elsif ($ch eq '"') {
        push @chars, Qstr;
        $mode = 1;
      }
      elsif (is_digit($ch)) {
        push @chars, Qint;
        push @chars, $ch;
        $mode = 2;
      }
    } elsif ($mode == 1) {
      given ($ch) {
        when ('"') { $mode = 0 }
        when ("\\") { $mode = 3 }
        default { push @chars, $ch }
      }
    } elsif ($mode == 2) {
      if ($ch eq ',') { $mode = 0 }
      elsif ($ch eq ']') {
        push @chars, Out;
        $mode = 0;
      }
      elsif (is_digit($ch)) {
        push @chars, $ch;
      }
    } else {         
      $mode = 1;
      given ($ch) {
        when ('t') { push @chars, "\t" }
        when ('r') { push @chars, "\r" }
        when ('n') { push @chars, "\n" }
        default { push @chars, $ch }
      }
    }
  }
  return join('', @chars);
}

sub from_estr {
  my $estr = shift;
  my @chars = ();
  # 0 start array mode
  # 1 str mode
  # 2 int mode
  # 3 middle array mode
  my $mode = 0;
  for my $ch (split '', $estr) {
    if ($mode == 0) {
      given ($ch) {
        when (In) { push @chars, '['; }
        when (Qstr) { push @chars, '"'; $mode = 1 }
        when (Qint) { $mode = 2; }
        when (Out) { push @chars, ']'; $mode = 3 }
      }
    }
    elsif ($mode == 1) {
      given ($ch) {
        when (Qstr) { push @chars, '","'; }
        when (Qint) { push @chars, '",'; $mode = 2; }
        when (In) { push @chars, '",['; $mode = 0; }
        when (Out) { push @chars, '"]'; $mode = 3; }
        default { push @chars, char_to_json($ch); }
      }
    }
    elsif ($mode == 2) {
      given ($ch) {
        when (Qstr) {
          push @chars, ',"';
          $mode = 1;
        }
        when (Qint) {
          push @chars, ',';
        }
        when (In) {
          push @chars, ',[';
          $mode = 0;
        }
        when (Out) {
          push @chars, ']';
          $mode = 3;
        }
        default {
          if (is_digit($ch)) {
            push @chars, $ch;
          }
        }
      }
    }
    else {
      given ($ch) {
        when (Qstr) { 
          push @chars, ',"';
          $mode = 1;
        }
        when (Qint) {
          push @chars, ',';
          $mode = 2;
        }
        when (In) {
          push @chars, ',[';
          $mode = 0
        }
        default {
          if ($ch eq Out) {
            push @chars, ']';
          }
        }
      }
    }
  }
  return join('', @chars);
}

sub char_to_json {
  my $ch = shift;
  given ($ch) {
    when ("\t") { return '\t'   }
    when ("\n") { return '\n'   }
    when ("\r") { return '\r'   }
    when ("\\") { return '\\\\' }
    when ('"')  { return '\"'   }
    default { return $ch }
  }
}

sub atoms {
  my $estr = shift;
  my @estrs = ();
  my $chars = '';
  my $depth = 0;
  # 0 chars has char 1: chars is blank
  my $mode = 0;
  for my $ch (split '', $estr) {
    if ($depth == 0) {
      $depth++ if $ch eq In;
    } elsif ($depth == 1) {
      if ($ch eq In) {
        $depth++;
        if ($mode == 0) { $mode = 1 }
        else { push @estrs, $chars; $chars = '' }
        $chars .= $ch;
      }
      elsif ($ch eq Qstr) {
        if ($mode == 0) { $mode = 1 }
        else { push @estrs, $chars; $chars = '' }
      }
      elsif ($ch eq Qint) {
        if ($mode == 0) { $mode = 1 }
        else { push @estrs, $chars; $chars = '' }
        # int return qint
        $chars .= $ch;
      }
      elsif ($ch eq Out) {
        if ($mode == 1) { push @estrs, $chars }
        last
      }
      else {
        if ($mode == 1) { $chars .= $ch }
      }
    } else {
      if ($ch eq In) { $depth++ }
      elsif ($ch eq Out) { $depth-- }
      $chars .= $ch;
    }
  }
  return @estrs;
}

sub cons {
  my @atoms = @_;
  my @estrs = map { estr($_) } @atoms;
  return In . join('', @estrs) . Out;
}

sub estr {
  my $atom = shift;
  if (is_estr($atom))  { return $atom          } 
  if (is_int($atom))   { return Qint . $atom   }
  if (is_str($atom))   { return Qstr . $atom   }
  if (is_array($atom)) { return cons(@{$atom}) }
  say "could not estr hash or func";
  return False
}

sub flat {
  my $estr = shift;
  my @atoms = atoms($estr);
  if (len([@atoms]) == 2) {
    return @atoms;
  }
  if (len([@atoms]) > 2) {
    my $rest = rest([@atoms]);
    return $atoms[0], cons(@{$rest});
  }  
  say from_estr($estr);
  say "Could not Flat!";
}

sub efirst {
  my $estr = shift;
  my @atoms = atoms($estr);
  return $atoms[0];
}

sub esecond {
  my $estr = shift;
  my @atoms = atoms($estr);
  return $atoms[1];
}

sub etail {
  my $estr = shift;
  my @atoms = atoms($estr);
  return $atoms[-1];
}

sub elen {
  my $estr = shift;
  my @atoms = atoms($estr);
  return scalar(@atoms);
}

sub epush {
  my ($array, $elem) = @_;
  return cutlast(estr($array)) . estr($elem) . Out;
}

sub eappend {
  my ($a_one, $a_two) = @_;
  return cutlast(estr($a_one)) . rest(estr($a_two));
}

sub eunshift {
  my ($elem, $array) = @_;
  return In . estr($elem) . rest(estr($array));
}

1;
