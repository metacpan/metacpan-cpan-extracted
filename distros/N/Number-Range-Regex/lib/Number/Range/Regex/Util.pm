# Number::Range::Regex::Util
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Util;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw ( option_mangler has_regex_overloading
               multi_union empty_set
               base_chr base_ord base_digits base_next base_prev
               _calculate_digit_range );
@EXPORT_OK = qw ( _order_by_min ) ;
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

$VERSION = '0.32';

require overload;
sub has_regex_overloading {
  # http://www.gossamer-threads.com/lists/perl/porters/244314
  # http://search.cpan.org/~jesse/perl-5.12.0/pod/perl5120delta.pod#qr_overload$
  # 1.08, 1.09 are too low. 1.10: works
  # http://search.cpan.org/~jesse/perl-5.11.1/lib/overload.pm
  return defined $overload::VERSION && $overload::VERSION > '1.09';
}

sub empty_set {
  shift;
  return Number::Range::Regex::CompoundRange->new( @_ );
}

sub multi_union {
  my $opts = option_mangler( ref $_[-1] eq 'HASH' ? pop : undef );
  my $warn_overlap = delete $opts->{warn_overlap};
  my @ranges = @_;
  my $self = empty_set( $opts );
  $self = $self->union( $_, { warn_overlap => $warn_overlap } )  for  @ranges;
#  $self->{opts} = $opts;
  return $self;
}

# local options can override defaults
sub option_mangler {
  my (@passed_opts) = grep defined, @_;
  # next line is redundant but an optimization
  return $Number::Range::Regex::Range::default_opts  unless  @passed_opts;
  unshift @passed_opts, $Number::Range::Regex::Range::default_opts;
  my $opts;
  foreach my $opts_ref ( @passed_opts ) {
    die "too many arguments from ".join(":", caller())." $opts_ref" unless ref $opts_ref eq 'HASH';
    # make a copy of options hashref, add overrides
    while (my ($key, $val) = each %$opts_ref) {
      $opts->{$key} = $val;
    }
  }
  return $opts;
}

sub _order_by_min {
  my ($a, $b) = @_;
  return $a->{min} < $b->{min} ? ($a, $b) : ($b, $a);
}

sub base_digits {
  my ($base) = @_;
  return join '', map { $Number::Range::Regex::Range::STANDARD_DIGIT_ORDER[$_] } (0..$base-1);
}

sub base_next {
  my ($c, $base_digits) = @_;
  my $ord = base_ord($c, $base_digits);
  return  if  $ord+1 == length $base_digits;
  return base_chr($ord+1, $base_digits);
}

sub base_prev {
  my ($c, $base_digits) = @_;
  my $ord = base_ord($c, $base_digits);
  return  if  $ord == 0;
  return base_chr($ord-1, $base_digits);
}

#TODO: memoize base_ord, base_chr for performance?
sub base_ord {
  my ($c, $base_digits) = @_;
  return -1                    if  $c eq -1;
  return 1+length $base_digits  if  length $c > 1;
  my $ord = index $base_digits, $c;
  die "$c not found in $base_digits"  if  $ord == -1;
  return $ord;
}

sub base_chr {
  my ($n, $base_digits) = @_;
  my $chr = substr($base_digits, $n, 1);
  die "offset out of range: $n > ".length($base_digits)  if  !length $chr;
  return $chr;
}

#TODO: should _calculate_digit_range() be in Util?
# calculate the tersest possible representation of a digit range
# '1'            -> 1
# '12'           -> [12]
# '123'          -> [1-3] #preferred stylistically to [123]
# '1234'         -> [1-4]
# '0123456789'   -> \d
# '123456789abc' -> [1-9a-c]
sub _calculate_digit_range {
  my ($digit_min, $digit_max, $base_digits) = @_;
  return  unless  defined $digit_min && defined $digit_max;
  my $ord_min = base_ord( $digit_min, $base_digits );
  my $ord_max = base_ord( $digit_max, $base_digits );
  return             if  $ord_min > $ord_max;
  return $digit_min  if  $ord_min == $ord_max;
  my @range_chars;
  for(my $n=$ord_min; $n <= $ord_max; ++$n) {
    push @range_chars, base_chr( $n, $base_digits );
  }
  my $last = $range_chars[0];
  my $n = 1;
  while($n < @range_chars) {
    my $this = $range_chars[$n];
    if(1 == ord($this)-ord($last)) {
      $range_chars[$n-1] .= $this;
      splice @range_chars, $n, 1;
    } else {
      $n++;
    }
    $last = $this;
  }
  foreach my $n (0..$#range_chars) {
    my $str = $range_chars[$n];
    my $len = length $str;
    die "internal error"  if  $len == 0;
    next                  if  $len == 1; # 'a' is as terse as possible
    next                  if  $len == 2; # 'bc' is also as terse as possible
    # collapse e.g. 234567 into 2-7
    my $first = substr($str, 0, 1);
    my $last  = substr($str, -1, 1);
    $range_chars[$n] = ($first eq '0' && $last eq '9') ? '\d' : "$first-$last";
  }
  if(1==@range_chars) {
    my $ret = $range_chars[0];
    # we don't need brackets if all we have is \d or a single digit
    return $ret  if  $ret eq '\d' || length($ret)==1;
  }
  return join '', '[', @range_chars, ']';
}

1;

