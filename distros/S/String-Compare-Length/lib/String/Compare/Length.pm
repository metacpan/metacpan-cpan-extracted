package String::Compare::Length;

use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw(compare_array compare_arrays compare_hoa);
our $VERSION = '0.05';

sub array_avg_length {
  my $array = shift;
  my $total_length = 0;
  for (@$array) {
    $total_length += length $_;
  }
  my $average_length = $total_length/@$array;
  return $average_length;
}

sub compare_array ($\@){
  my ($string, $array) = @_;
  my $string_length = length $string;
  my $average_length = array_avg_length($array);
  return abs($string_length - $average_length); 
}

sub compare_hoa ($\%){
  my ($string, $hoa) = @_;
  my %diff_hash = ();
  while (my ($key,$value) = each %$hoa) {
    $diff_hash{$key} = compare_array($string, @$value);
  }
  return \%diff_hash;
}

sub compare_arrays (\@\@){
  my ($arr1, $arr2) = @_;
  return abs(array_avg_length($arr1) - array_avg_length($arr2));
}

1;
__END__

=head1 NAME

String::Compare::Length - String Length Comparisons

=head1 SYNOPSIS

  use String::Compare::Length;
  my $string = "Netscape";
  my @strings = qw(Opera Safari Konqueror Mosaic);
  my $difference = compare_array($string,@strings);
  if ($difference == 0) {
     print "The string has a length equal to the average length of strings in the array";
  } else {
     print "The difference in length is $difference";
  }

=head1 DESCRIPTION

This module was created when I needed to use string length to determine the likelihood of a string belonging to a group of strings. With this module, you can calculate the difference in length between a string and the average length of strings in an array. Not limiting itself to simple arrays, the module also accomodates hashes of arrays. You can also compare the average lengths of strings in two arrays.

=head2 FUNCTIONS

=head2 compare_array

Accepts a string and an array. Determines the string length and the average length of the strings in the array. Returns the difference between the two.

=cut

=head2 compare_arrays

Accepts two arrays. Determines the average string length in both arrays. Returns the difference between them.

=cut

=head2 compare_hoa

Accepts a string and a hash containing array references. Determines the string length and average length of the strings in each array. Returns a hash reference with the same keys as the original but whose values are now the difference between the lengths. 

=cut

=head1 SEE ALSO

L<String::Compare>

=head1 AUTHOR

Mike Accardo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mike Accardo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
