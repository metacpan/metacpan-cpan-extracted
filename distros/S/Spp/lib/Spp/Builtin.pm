package Spp::Builtin;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(End In Out True False Qstr Qint
  is_estr is_qint is_int is_str is_array is_true
  is_false is_bool is_atom is_atoms
  error read_file write_file to_json from_json
  first tail rest len trim subarray uuid cutlast
  is_space is_upper is_lower is_digit is_xdigit
  is_alpha is_words is_hspace is_vspace
  clean_ast clean_atom start_with end_with to_end
  see_ast);

use JSON::XS qw(encode_json decode_json);

use constant {
  End   => chr(0),
  In    => chr(1),
  Out   => chr(2),
  True  => chr(3),
  False => chr(4),
  Qstr  => chr(5),
  Qint  => chr(6),
};

sub is_estr {
  my $estr = shift;
  return first($estr) eq In;
}

sub is_qint {
  my $estr = shift;
  return first($estr) eq Qint;
}

sub is_int {
  my $int = shift;
  return ($int ^ $int) eq '0';
}

sub is_str {
   my $x = shift;
   return (ref($x) eq ref(''));
}

sub is_array {
   my $x = shift;
   return (ref($x) eq ref([]));
}

sub is_true {
  my $atom = shift;
  return $atom eq True;
}

sub is_false {
  my $atom = shift;
  return $atom eq False;
}

sub is_bool {
  my $atom = shift;
  return 1 if is_false($atom);
  return 1 if is_true($atom);
  return 0;
}

sub is_atom {
   my $x = shift;
   return (is_array($x) and is_str($x->[0]));
}

sub is_atoms {
   my $pairs = shift;
   return 0 if !is_array($pairs);
   for my $pair (@{$pairs}) {
      return 0 if !is_atom($pair);
   }
   return 1;
}

sub error { say @_; exit() } 

sub read_file {
   my $file = shift;
   error("file: $file not exists") if not (-e $file);
   local $/;
   open my ($fh), '<:encoding(UTF-8)', $file or die $!;
   return <$fh>;
}

sub write_file {
   my ($file, $str) = @_;
   open my ($fh), '>:encoding(UTF-8)', $file or die $!;
   print {$fh} $str;
   say "write file: $file ok!";
   return $file;
}

sub to_json {
   my $data = shift;
   if (is_str($data)) {
      my $json_str = encode_json([$data]);
      return substr($json_str, 1, -1);
   }
   return encode_json($data);
}

sub from_json { return decode_json(shift) }

sub first {
   my $data = shift;
   if (is_str($data)) { return substr($data, 0, 1) }
   if (is_array($data)) { return $data->[0] }
   error("could not first No Str/array");
}

sub tail {
   my $data = shift;
   if (is_str($data)) { return substr($data, -1) }
   if (is_array($data)) { return $data->[-1] }
   error("Could not tail not Str/array");
}

sub rest {
   my $data = shift;
   return substr($data, 1) if is_str($data);
   if (is_array($data)) {
      my @array = @{$data};
      return [splice(@array, 1)];
   }
   error("rest only could do str or array");
}

sub len {
   my $data = shift;
   return scalar(@{$data}) if is_array($data);
   return length($data) if is_str($data);
}

sub trim {
   my $str = shift;
   if (is_str($str)) {
      $str =~ s/^\s+|\s+$//g;
      return $str;
   }
   error("trim only make string");
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
   error("subarray only could process array");
}

sub uuid { return scalar(rand()) }

sub cutlast {
   my $str = shift;
   if (is_str($str)) {
      return substr($str, 0, -1);
   }
   if (is_array($str)) {
      my @array = @{$str};
      return [splice @array, 0, -1];
   }
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
   my $r = shift;
   return $r ~~ [' ', "\t"];
}

sub is_vspace {
   my $r = shift;
   return $r ~~ ["\r", "\n"];
}

sub clean_ast {
   my $ast   = shift;
   return clean_atom($ast) if is_atom($ast);
   my $clean_atoms = [];
   for my $atom (@{$ast}) {
      push @{$clean_atoms}, clean_atom($atom);
   }
   return $clean_atoms;
}

sub clean_atom {
   my $atom = shift;
   my ($name, $value) = @{$atom};
   if (is_str($value)) { return [$name, $value] }
   if (len($value) == 0) {
      return [$name, $value]
   }
   if (is_atom($value)) {
      return [$name, clean_atom($value)];
   }
   return [$name, clean_ast($value)];
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
   my $str   = shift;
   my $index = index($str, "\n");
   return substr($str, 0, $index);
}

sub see_ast {
   my $ast = shift;
   return to_json(clean_ast($ast));
}

1;
