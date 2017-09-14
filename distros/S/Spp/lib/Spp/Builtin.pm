package Spp::Builtin;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  all is_str is_array is_hash is_atom is_atoms
  error read_file write_file to_json from_json concat
  first rest trim len subarray uuid zip unique append
  is_char_space is_char_upper is_char_lower is_char_digit
  is_char_xdigit is_char_alpha is_char_words
  is_char_hspace is_char_vspace clean_ast);

use JSON::XS qw(encode_json decode_json);
use List::MoreUtils qw(all mesh uniq);

sub is_str {
   my $x = shift;
   return (ref($x) eq ref(''));
}

sub is_array {
   my $x = shift;
   return (ref($x) eq ref([]));
}

sub is_hash {
   my $x = shift;
   return (ref($x) eq ref({}));
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
   say "write file: |$file| ok!";
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

sub concat {
   my @strs = @_;
   return join('', @strs);
}

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

      # copy $data, splice would change array
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
   # make copy of $array, splice would change it
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

sub zip {
   my ($arr_one, $arr_two) = @_;
   return [ mesh(@{$arr_one}, @{$arr_two}) ];
}

sub unique {
   my $array = shift;
   return [ uniq @{$array} ];
}

sub append {
   my ($array_one, $array_two) = @_;
   push @{$array_one}, @{$array_two};
   return $array_one;
}

sub is_char_space {
   my $r = shift;
   return $r ~~ ["\n", "\t", "\r", ' '];
}

sub is_char_upper {
   my $r = shift;
   return $r ~~ ['A' .. 'Z'];
}

sub is_char_lower {
   my $r = shift;
   return $r ~~ ['a' .. 'z'];
}

sub is_char_digit {
   my $r = shift;
   return $r ~~ ['0' .. '9'];
}

sub is_char_xdigit {
   my $char = shift;
   return 1 if is_char_digit($char);
   return 1 if $char ~~ ['a' .. 'f'];
   return 1 if $char ~~ ['A' .. 'F'];
   return 0;
}

sub is_char_alpha {
   my $r = shift;
   return $r ~~ ['a' .. 'z', 'A' .. 'Z', '_'];
}

sub is_char_words {
   my $r = shift;
   return 1 if is_char_digit($r);
   return 1 if is_char_alpha($r);
   return 0;
}

sub is_char_hspace {
   my $r = shift;
   return $r ~~ [' ', "\t"];
}

sub is_char_vspace {
   my $r = shift;
   return $r ~~ ["\r", "\n"];
}

sub clean_ast {
   my $ast   = shift;
   return clean_atom($ast) if is_atom($ast);
   if (is_array($ast)) {
      my $clean_atoms = [];
      for my $atom (@{$ast}) {
         if (is_atom($atom)) {
            push @{$clean_atoms}, clean_atom($atom);
         } else {
            say to_json($atom);
            error("not atom in ast value!");
         }
      }
      return $clean_atoms;
   }
   say to_json([$ast]);
   error("ast is not array!")
}

sub clean_atom {
   my $atom = shift;
   my ($name, $value) = @{$atom};
   if (is_str($value)) { return [$name, $value] }
   if (is_array($value)) {
      if (len($value) == 0) {
         return [$name, $value]
      }
      if (is_atom($value)) {
         return [$name, clean_atom($value)];
      }
      if (is_atoms($value)) {
        return [$name, clean_ast($value)];
     }
   }
   say to_json($atom);
   error("error ast not atom or atoms!");
}

1;
