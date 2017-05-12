# Number::Range::Regex::SimpleRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::SimpleRange;

# a contiguous, finite range, can be expressed as an array of TrivialRange

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION );
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.32';

use Number::Range::Regex::Util ':all';
use Number::Range::Regex::Util::inf qw( neg_inf pos_inf inf_type _is_negative _pad );

sub new {
  my ($class, $min, $max, $passed_opts) = @_;

  my $opts = option_mangler( $passed_opts );

  die 'internal error: undefined min and max from caller: '.join(":", caller) if !( defined $min && defined $max );

  my $base = $opts->{base};
  my $base_digits = $opts->{base_digits} = base_digits($base);
  my $base_max    = $opts->{base_max}    = substr($base_digits, -1);
  my $base_digits_regex = $opts->{base_digits_regex} = _calculate_digit_range( 0, $base_max, $base_digits );

  die "min ($min) must be a base $opts->{base} integer or /^[+-]?inf\$/"  if  $min !~ /^[-+]?(?:inf|[$base_digits]+)$/;
  die "max ($max) must be a base $opts->{base} integer or /^[+-]?inf\$/"  if  $max !~ /^[-+]?(?:inf|[$base_digits]+)$/;

  # convert '-inf' / '+inf' strings to neg_inf / pos_inf objects
  # and canonicalize min and max by removing leading zeroes, plus signs
  foreach my $val ( \$min, \$max ) {
    next  if  ref $$val; # don't do these checks on pos_inf/neg_inf objects
    $$val =~ s/^\+//;
    $$val =~ s/^(-?)0+/$1/; #strip leading zeroes
    $$val = 0        if  $$val =~ /^-?$/; #don't strip "0" or "-0" -> ""
    $$val = pos_inf  if  $$val =~ /^[+]?inf$/;
    $$val = neg_inf  if  $$val =~ /^-inf$/;
  }

  # any infinite numbers are compared using Util::inf, but others
  # must be compared as strings to account for bases >10
  # TODO: this assumes we have a base in ascii-order!
  my $out_of_order;
  if(inf_type($min) || inf_type($max)) {
    $out_of_order = $min > $max;
  } elsif( !_is_negative($min) && _is_negative($max) ) {
    $out_of_order = 1;
  } elsif( _is_negative($min) && !_is_negative($max) ) {
    $out_of_order = 0;
  } else { #min and max have same sign
    my $digdiff = length($max)-length($min);
    my $pmin = $digdiff > 0 ? _pad($min, $digdiff)  : $min;
    my $pmax = $digdiff < 0 ? _pad($max, -$digdiff) : $max;
    $out_of_order = _is_negative($max) ? $pmin lt $pmax : $pmin gt $pmax;
  }

  if( $out_of_order ) {
    die "min($min) > max($max) (autoswap option not specified)"  if  !$opts->{autoswap};
    ($min, $max) = ($max, $min);
  }

  return bless { min => $min, max => $max, opts => $opts,
                 base => $base, base_max => $base_max,
                 base_digits => $base_digits, base_digits_regex => $base_digits_regex,
               }, $class;
}

sub to_string {
  my ($self, $passed_opts) = @_;
  if( $self->{min} eq $self->{max} ) {
    return $self->{min};
  # the prefer_comma option is dangerous because if you read in 3,4
  # you don't get 3..4, but instead 3..3,4..4 which requires collapsing
  #} elsif($self->{min}+$opts->{prefer_comma} >= $self->{max}) {
  } else {
    return "$self->{min}..$self->{max}";
  }
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $self->{opts}, $passed_opts );

  $self->{tranges} ||= [ $self->_calculate_tranges() ];

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator, map { $_->regex( $opts ) } @{$self->{tranges}};
  $regex_str    = " $regex_str "  if  $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my ($min, $max) = ($self->{min}, $self->{max});
    my $comment = "Number::Range::Regex::SimpleRange[$min..$max]";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }
  $regex_str = "(?:$regex_str)"  if  @{$self->{tranges}} != 1;

  return qr/$begin_comment_maybe$modifier_maybe$regex_str$end_comment_maybe/;
}

sub _calculate_tranges {
  my ($self) = @_;
  my $min = $self->{min};
  my $max = $self->{max};

  if( _is_negative( $min ) && _is_negative( $max ) ) {
    my $pos_sr = __PACKAGE__->new( -$max, -$min );
    my @tranges = $pos_sr->_calculate_tranges();
    @tranges = reverse map { Number::Range::Regex::TrivialRange->new(
                         -$_->{max}, -$_->{min} ) } @tranges;
    return @tranges;
  } elsif( _is_negative( $min ) && !_is_negative( $max ) ) {
    # min..-1, 0..max
    my $pos_lo_sr = __PACKAGE__->new( 1, -$min );
    my @tranges = $pos_lo_sr->_calculate_tranges();
    @tranges = reverse map { Number::Range::Regex::TrivialRange->new(
                         -$_->{max}, -$_->{min}, ) } @tranges;
    push @tranges, __PACKAGE__->new( 0, $max )->_calculate_tranges();
    return @tranges;
  } elsif( !_is_negative( $min ) && _is_negative( $max ) ) {
    die "_calculate_tranges() - internal error - min($min)>=0 but max($max)<0?";
  }
  # if we get here, $min >= 0 and $max >= 0

  if ( $min eq $max ) {
    return Number::Range::Regex::TrivialRange->new( $min, $min );
  }

  if($max == pos_inf) {
    # iterate from $self->{min} up to the next (power of 10) - 1 (e.g. 9999)
    # then spit out a regex for any integer with a longer length
    my $tmp = $self->{base_max} x length $self->{min};
    my $noninf = __PACKAGE__->new($self->{min}, $tmp );
    return ( $noninf->_calculate_tranges(),
             Number::Range::Regex::TrivialRange->new( $tmp+1, pos_inf ) );
  } else {

#    $min-- unless $self->{opts}->{exclusive_min} || $self->{opts}->{exclusive};
#    $max++ unless $self->{opts}->{exclusive_max} || $self->{opts}->{exclusive};
#    warn "WARNING: exclusive ranges untested!" if($self->{opts}->{exclusive_min} || $self->{opts}->{exclusive_max} || $self->{opts}->{exclusive});

    my $digits_diff = length($max)-length($min);
    my $padded_min = ('0' x $digits_diff).$min;

    my $samedigits = 0;
    for my $digit (0..length($max)-1) {
      last unless substr($padded_min, $digit, 1) eq substr($max, $digit, 1);
      $samedigits++;
    }

    my ($rightmost, $leftmost) = (length $max, $samedigits+1);

    my @tranges = ();
    push @tranges,
      $self->_do_range_setting_loop($min, $padded_min, length($max) - length($min), $rightmost,
        [ reverse ($leftmost+1..$rightmost) ],
        sub {
          my ( $digit, $trailer_len, $header ) = @_;
          return ($trailer_len ? base_next($digit, $self->{base_digits}) : $digit, $self->{base_max});
        }
      );

    push @tranges,
      $self->_do_range_setting_loop($min, $padded_min, length($max) - length($min), $rightmost,
        [ $leftmost ],
        sub {
          my ( $digit, $trailer_len, $header ) = @_;
          my $digit_min = $trailer_len ? base_next($digit, $self->{base_digits}) : $digit; #inclusive in ones column only!
          my $digit_max = substr($max, length($header), 1);
          $digit_max = base_prev($digit_max, $self->{base_digits})  if  $trailer_len;
          return ($digit_min, $digit_max);
        }
      );

    push @tranges,
      $self->_do_range_setting_loop($max, $max, 0, $rightmost,
        [ ($leftmost+1)..$rightmost ],
        sub {
          my ( $digit, $trailer_len, $header ) = @_;
          return (0, $trailer_len ? base_prev($digit, $self->{base_digits}) : $digit);
        }
      );

    return @tranges;
  }
}

sub _do_range_setting_loop {
  my ($self, $string_base, $padded_string_base, $string_offset,
      $rightmost, $digit_pos_range, $digit_range_sub) = @_;

  my @ranges = ();
  foreach my $digit_pos (@$digit_pos_range) {
    my $pos = $digit_pos - $string_offset - 1;
    my $static_header = $pos < 0 ? "" : substr($string_base, 0, $pos);
    my $trailer_len = $rightmost - $digit_pos;

    my $digit = substr($padded_string_base, $digit_pos-1, 1);

    my ($digit_min, $digit_max) = $digit_range_sub->( $digit, $trailer_len, $static_header );

    my $digit_range = _calculate_digit_range( $digit_min, $digit_max, $self->{base_digits} );
    next  unless  defined $digit_range;

    my $range_min = $static_header.$digit_min.(0 x $trailer_len);
    my $range_max = $static_header.$digit_max.($self->{base_max} x $trailer_len);
    push @ranges, Number::Range::Regex::TrivialRange->new(
                      $range_min, $range_max );
  }
  return @ranges;
}

sub intersection {
  my ($self, $other) = @_;

  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->intersection( $other );
  }
  my ($lower, $upper) = _order_by_min( $self, $other );
  if( $upper->{min} <= $lower->{max} ) {
    return $upper  if  $upper->{max} <= $lower->{max};
    return __PACKAGE__->new( $upper->{min}, $lower->{max} );
  } else {
    return empty_set();
  }
}

sub union {
  my $opts = option_mangler( ref $_[-1] eq 'HASH' ? pop : undef );
  my ($self, @other) = @_;
#warn "sr::u, wo: $opts->{warn_overlap}, $self, @other";
  return multi_union( $self, @other )  if  @other > 1;
  my $other = shift @other;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->union( $other );
  }
  my ($lower, $upper) = _order_by_min( $self, $other );
  if( $upper->{min} < $lower->{max}+1 ) {
    if( $opts->{warn_overlap} ) {
      my $overlap = __PACKAGE__->new( $upper->{min}, $lower->{max} );
      my $subname = $opts->{warn_overlap} eq '1' ? 'union' : $opts->{warn_overlap};
      warn "$subname call got overlap: ".$overlap->to_string();
    }
    # NOTE: this is more complicated than it probably should be: we preserve
    # the original object if we can, so if it's a TR, it stays a TR.
    # we don't actually seem to need that, although we have tests for it.
    if( $lower->{max} >= $upper->{max} ) {
      return $lower;
    } else {
      return __PACKAGE__->new( $lower->{min}, $upper->{max} );
    }
  } elsif( $upper->{min} == $lower->{max}+1 ) {
    return __PACKAGE__->new( $lower->{min}, $upper->{max} );
  } else { #$upper->{min} > $lower->{max}+1
    return Number::Range::Regex::CompoundRange->new( $lower, $upper );
  }
}

sub subtract {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->subtract( $other);
  }
  return $self  unless  $self->touches($other);

  if( $self->{min} < $other->{min} ) {
    if( $self->{max} <= $other->{max} ) {
      # e.g. (1..7)-(3..11) = (1..2)
      # e.g. (1..11)-(3..11) = (1..2)
      return __PACKAGE__->new( $self->{min}, $other->{min}-1 );
    } else {
      # e.g. (1..7)-(2..6) = (1, 7)
      my $r1 = __PACKAGE__->new( $self->{min}, $other->{min}-1 );
      my $r2 = __PACKAGE__->new( $other->{max}+1, $self->{max} );
      return $r1->union( $r2 );
    }
  } else {
    if( $self->{max} <= $other->{max} ) {
      # e.g. (1..7)-(1..11) = ()
      # e.g. (1..7)-(1..7) = ()
      return empty_set();
    } else {
      # e.g. (1..7)-(1..4) = (5..7)
      return __PACKAGE__->new( $other->{max}+1, $self->{max} );
    }
  }
}

sub xor {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->xor( $other );
  }
  return $self->union($other)  unless  $self->touches($other);

  if( $self->{min} == $other->{min} ) {
    if( $self->{max} < $other->{max} ) {
      # e.g. (1..7)xor(1..11) = (8..11)
      return __PACKAGE__->new( $self->{max}+1, $other->{max} );
    } elsif($self->{max} == $other->{max}) {
      # e.g. (1..11)xor(1..11) = ()
      return empty_set( $self->{opts} );
    } else {
      # e.g. (1..7)xor(1..6) = (7)
      return __PACKAGE__->new( $other->{max}+1, $self->{max} );
    }
  } else {
    my ($lower, $upper) = _order_by_min( $self, $other );
    if($lower->{max} < $upper->{max}) {
      # e.g. (1..7)xor(3..11) = (1..2, 8..11)
      my $r1 = __PACKAGE__->new( $lower->{min}, $upper->{min}-1 );
      my $r2 = __PACKAGE__->new( $lower->{max}+1, $upper->{max} );
      return $r1->union( $r2 );
    } elsif($lower->{max} == $upper->{max}) {
      # e.g. (1..11)xor(3..11) = (1..2)
      return __PACKAGE__->new( $lower->{min}, $upper->{min}-1 );
    } else {
      # e.g. (1..7)xor(3..6) = (1..2, 7)
      my $r1 = __PACKAGE__->new( $lower->{min}, $upper->{min}-1 );
      my $r2 = __PACKAGE__->new( $upper->{max}+1, $lower->{max} );
      return $r1->union( $r2 );
    }
  }
}

sub invert {
  my ($self) = @_;
  my @r;
  if($self->{min} != neg_inf) {
    push @r, __PACKAGE__->new( neg_inf, $self->{min}-1 );
  }
  if($self->{max} != pos_inf) {
    push @r, __PACKAGE__->new( $self->{max}+1, pos_inf );
  }
  return multi_union( @r );
}

sub overlaps {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    if(!$other->isa( 'Number::Range::Regex::SimpleRange') ) {
      return 1  if  $other->overlaps($self);
    } else {
      die "other argument is not a simple range (try swapping your args)"  unless  $other->isa('Number::Range::Regex::SimpleRange');
      my ($lower, $upper) = _order_by_min( $self, $other );
      return 1  if  $upper->{min} <= $lower->{max};
    }
  }
  return;
}

sub touches {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    if(!$other->isa( 'Number::Range::Regex::SimpleRange') ) {
      return 1  if  $other->touches($self);
    } else {
      die "other argument is not a simple range (try swapping your args)"  unless  $other->isa('Number::Range::Regex::SimpleRange');
      my ($lower, $upper) = _order_by_min( $self, $other );
      return 1  if  $upper->{min} <= $lower->{max}+1;
    }
  }
  return;
}

sub contains {
  my ($self, $n) = @_;
  return ($n >= $self->{min}) && ($n <= $self->{max});
}

sub has_lower_bound { my ($self) = @_; return $self->{min} != neg_inf; }
sub has_upper_bound { my ($self) = @_; return $self->{max} != pos_inf; }

sub is_infinite {
  my ($self) = @_;
  return !( $self->has_lower_bound && $self->has_upper_bound );
}

sub is_empty { return; }

1;

