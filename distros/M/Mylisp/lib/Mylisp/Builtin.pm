package Mylisp::Builtin;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
End True False In Out Qstr Qint Blank Ep 
read_file write_file croak error len

is_alpha is_digit is_hspace is_lower is_space
is_upper is_vspace is_words is_xdigit

start_with end_with to_end add trim repeat
first_char last_char rest_str cut to_chars
str_to_int

subarray to_str aflat amatch
apush aunshift aappend ashift ajoin asplit
first tail rest sort_array

int_to_str has_change
);

use Carp;

use constant {
  End   => chr(0),
  True  => chr(1),
  False => chr(2),
  In    => chr(3),
  Out   => chr(4),
  Qstr  => chr(5),
  Qint  => chr(6),
  Blank => chr(3).chr(4),
  Ep    => chr(92),
};

sub error { say @_; exit }

sub len {
  my $data = shift;
  return length($data) if ref($data) eq ref('');
  return scalar(@{$data});
}

## =======================
## for char

sub is_alpha {
  my $c = shift;
  return 1 if is_lower($c);
  return 1 if is_upper($c);
  return 1 if $c eq '_';
  return 0;
}

sub is_digit {
  my $c = shift;
  my $i = ord($c);
  return ($i >= 48 and $i <= 57);
}

sub is_hspace {
  my $c = shift;
  return ($c eq ' ' or $c eq "\t");
}

sub is_lower {
  my $c = shift;
  my $i = ord($c);
  return ($i >= 97 and $i <= 122);
}

sub is_space {
  my $c = shift;
  return ($c eq "\n" or
    $c eq "\t" or
    $c eq "\r" or
    $c eq ' ');
}

sub is_upper {
  my $c = shift;
  my $i = ord($c);
  return ($i >= 65 and $i <= 90);
}

sub is_vspace {
  my $c = shift;
  return ($c eq "\r" or $c eq "\n");
}

sub is_words {
  my $c = shift;
  return 1 if is_digit($c);
  return 1 if is_alpha($c);
  return 0;
}

sub is_xdigit {
  my $c = shift;
  return 1 if is_digit($c);
  my $i = ord($c);
  return 1 if $i >= 65 and $i <= 70;
  return 1 if $i >= 97 and $i <= 102;
  return 0;
}

## ===============================
## for string

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
  my ($text, $off) = @_;
  my $str = substr $text, $off;
  my $index = index($str, "\n");
  return substr($str, 0, $index);
}

sub add {
  my @strs = @_;
  return join '', @strs;
}

sub trim {
  my $str = shift;
  $str =~ s/^\s+|\s+$//g;
  return $str;
}

sub repeat {
  my ($str, $count) = @_;
  return $str x $count;
}

sub first_char {
  my $data = shift;
  return substr $data, 0, 1;
}

sub last_char {
  my $str = shift;
  return substr $str, -1;
}

sub rest_str {
  my $str = shift;
  return substr $str, 1;
}

sub cut {
  my $str = shift;
  return substr($str, 0, -1);
}

sub to_chars {
  my $str = shift;
  return [ split '', $str ];
}

sub str_to_int {
  my $str = shift;
  return 0 + $str;
}

sub int_to_str {
  my $int = shift;
  return "$int";
}

### ===============================
### for array

sub subarray {
  my ($array, $from, $to) = @_;
  my @array = @{$array};
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

sub to_str {
  my $array = shift;
  return join '', @{$array};
}

sub aflat {
  my $array = shift;
  return $array->[0], $array->[1];
}

sub amatch {
  my $array = shift;
  return $array->[0], rest($array);
}

sub apush {
  my ($array, $elem) = @_;
  push @{$array}, $elem;
  return $array;
}

sub aunshift {
  my ($elem, $array) = @_;
  unshift @{$array}, $elem;
  return $array;
}

sub aappend {
  my ($a, $b) = @_;
  push @{$a}, @{$b};
  return $a;
}

sub ashift {
  my $array = shift;
  shift @{$array};
  return 1;
}

sub ajoin {
  my ($char, $array) = @_;
  return join $char, @{$array};
}

sub asplit {
  my ($char, $str) = @_;
  return [ split $char, $str ];
}

sub first {
  my $array = shift;
  return $array->[0];
}

sub tail {
  my $data = shift;
  return $data->[-1];
}

sub rest {
  my $data = shift;
  return subarray($data, 1);
}

sub sort_array {
  my $array = shift;
  return [reverse sort @{$array}];
}

## =============================
## for file

sub read_file {
  my $file = shift;
  croak("file: $file not exists") if not -e $file;
  local $/;
  open my ($fh), '<', $file or die $!;
  return <$fh>;
}

sub write_file {
  my ($file, $str) = @_;
  open my ($fh), '>', $file or die $!;
  print {$fh} $str;
  return $file;
}

sub get_file_time {
  my $file = shift;
  if (not(-e $file)) {
    say "$file is not exists!";
  }
  else {
    return (stat($file))[9];
  }
}

sub has_change {
  my ($file, $to_file) = @_;
  if ((-e $file) && (-e $to_file)) {
    my $file_time    = get_file_time($file);
    my $to_file_time = get_file_time($to_file);
    return ($file_time > $to_file_time);
  }
  return 1;
}

1;
