package Spp::Builtin;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(all is_str is_array
  read_file write_file concat to_json from_json
  start_with end_with first tail rest
  trim len subarray to_end append);

use 5.012;
no warnings "experimental";
use JSON::XS qw(encode_json decode_json);
use List::MoreUtils qw(all);

sub is_str {
   my $x = shift;
   return (ref($x) eq ref(''));
}

sub is_array {
   my $x = shift;
   return (ref($x) eq ref([]));
}

sub read_file {
   my $file = shift;
   die("file: $file not exists") if not -e $file;
   local $/;
   open my ($fh), '<:utf8', $file or die $!;
   return <$fh>;
}

sub write_file {
   my ($file, $str) = @_;
   open my ($fh), '>:utf8', $file or die $!;
   print {$fh} $str;
   say "write file: |$file| ok!";
   return $file;
}

sub concat {
   my @strs = @_;
   return join('', @strs);
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
   die "could not first($data)";
}

sub tail {
   my $data = shift;
   if (is_str($data)) { return substr($data, -1) }
   if (is_array($data)) { return $data->[-1] }
   die "Could not tail($data)";
}

sub rest {
   my $data = shift;
   return substr($data, 1) if is_str($data);
   if (is_array($data)) {

      # copy $data, splice would change array
      my @array = @{$data};
      return [splice(@array, 1)];
   }
   die("rest only could do str or array");
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
   die("trim only make string");
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
   die "subarray only could process array";
}

sub to_end {
   my $str   = shift;
   my @chars = ();
   for my $char (split '', $str) {
      last if $char eq "\n";
      push @chars, $char;
   }
   return join('', @chars);
}

sub append {
   my ($array_one, $array_two) = @_;
   push @{$array_one}, @{$array_two};
   return $array_one;
}

1;
