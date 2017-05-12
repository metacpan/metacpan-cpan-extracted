package Spp::Tools;

=head1 NAME

Spp::Tools - The perl interface for Spp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Tools gather some small reused function

    use Spp::Tools;

    my $first_element = first([1,2,3]);
    # 1

=cut

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
create_cursor
add_exprs
all_is_spp_array
all_is_spp_int
all_is_spp_str
all_is_spp_sym
apply_char
error
host_range
fill_array
get_atoms_type
get_token_name
in
is_bool
is_false
is_fail
is_nil
is_true
is_str
is_int
is_array
is_hash
is_func
is_match
is_match_atom
is_match_atoms
is_same
len
load_file
host_join
host_split
host_substr
host_zip
read_file
rest
see
subarray
to_str
trim
type
uuid
write_file
name_match
gather_match
get_rule_file
get_spp_file
host_sum
host_concat
);

use 5.020;
use Carp qw(croak);
use JSON qw(encode_json decode_json);
use List::Util qw(max);
use experimental qw(switch autoderef);
use List::MoreUtils qw(pairwise);

###################################################

sub create_cursor {
  my $str = shift;
  my $trim_str = trim($str);
  return {
    STR  => $trim_str,
    POS  => 0,
    LEN  => len($trim_str),
    LOG  => [],
  };
}

sub add_exprs {
  my $atoms = shift;
  return $atoms->[0] if len($atoms) == 1;
  return ['exprs', $atoms];
}

sub all_is_match_atom {
  my $atoms = shift;
  for my $atom (values $atoms) {
    next if is_match_atom($atom);
    return 0;
  }
  return 1;
}

sub all_is_spp_array {
  my $atoms = shift;
  if (all_is_match_atom($atoms)) {
    return 1 if get_atoms_type($atoms) eq 'array';
  }
  return 0;
}

sub all_is_spp_int {
  my $atoms = shift;
  if (all_is_match_atom($atoms)) {
    return 1 if get_atoms_type($atoms) eq 'int';
  }
  return 0;
}

sub all_is_spp_str {
  my $atoms = shift;
  if (all_is_match_atom($atoms)) {
    return 1 if get_atoms_type($atoms) eq 'str';
  }
  return 0;
}

sub all_is_spp_sym {
  my $atoms = shift;
  if (all_is_match_atom($atoms)) {
    return 1 if get_atoms_type($atoms) eq 'sym';
  }
  return 0;
}

sub apply_char {
  my ($len, $cursor) = @_;
  my $pos = $cursor->{POS};
  my $str = $cursor->{STR};
  return '' if $pos >= $cursor->{LEN};
  return substr($str, $pos, $len) if $len > 0;
  return substr($str, $pos + $len, abs($len)) if $len < 0;
  return substr($str, $pos, 1) if $len == 0;
}

sub error { say @_; exit }

sub fill_array {
  my ($value, $len) = @_;
  my $fill_array = [];
  for my $x (1 .. $len) {
    push $fill_array, $value;
  }
  return $fill_array;
}

sub host_range {
  my ($from, $to) = @_;
  return [ $from .. $to ];
}

sub get_atoms_type {
  my $atoms = shift;
  my $type = type($atoms->[0]);
  for my $atom (values $atoms) {
    next if type($atom) eq $type;
    return 0
  }
  return $type;
}

sub get_token_name {
   my $token_name = shift;
   if ( $token_name =~ /^\./ ) {
      return substr($token_name, 1);
   }
   return $token_name;
}

sub in {
  my ($element, $array) = @_;
  my $element_str = to_str($element);
  for my $x (values $array) {
    return 1 if to_str($x) eq $element_str;
  }
  return 0;
}

sub is_bool {
  my $x = shift;
  return 1 if is_match_atom($x) and type($x) eq 'bool';
  return 0;
}

sub is_false {
  my $x = shift;
  return 1 if is_bool($x) and $x->[1] eq 'false';
  return 0;
}

sub is_nil {
  my $x = shift;
  return 1 if type($x) eq 'nil';
  return 0;
}

sub is_true {
  my $x = shift;
  return 1 if is_bool($x) and $x->[1] eq 'true';
  return 0;
}

sub is_fail {
  my $x = shift;
  return 1 if is_false($x) or is_nil($x);
  return 0;
}

sub is_str {
   my $x = shift;
   return 1 if ref($x) eq ref('');
   return 0;
}

sub is_int {
  my $x = shift;
  if (is_str($x)) {
    return 0 if $x ^ $x;
    return 0 if $x eq '';
    return 1;
  }
  return 0;
}

sub is_array {
   my $x = shift;
   return 1 if ref($x) eq ref([]);
   return 0;
}

sub is_hash {
   my $x = shift;
   return 1 if ref($x) eq ref({});
   return 0;
}

sub is_func {
  my $x = shift;
  return 1 if ref($x) eq ref(sub {});
  return 0;
}

sub is_match {
  my $x = shift;
  return 0 if is_false($x);
  return 1 if is_true($x) or is_str($x);
  return 1 if is_match_atom($x) or is_match_atoms($x);
  my $data_str = to_str($x);
  error("error match data: $data_str");
}

sub is_match_atom {
   my $x = shift;
   return 0 unless is_array($x);
   return 0 unless len($x) > 1;
   return 0 unless is_str($x->[0]);
   return 1;
}

sub is_match_atoms {
  my $pairs = shift;
  if ( is_array($pairs) ) {
    for my $pair (values $pairs) {
      next if is_match_atom($pair);
      return 0;
    }
    return 1;
  }
  return 0;
}

sub is_same {
  my ($data_a, $data_b) = @_;
  return 1 if to_str($data_a) eq to_str($data_b);
  return 0;
}

sub len {
  my $data = shift;
  return scalar( @{$data} ) if is_array($data);
  return $data if is_int($data);
  return length( $data ) if is_str($data);
}

sub load_file {
  my $file_name = shift;
  my $file_txt = read_file($file_name);
  return decode_json($file_txt);
}

sub host_join {
  my ($array, $sep) = @_;
  if (defined $sep) {
    return join($sep, @$array);
  }
  return join('', @$array);
}

sub host_split {
  my ($str, $sep) = @_;
  if (defined $sep) {
    return [ split($sep, $str) ];
  }
  return [ split('', $str) ];
}

sub host_substr {
  my ($str, $from, $len) = @_;
  return substr($str, $from, $len);
}

sub host_zip {
  my ($a_one, $a_two) = @_;
  return [ pairwise { [$a, $b] } @$a_one, @$a_two ];
}

sub read_file {
  my $file = shift;
  error("file: $file not exists") if not -e $file;
  local $/;
  open my ($fh), '<', $file or die $!;
  return <$fh>;
}

sub rest {
   my $data = shift;
   my $len_data = len($data);
   if (is_array($data)) {
     return [ splice( [ @{$data} ], 1, $len_data ) ];
   }
   return substr($data, 1) if is_str($data);
   error("rest only could implement with str or array");
}

sub see {
  my $data = shift;
  say to_str($data);
  return 1;
}

sub subarray {
  my ($array, $from, $to) = @_;
  if (is_array($array)) {
    my $list = [ @{$array} ];
    if ($to < 0) {
      my $len = len($list) + $to - $from + 1;
      my $sub_list = [ splice $list, $from, $len ];
      return $sub_list;
    }
    return [ splice $list, $from, $to ];
  }
  my $array_str = to_str($array);
  error("subarray only could process array: not $array_str");
}

sub to_str {
  my $data = shift;
  return $data if is_str($data);
  return encode_json($data);
}

sub trim {
  my $str = shift;
  if (is_str($str)) {
    $str =~ s/^\s+|\s+$//g;
    return $str;
  }
  my $str_json = to_str($str);
  error("trim only could make string, not $str_json");
}

sub type {
  my $x = shift;
  return $x->[0] if is_array($x);
  my $x_str = to_str($x);
  error("Could not get $x_str type");
}

sub uuid { return scalar(rand()) }

sub write_file {
  my ($file, $str) = @_;
  open my ($fh), '>', $file or die $!;
  print {$fh} $str;
  return $file;
}

sub name_match {
  my ( $name, $match ) = @_;
  return $match       if is_false($match);
  return $match       if is_true($match);
  return [$name, $match] if is_str($match);
  return $match          if $name =~ /^[a-z_]/;
  return [$name, [$match]] if is_match_atom($match);
  return [$name, $match];
}

sub gather_match {
  my ( $gather, $match ) = @_;
  return $match if is_false($match);
  return $match if is_true($gather);
  if ( is_str($gather) ) {
    return $gather if is_true($match);
    return $gather . $match if is_str($match);
    return $match if is_match_atom($match);
    return $match if is_match_atoms($match);
  }
  return $gather if is_true($match) or is_str($match);
  if ( is_match_atom($gather) ) {
    return [ $gather, $match ] if is_match_atom($match); 
    return [ $gather, @{$match} ] if is_match_atoms($match); 
  }
  if ( is_match_atoms($gather) ) {
    return [ @{$gather}, $match ] if is_match_atom($match);
    return [ @{$gather}, @{$match} ] if is_match_atoms($match);
  }
  my $gather_str = to_str($gather);
  my $match_str = to_str($match);
  error("$gather_str could not gather match with $match_str");
}

sub get_rule_file {
  my $name = shift;
  return "$name.json" if (-e "$name.json");
  for my $dir (@INC) {
    my $path = "$dir/rule/$name.json";
    return $path if (-e $path);
  }
  error("Could not get rule file: $name.json");
}

sub get_spp_file {
  my $name = shift;
  return "$name.spp" if (-e "$name.spp");
  for my $dir (@INC) {
    my $path = "$dir/spp/$name.spp";
    return $path if (-e $path);
  }
  error("Could not get spp file: $name.spp");
}

sub host_sum {
  my $nums = shift;
  my $sum = 0;
  for my $value (values $nums) {
    $sum += $value;
  }
  return $sum;
}

sub host_concat {
  my $arrays = shift;
  my $concat_array = [];
  for my $array (values $arrays) {
    push $concat_array, @{$array};
  }
  return $concat_array;
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp::Tools

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spp>

=item * Search CPAN

L<http://search.cpan.org/dist/Spp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Song.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Spp::Tools
