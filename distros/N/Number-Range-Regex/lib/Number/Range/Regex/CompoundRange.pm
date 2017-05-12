# Number::Range::Regex::CompoundRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::CompoundRange;

use strict;

use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION );
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.32';

use Number::Range::Regex::Util;
use Number::Range::Regex::Util::inf qw ( neg_inf pos_inf );

sub new {
  my $opts = option_mangler( ref $_[-1] eq 'HASH' ? pop : undef );
  my ($class, @ranges) = @_;
  # TODO: do we need to collapse&sort the ranges? either by calling
  # multi_union (which has a collapsing effect) or by an explicit sort
  # by min + verify no overlaps + _collapse_ranges ?
  return bless { ranges => [ @ranges ], opts => $opts }, $class;
}

sub to_string {
  my ($self, $passed_opts) = @_;
  return join(',', map { $_->to_string() } @{$self->{ranges}});
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $self->{opts}, $passed_opts );

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str;
  if(@{$self->{ranges}}) {
    $regex_str = join $separator, map { $_->regex( { %$opts, comment => 0 } ) } @{$self->{ranges}};
  } else {
    $regex_str = '(?!)'; # never matches
  }
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my $comment = "Number::Range::Regex::CompoundRange[".$self->to_string."]";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }
  return qr/(?:$begin_comment_maybe$modifier_maybe(?:$regex_str)$end_comment_maybe)/;
}

sub _do_unequal_min {
#warn "in _do_unequal_min";
  my ($self, $lower, $upper, $ptr, $ranges) = @_;
  if( $lower->{max} > $upper->{max} ) {
    # 3 ranges, last of which may yet overlap
    my $r1 = Number::Range::Regex::SimpleRange->new( $lower->{min}, $upper->{min}-1 );
    my $r2 = $upper;
    my $r3 = Number::Range::Regex::SimpleRange->new( $upper->{max}+1, $lower->{max} );
#warn "l: $lower->{min}..$lower->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max},$r3->{min}..$r3->{max}";
    splice( @$ranges, $$ptr, 1, ($r1, $r2, $r3) );
    $$ptr += 2; # $r3 may overlap something else
  } elsif( $lower->{max} >= $upper->{min} ) {
    # 2 ranges, latter of which may yet overlap
    my $r1 = Number::Range::Regex::SimpleRange->new( $lower->{min}, $upper->{min}-1 );
    my $r2 = Number::Range::Regex::SimpleRange->new( $upper->{min}, $lower->{max} );
#warn "l: $lower->{min}..$lower->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
    splice( @$ranges, $$ptr, 1, ($r1, $r2 ) );
    $$ptr += 1;
  } else { # $lower->{max} < $upper->{min}
    # 1 range, no overlap
#warn "l: $lower->{min}..$lower->{max} is ok";
    $$ptr++;
  }
}

sub sectionify {
  my ($self, $other) = @_;

  my @s_ranges = @{$self->{ranges}};
  my @o_ranges = $other->isa('Number::Range::Regex::CompoundRange') ? @{$other->{ranges}} :
                 $other->isa('Number::Range::Regex::SimpleRange') ? ( $other ) :
                 die "other is neither a simple nor compound range!";

#warn "s_ranges1: ".join ",", map { "$_->{min}..$_->{max}" } @s_ranges;
#warn "o_ranges1: ".join ",", map { "$_->{min}..$_->{max}" } @o_ranges;

  # munge ranges so that there are no partial overlaps - only
  # non-overlaps and complete overlaps e.g:
  #   if s=(6..12) and o=(7..13):
  #      s=(6,7..12) and o=(7..12,13);
  #   if s=(6..12) and o=(7..9):
  #      s=(6,7..9,10..12) and o=(7..9);
  my ($s_ptr, $o_ptr) = (0, 0);
  while( ($s_ptr < @s_ranges) && ($o_ptr < @o_ranges) ) {
#warn "s_ranges: @s_ranges, o_ranges: @o_ranges";
    my $this_s = $s_ranges[$s_ptr];
    my $this_o = $o_ranges[$o_ptr];
#warn "checking this_s: $this_s->{min}..$this_s->{max}, this_o: $this_o->{min}..$this_o->{max}";
    if( $this_s->{min} < $this_o->{min} ) {
#printf STDERR "l==s, ";
      $self->_do_unequal_min($this_s, $this_o, \$s_ptr, \@s_ranges );
    } elsif( $this_s->{min} > $this_o->{min} ) {
#printf STDERR "l==o, ";
      $self->_do_unequal_min($this_o, $this_s, \$o_ptr, \@o_ranges );
    } else { # $this_s->{min} == $this_o->{min}
      if( $this_s->{max} < $this_o->{max} ) {
        # 2 ranges, latter of which may yet overlap
        my $r1 = $this_s;
        my $r2 = Number::Range::Regex::SimpleRange->new($this_s->{max}+1, $this_o->{max} );
        splice( @o_ranges, $o_ptr, 1, ($r1, $r2) );
#warn "o: $this_o->{min}..$this_o->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
        $o_ptr++; # $r2 may overlap something else
      } elsif( $this_s->{max} > $this_o->{max} ) {
        # 2 ranges, latter of which may yet overlap
        my $r1 = $this_o;
        my $r2 = Number::Range::Regex::SimpleRange->new($this_o->{max}+1, $this_s->{max} );
        splice( @s_ranges, $s_ptr, 1, ($r1, $r2) );
#warn "s: $this_s->{min}..$this_s->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
        $s_ptr++; # $r2 may overlap something else
      } else { # $this_s->{max} == $this_o->{min}
        # 1 range, no overlap
#warn "s/o: $this_o->{min}..$this_o->{max} is ok";
        $s_ptr++;
        $o_ptr++;
      }
    }
  }

#warn "s_ranges2: ".join ",", map { "$_->{min}..$_->{max}" } @s_ranges;
#warn "o_ranges2: ".join ",", map { "$_->{min}..$_->{max}" } @o_ranges;

  my $sections;
  ($s_ptr, $o_ptr) = (0, 0);
  while( ($s_ptr < @s_ranges) && ($o_ptr < @o_ranges) ) {
    my $this_s = $s_ranges[$s_ptr];
    my $this_o = $o_ranges[$o_ptr];
    if( $this_s->{min} < $this_o->{min} ) {
      push @{$sections->{just_self}}, $this_s;
      push @{$sections->{in_either}}, $this_s;
      $s_ptr++;
    } elsif( $this_o->{min} < $this_s->{min} ) {
      push @{$sections->{just_other}}, $this_o;
      push @{$sections->{in_either}}, $this_o;
      $o_ptr++;
    } else { # $this_s->{min} == $this_o->{min}
      die "internal error in sectionify"  unless  $this_s->{max} == $this_o->{max};
      push @{$sections->{in_both}}, $this_s;
      push @{$sections->{in_either}}, $this_s;
      $s_ptr++;
      $o_ptr++;
    }
  }
  if( $o_ptr < @o_ranges ) {
    push @{$sections->{just_other}}, @o_ranges[$o_ptr..$#o_ranges];
    push @{$sections->{in_either}},  @o_ranges[$o_ptr..$#o_ranges];
  } elsif( $s_ptr < @s_ranges ) {
    push @{$sections->{just_self}},  @s_ranges[$s_ptr..$#s_ranges];
    push @{$sections->{in_either}},  @s_ranges[$s_ptr..$#s_ranges];
  }

#warn "just_self: ".join ",", map { "$_->{min}..$_->{max}" } @{$sections->{just_self}};
#warn "in_both: ".join ",", map { "$_->{min}..$_->{max}" } @{$sections->{in_both}};
#warn "in_either: ".join ",", map { "$_->{min}..$_->{max}" } @{$sections->{in_either}};
#warn "just_other: ".join ",", map { "$_->{min}..$_->{max}" } @{$sections->{just_other}};

  return $sections;
}


sub intersection {
  my ($self, $other) = @_;
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{in_both}} );
}

sub subtract {
  my ($self, $other) = @_;
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{just_self}} );
}

sub xor {
  my ($self, $other) = @_;
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{just_self}}, @{$sections->{just_other}} );
}

sub invert {
  my ($self) = @_;
  my @included = @{$self->{ranges}};
  return Number::Range::Regex::SimpleRange->new( neg_inf, pos_inf ) unless @included;
  my @excluded = ();
  if($included[0]->{min} != neg_inf ) {
    push @excluded, Number::Range::Regex::SimpleRange->new( neg_inf, $included[0]->{min}-1 );
  }
  for(my $c=1; $c<@included; ++$c) {
    my $last = $included[$c-1];
    my $this = $included[$c];
    if($last->{max}+1 > $this->{min}-1) {
      die "internal error - overlapping SRs?";
    } else {
      push @excluded, Number::Range::Regex::SimpleRange->new( $last->{max}+1, $this->{min}-1 );
    }
  }
  if($included[-1]->{max} != pos_inf) {
    push @excluded, Number::Range::Regex::SimpleRange->new( $included[-1]->{max}+1, pos_inf );
  }
  return __PACKAGE__->new( @excluded );
}

sub union {
  my $opts = option_mangler( ref $_[-1] eq 'HASH' ? pop : undef );
  my ($self, @other) = @_;
#warn "cr::u, wo: $opts->{warn_overlap}, $self, @other";
  return multi_union( $self, @other )  if  @other > 1;
  my $sections = $self->sectionify( $other[0] );
  if( $opts->{warn_overlap} && $sections->{in_both} && @{ $sections->{in_both} } ) {
    my $subname = $opts->{warn_overlap} eq '1' ? 'union' : $opts->{warn_overlap};
    warn "$subname call got overlap(s): ", join ",", @{ $sections->{in_both} };
  }
  my @in_either = _collapse_ranges( @{$sections->{in_either}} );
  if( @in_either == 0 ) {
    return empty_set();
  } elsif( @in_either == 1 ) {
    return $in_either[0];
  } else {
    return __PACKAGE__->new( @in_either );
  }
}

sub _collapse_ranges {
  my @ranges = @_;
  my $last_r;
  my $this_r = $ranges[0];
  for (my $rpos = 1; $rpos < @ranges; $rpos++ ) {
    $last_r = $this_r;
    $this_r = $ranges[$rpos];
    if($last_r->touches($this_r)) {
      $this_r = $last_r->union( $this_r );
      splice(@ranges, $rpos-1, 2, $this_r);
      $rpos--;
    }
  }
  return @ranges;
}

#sub _is_contiguous {
#  my ($self) = @_;
#  my $last_r;
#  my $this_r = $self->{ranges}->[0];
#  for (my $rpos = 1; $rpos < @{$self->{ranges}}; $rpos++ ) {
#    $last_r = $this_r;
#    $this_r = $self->{ranges}->[$rpos];
#    return  if  $last_r->{max}+1 < $this_r->{min};
#  }
#  return ($self->{ranges}->[0]->{min}, $self->{ranges}->[-1]->{max});
#}

sub contains {
  my ($self, $n) = @_;
  foreach my $r (@{$self->{ranges}}) {
    return 1  if  $r->contains( $n );
  }
  return;
}

sub is_empty {
  my ($self) = @_;
  return !@{$self->{ranges}};
}

sub has_lower_bound {
  my ($self) = @_;
  return  if  $self->is_empty;
  return $self->{ranges}->[0]->has_lower_bound;
}

sub has_upper_bound {
  my ($self) = @_;
  return  if  $self->is_empty;
  return $self->{ranges}->[-1]->has_upper_bound;
}

sub is_infinite {
  my ($self) = @_;
  return  if  $self->is_empty;
  return ! ( $self->{ranges}->[0]->has_lower_bound && $self->{ranges}->[-1]->has_upper_bound );
}

1;

