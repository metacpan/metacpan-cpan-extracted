
require 5;
package Number::Latin;
$VERSION = '1.01';   # Time-stamp: "2001-02-22 16:43:53 MST"
@ISA = ('Exporter');
@EXPORT = ('int2latin', 'int2Latin', 'int2LATIN', 'latin2int');
use strict;
use integer;
require Exporter;

#---------------------------------------------------------------------------
sub int2latin ($) {
  return undef unless defined $_[0];
  return '0' if $_[0] == 0;
  return '-' . _i2l( abs int $_[0] ) if $_[0] <= -1;
  return       _i2l(     int $_[0] );
}

sub int2Latin ($) {
  # just the above plus ucfirst
  return undef unless defined $_[0];
  return '0' if $_[0] == 0;
  return '-' . ucfirst(_i2l( abs int $_[0] )) if $_[0] <= -1;
  return       ucfirst(_i2l(     int $_[0] ));
}

sub int2LATIN ($) {
  # just the above plus uc
  return undef unless defined $_[0];
  return '0' if $_[0] == 0;
  return '-' . uc(_i2l( abs int $_[0] )) if $_[0] <= -1;
  return       uc(_i2l(     int $_[0] ));
}

{
  my @alpha = ('a' .. 'z'); 

  sub _i2l { # the real work
    my $int = shift(@_) || return "";
    _i2l(int (($int - 1) / 26)) . $alpha[$int % 26 - 1];  # yes, recursive
  }
}

#---------------------------------------------------------------------------
sub latin2int ($);
sub latin2int ($) {
  return undef unless defined $_[0];
  return 0 if $_[0] eq '0' or $_[0] =~ m/^0+$/s; # special case
  my $in = $_[0];
  return scalar(-latin2int($1)) if $in =~ m<^-([a-zA-Z]+)$>s;
  return undef unless $_[0] =~ m<^[a-zA-Z]+$>s;
  $in =~ tr/A-Z/a-z/;
  _l2i($in);
}

# use Number::Latin; print ">\n"; print latin2int('aaa'), "\n";

sub _l2i {  # the real work.  DESTRUCTIVE to $_[0]
  #print "<$_[0]> => ";
  my $sval = ord(
                 # my $x =
                 chop($_[0])
                ) - ord('a') + 1;
  #print "sval: $x=>$sval leaving <$_[0]>\n";
  (length $_[0]) ? ($sval + 26 * _l2i($_[0])) : $sval;  # yes, recursive
}

#---------------------------------------------------------------------------
1;

__END__

=head1 NAME

Number::Latin -- convert to/from the number system "a,b,...z,aa,ab..."

=head1 SYNOPSIS

  use Number::Latin;
  print join(' ', map int2latin($_), 1 .. 30), "\n";
   #
   # Prints:
   #  a b c d e f g h i j k l m n o p q r s t u v w x y z aa ab ac ad

=head1 DESCRIPTION

Some applications, notably the numbering of points in outlines, use a
scheme that starts with the letter "a", goes to "z", and then starts
over with "aa" thru "az", then "ba", and so on.  (The W3C refers to
this numbering system as "lower-latin"/"upper-latin" or "lower
alpha"/"upper alpha", in discussions of HTML/CSS options for rendering
of list elements (OL/LI).)

This module provides functions that deal with that numbering system,
converting between it and integer values.

=head2 FUNCTIONS

This module exports four functions, C<int2latin>, C<int2Latin>,
C<int2LATIN>, and C<latin2int>:

=over

=item $latin = int2latin( INTEGER )

This returns the INTEGERth item in the sequence
C<('a' .. 'z', 'aa', 'ab', etc)>.
For example, C<int2latin(1)> is C<"a">, 
C<int2latin(2)> is C<"b">, C<int2latin(26)> is C<"z">, 
C<int2latin(30)> is C<"ad">, and so for any nonzero integer.

=item $latin = int2Latin( INTEGER )

This is just like C<int2latin>, except that the return value is has
an initial capital.  E.g., C<int2Latin(30)> is C<"Ad">.

=item $latin = int2LATIN( INTEGER )

This is just like C<int2latin>, except that the return value is in
all uppercase.  E.g., C<int2LATIN(30)> is C<"AD">.

=item $latin = latin2int( INTEGER )

This converts back from latin number notation (regardless of
capitalization!) to an integer value.  E.g., C<latin2int("ad")> is 30.

=back

=head1 NOTES

The latin numbering system is not to be confused with Roman numerals,
in spite of their names.

The latin numbering system isn't a normal base-N number system (thus
making this module necessary), as evidenced by the fact that the item
after "z" is "aa".  If you considered this to be a base-26 numbering
system (running from a-z for 0-25), then after "z" would be "ba"; if
you considered it a base-27 numbering system (running from a-z for
1-26), then after "z" would be "a" followed by some sort of
placeholder zero.  But it's neither.

I vaguely remember reading, years ago, of some languages (in New
Guinea?) with count-number systems that work like the latin number
system -- i.e., where either the number after "nine" is "one-MULT
one", or the number after "ten" is "one-MULT one".  However, I haven't
been able to find a reference for exactly what language(s) those were
number system; I welcome email on the subject.

=head1 COPYRIGHT

Copyright (c) 1997- by Abigail, and 2001- Sean M. Burke.  All rights
reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Roman>

C<http://www.w3.org/TR/REC-CSS2/generate.html#lists>

C<http://people.netscape.com/ftang/i18n.html>

C<http://people.netscape.com/ftang/number/draft.html>

=head1 AUTHOR

Initial implementation in a C<comp.lang.perl.misc> post by Abigail
(C<abigail@foad.org>) in 1997.  Documentation, further doings,
and current maintenance by Sean M. Burke, C<sburke@cpan.org>

=cut

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# First implemention by Abigail (abigail@foad.org):
sub decimal_to_string ($);
sub decimal_to_string ($) {
  my $decimal = shift or return "";
  decimal_to_string (int (($decimal - 1) / 26)) .
    ('a' .. 'z') [$decimal % 26 - 1];
}
 
sub string_to_decimal ($);
sub string_to_decimal ($) {
  my $string = shift or return 0;
  ord (chop $string) - ord ('a') + 1 + 26 * string_to_decimal ($string);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Test case:
use Number::Latin;
my($c1, $c2);
foreach (0 .. 29000) {
  $c1 = orig_int2lat($_);
  $c2 = int2latin($_);
  printf "% 6s %s %s %s\n", $_, $c1,$c2 if $c1 ne $c2;
}

print "Done.\n";
# (passes)


# MY ORIGINAL IMPLEMENTATION:
my(@alpha);
BEGIN { @alpha = ('a' .. 'z'); }
sub orig_int2lat {
  my($v, $pref, $out);
  return '0' if 0 == ($v = $_[0]); # special case
  if($v < 0) { # a nasty case that we'll tolerate
    $v = abs($v);
    $pref = '-';
    $out = '';
  } else {
    $out = $pref = '';
  }

  {
    if(--$v < 26) {  # ...and that's why this makes no sense, but WORKS!
      return scalar($pref . $alpha[$v % 26] . $out);
    } else {
      $out = $alpha[$v % 26] . $out;
      $v = int($v / 26);
      redo;
    }
  }
  # So: 1=a, 26=z, 27=aa, ... 52=az, 53=ba, ... 702=zz, 703=aaa...
  #  18278=zzz, 18279=aaaa
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Other test case -- make sure numbers round-trip.
use Number::Latin;
my($lat, $int);
for (0 .. 300) {
  print "$_ => $lat => $int\n"
    unless $_ == ($int = latin2int($lat = int2latin($_)));
}
print "Done.\n";
# Passes.

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use Number::Latin;  print latin2int('zzzz');
