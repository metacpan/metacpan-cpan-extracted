# Number::Range::Regex::Util::inf
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Util::inf;

# why don't we use perl's "support" for inf?
# 1) behaves in various different ways between 5.6.X where X <= 1
#    5.6.Y where Y >= 2, 5.8.X where X <= 7, and 5.8.Y where Y >= 8
# 2) it's annoying - you can't implement a function inf() because of
#    perl's desire to look like a shell script. because of this,
#    -inf is interpreted as a bareword so you can say dumb(-foo => bar);
#    but +inf and inf generate errors about barewords. you can't simply
#    "fix" that by adding a sub inf { return 'inf' }; because that
#    generates warnings about -inf being ambiguous between the literal
#    '-inf' and -&inf(); in caller context.
# 3) it is only supported if the underlying libc supports it
# 4) it depends on the underlying libc's definition of the string
#    version of infinity, which on win32 is '1.#INF', solaris
#    'Infinity', and libc 'inf'

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw ( pos_inf neg_inf );
@EXPORT_OK = qw ( inf_type _cmp _is_negative _pad );
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

$VERSION = '0.32';

use overload '<=>' => \&_cmp, # also defines <, <=, ==, !=, >=, >
             '+'   => \&_add, # with neg, also defines non-unary -
             'neg' => \&_neg, # unary minus
             'eq'  => \&_eq,  # string equality check, always returns false
             '""'  => sub { my $self = shift; return $$self };

sub pos_inf { my $v = '+inf'; return bless \$v, __PACKAGE__; }
sub neg_inf { my $v = '-inf'; return bless \$v, __PACKAGE__; }

# returns -1 if this is neg_inf, 0 if this is non-infinite, 1 if pos_inf
sub inf_type {
  my ($val) = @_;
  my $str_val = "$val";
  return $str_val eq '-inf' ? -1 : $str_val eq '+inf' ? 1 : 0;
}

sub _neg {
  my ($val) = @_;
  return pos_inf  if  inf_type($val) == -1;
  return neg_inf;  # inf_type($val) == 1 # if we're not -inf, we're +inf
}

# we can't do numberic comparisons because of non-base-10 support,
# and we don't want to stringify when we can avoid it
sub _is_negative {
  my ($val) = @_;
  my $inf_type = inf_type($val);
  return $inf_type ? $inf_type == -1 : $val =~ /^-/;
}

# usage: _pad( $value, $num_extra_leading_zeroes );
sub _pad {
  my ($val, $extra) = @_;
  return $val  if  inf_type($val);
  return $val =~ s/^-// ? '-'.(0 x $extra).$val : (0 x $extra).$val;
}

# for our purposes, -inf!=-inf, and +inf!=+inf
sub _eq { return }

sub _add {
  my ($a, $b, $swapped) = @_;
  # note: the case of 2 non-infinite numbers never gets here, so the
  # below is accurate
  die "neg_inf + pos_inf is undefined"  if  0 == inf_type($a) + inf_type($b);
  # some infinite value k + any value that is not the opposite of itself = k
  return $a;
}

sub _cmp {
  my ($l, $r, $swapped) = @_;
  ($l, $r) = ($r, $l)  if  $swapped;
  # note: the below would be wrong for the case of 2 non-infinite numbers,
  # (inf_type($l) == inf_type($r) == 0), but we never check the overloaded
  # _cmp() in that case, as both $l and $r are non-overloaded & non-infinite
  return inf_type($l) <=> inf_type($r);
}

1;
