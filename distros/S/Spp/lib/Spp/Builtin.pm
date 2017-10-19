package Spp::Builtin;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(End In Out True False Qstr Qint Blank
  clean first string strings sort_array to_json from_json
  is_exists first_char last_char rest_str tail rest
  is_string is_int is_array Chop add uuid
  error read_file write_file len trim subarray
  is_space is_upper is_lower is_digit is_xdigit
  is_alpha is_words is_hspace is_vspace
  start_with end_with to_end get_time change_sufix
  get_file_mtime is_update tidy_perl find_wanted 
  to_int copy is_false is_true croak
  estr estr_ints is_str is_bool is_estr is_blank
  cons cons_atom is_atom);

use File::Find::Wanted qw(find_wanted);
use Time::Piece;
use File::Basename qw(fileparse);
use Perl::Tidy;
use File::Copy qw(copy);
use String::Random;
use JSON::XS qw(decode_json encode_json);
use Carp;

use constant {
  End   => chr(0),
  In    => chr(1),
  Out   => chr(2),
  True  => chr(3),
  False => chr(4),
  Qstr  => chr(5),
  Qint  => chr(6),
  Blank => (chr(1) . chr(2)),
};

sub cons {
  my @args = @_;
  my $estr = join '', map { cons_atom($_) } @args;
  return (In . $estr . Out);
}

sub cons_atom {
  my $atom = shift;
  if (is_estr($atom)) { return $atom }
  if (is_str($atom))  { return (Qstr . $atom) }
  say "|$atom|";
  croak("not estr or str or int??");
}

sub estr {
  my $estr_array = shift;
  if (is_string($estr_array)) { croak('trace it...') }
  return cons(@{$estr_array});
}

sub estr_ints {
  my $ints = shift;
  my @estrs = map { (Qint . $_) } @{$ints};
  return In . join('', @estrs) . Out;
}

sub is_str {
  my $str = shift;
  if (is_string($str)) {
    my $char = substr($str, 0, 1);
    if (ord($char) > 6) { return 1 }
  }
  return 0;
}

sub is_bool {
  my $char = shift;
  if (is_false($char)) { return 1 }
  if (is_true($char))  { return 1 }
  return 0;
}

sub is_estr {
  my $str = shift;
  return substr($str, 0, 1) eq In;
}

sub is_blank {
  my $estr = shift;
  return $estr eq Blank;
}

sub error { say @_; exit() }

sub to_json {
  my $data = shift;
  return encode_json($data);
}

sub from_json {
  my $data = shift;
  return decode_json($data);
}

sub clean {
  my $stack = shift;
  @{$stack} = ();
}

sub string {
  my $stack = shift;
  return join '', @{$stack};
}

sub first {
  my $stack = shift;
  if (is_array($stack)) {
    return $stack->[0];
  }
  croak("Could not first not Array");
  return False
}

sub strings {
  my $stack = shift;
  return $stack;
}

sub sort_array {
  my $array = shift;
  return [reverse sort @{$array}];
}

sub uuid {
  my $gen = String::Random->new;
  return $gen->randregex('[A-Z]{5}');
}

sub is_exists {
  my $file = shift;
  return (-e $file);
}

sub first_char {
  my $data = shift;
  if (is_string($data)) {
    return substr $data, 0, 1;
  }
  croak("could not first No Str");
  return True
}

sub last_char {
  my $str = shift;
  if (is_string($str)) {
    return substr $str, -1;
  }
  croak("Could not last-char Array");
}

sub rest_str {
  my $data = shift;
  return substr($data, 1) if is_string($data);
  croak("rest_str only could do str");
}

sub tail {
  my $data = shift;
  if (is_array($data)) {
    return $data->[-1];
  }
  croak("Could not tail not Array");
}

sub rest {
  my $data = shift;
  if (is_array($data)) {
    my @array = @{$data};
    return [splice(@array, 1)];
  }
  croak("rest only could do array");
}

sub is_string {
  my $x = shift;
  return (ref($x) eq ref(''));
}

sub is_int {
  my $int = shift;
  return ($int ^ $int) eq '0';
}

sub is_array {
  my $x = shift;
  return (ref($x) eq ref([]));
}

sub Chop {
  my $str = shift;
  return substr($str, 0, -1);
}

sub add {
  my @strs = @_;
  return join '', @strs;
}

sub read_file {
  my $file = shift;
  error("file: $file not exists") if not(-e $file);
  local $/;
  open my ($fh), '<:encoding(UTF-8)', $file or die $!;
  return <$fh>;
}

sub write_file {
  my ($file, $str) = @_;
  open my ($fh), '>:encoding(UTF-8)', $file or die $!;
  print {$fh} $str;
  # say "write file: $file ok!";
  return $file;
}

sub len {
  my $data = shift;
  return length($data) if is_string($data);
  return scalar(@{$data}) if is_array($data);
  croak("len only make array");
}

sub trim {
  my $str = shift;
  if (is_string($str)) {
    $str =~ s/^\s+|\s+$//g;
    return $str;
  }
  croak("trim only make string");
}

sub subarray {
  my ($array, $from, $to) = @_;
  my @array = @{$array};
  if (is_array($array)) {
    if ($to > 0) {
      my $len = $to - $from + 1;
      my $sub_array = [splice @array, $from, $len];
      return $sub_array;
    }
    if (defined $to) {
      return [splice @array, $from, $to];
    }
    return [splice @array, $from];
  }
  croak("subarray only could process array");
}

sub is_space {
  my $r = shift;
  return $r ~~ ["\n", "\t", "\r", ' '];
}

sub is_upper {
  my $r = shift;
  return $r ~~ ['A' .. 'Z'];
}

sub is_lower {
  my $r = shift;
  return $r ~~ ['a' .. 'z'];
}

sub is_digit {
  my $r = shift;
  return $r ~~ ['0' .. '9'];
}

sub is_xdigit {
  my $char = shift;
  return 1 if is_digit($char);
  return 1 if $char ~~ ['a' .. 'f'];
  return 1 if $char ~~ ['A' .. 'F'];
  return 0;
}

sub is_alpha {
  my $r = shift;
  return $r ~~ ['a' .. 'z', 'A' .. 'Z', '_'];
}

sub is_words {
  my $r = shift;
  return 1 if is_digit($r);
  return 1 if is_alpha($r);
  return 0;
}

sub is_hspace {
  my $h = shift;
  return $h ~~ [' ', "\t"];
}

sub is_vspace {
  my $v = shift;
  return $v ~~ ["\r", "\n"];
}

sub start_with {
  my ($str, $start) = @_;
  return 1 if index($str, $start) == 0;
  return 0;
}

sub end_with {
  my ($str, $end) = @_;
  my $len = length($end);
  return substr($str, -$len) eq $end;
}

sub to_end {
  my $str = shift;
  my $index = index($str, "\n");
  return substr($str, 0, $index);
}

sub get_time {
  my $t = localtime;
  return $t->hms('-');
}

sub change_sufix {
  my ($file, $from_sufix, $to_sufix) = @_;
  my @sufix = ($from_sufix);
  my ($name, $path) = fileparse($file, @sufix);
  return $path . $name . $to_sufix;
}

sub get_file_mtime {
  my $file = shift;
  if (not(-e $file)) {
    say "$file is not exists!";
  }
  else {
    return (stat($file))[9];
  }
}

sub is_update {
  my ($file, $to_file) = @_;
  my $file_mtime    = get_file_mtime($file);
  my $to_file_mtime = get_file_mtime($to_file);
  return ($file_mtime < $to_file_mtime);
}

sub to_int {
  my $str = shift;
  return 0 + $str;
}

sub is_false {
  my $char = shift;
  return $char eq False;
}

sub is_true {
  my $char = shift;
  return $char eq True;
}

sub is_atom {
  my $estr = shift;
  return substr($estr, 0, 2) eq (In . Qstr);
}

sub tidy_perl {
  my $source_string = shift;
  my $dest_string;
  my $stderr_string;
  my $errorfile_string;
  my $argv  = "-i=2 -l=60 -vt=2 -pt=2 -bt=1 -sbt=2 -bbt=1";
  my $error = Perl::Tidy::perltidy(
    argv        => $argv,
    source      => \$source_string,
    destination => \$dest_string,
    stderr      => \$stderr_string,
    errorfile   => \$errorfile_string,
  );

  if ($error) {
    print "<<STDERR>>\n$stderr_string\n";
  }
  return $dest_string;
}

1;
