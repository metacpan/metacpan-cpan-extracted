
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::VectorValued::Utils;

@EXPORT_OK  = qw( PDL::PP vv_rlevec PDL::PP vv_rldvec PDL::PP vv_enumvec PDL::PP vv_enumvecg PDL::PP vv_rleseq PDL::PP vv_rldseq PDL::PP vv_vsearchvec PDL::PP vv_cmpvec vv_qsortvec vv_qsortveci PDL::PP vv_union PDL::PP vv_intersect PDL::PP vv_setdiff PDL::PP v_union PDL::PP v_intersect PDL::PP v_setdiff PDL::PP vv_vcos );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::VectorValued::Utils::VERSION = 1.0.22;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::VectorValued::Utils $VERSION;





use strict;

=pod

=head1 NAME

PDL::VectorValued::Utils - Low-level utilities for vector-valued PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::VectorValued::Utils;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut







=head1 FUNCTIONS



=cut





=pod

=head1 Vector-Based Run-Length Encoding and Decoding

=cut





=head2 vv_rlevec

=for sig

  Signature: (c(M,N); indx [o]a(N); [o]b(M,N))

Run-length encode a set of vectors.

Higher-order rle(), for use with qsortvec().

Given set of vectors $c, generate a vector $a with the number of occurrences of each element
(where an "element" is a vector of length $M ocurring in $c),
and a set of vectors $b containing the unique values.
As for rle(), only the elements up to the first instance of 0 in $a should be considered.

Can be used together with clump() to run-length encode "values" of arbitrary dimensions.
Can be used together with rotate(), cat(), append(), and qsortvec() to count N-grams
over a 1d PDL.

See also: PDL::Slices::rle, PDL::Ufunc::qsortvec, PDL::Primitive::uniqvec



=for bad

vv_rlevec does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*vv_rlevec = \&PDL::vv_rlevec;





=head2 vv_rldvec

=for sig

  Signature: (int a(N); b(M,N); [o]c(M,N))

Run-length decode a set of vectors, akin to a higher-order rld().

Given a vector $a() of the number of occurrences of each row, and a set $c()
of row-vectors each of length $M, run-length decode to $c().

Can be used together with clump() to run-length decode "values" of arbitrary dimensions.

See also: PDL::Slices::rld.



=for bad

vv_rldvec does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut




sub PDL::vv_rldvec {
  my ($a,$b,$c) = @_;
  if (!defined($c)) {
# XXX Need to improve emulation of threading in auto-generating c
    my ($rowlen) = $b->dim(0);
    my ($size) = $a->sumover->max;
    my (@dims) = $a->dims;
    shift(@dims);
    $c = $b->zeroes($b->type,$rowlen,$size,@dims);
  }
  &PDL::_vv_rldvec_int($a,$b,$c);
  return $c;
}


*vv_rldvec = \&PDL::vv_rldvec;





=head2 vv_enumvec

=for sig

  Signature: (v(M,N); int [o]k(N))

Enumerate a list of vectors with locally unique keys.

Given a sorted list of vectors $v, generate a vector $k containing locally unique keys for the elements of $v
(where an "element" is a vector of length $M ocurring in $v).

Note that the keys returned in $k are only unique over a run of a single vector in $v,
so that each unique vector in $v has at least one 0 (zero) index in $k associated with it.
If you need global keys, see enumvecg().



=for bad

vv_enumvec does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*vv_enumvec = \&PDL::vv_enumvec;





=head2 vv_enumvecg

=for sig

  Signature: (v(M,N); int [o]k(N))

Enumerate a list of vectors with globally unique keys.

Given a sorted list of vectors $v, generate a vector $k containing globally unique keys for the elements of $v
(where an "element" is a vector of length $M ocurring in $v).
Basically does the same thing as:

 $k = $v->vsearchvec($v->uniqvec);

... but somewhat more efficiently.



=for bad

vv_enumvecg does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*vv_enumvecg = \&PDL::vv_enumvecg;





=head2 vv_rleseq

=for sig

  Signature: (c(N); indx [o]a(N); [o]b(N))

Run-length encode a vector of subsequences.

Given a vector of $c() of concatenated variable-length, variable-offset subsequences,
generate a vector $a containing the length of each subsequence
and a vector $b containing the subsequence offsets.
As for rle(), only the elements up to the first instance of 0 in $a should be considered.

See also PDL::Slices::rle.



=for bad

vv_rleseq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*vv_rleseq = \&PDL::vv_rleseq;





=head2 vv_rldseq

=for sig

  Signature: (int a(N); b(N); [o]c(M))

Run-length decode a subsequence vector.

Given a vector $a() of sequence lengths
and a vector $b() of corresponding offsets,
decode concatenation of subsequences to $c(),
as for:

 $c = null;
 $c = $c->append($b($_)+sequence($a->type,$a($_))) foreach (0..($N-1));

See also: PDL::Slices::rld.



=for bad

vv_rldseq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut




sub PDL::vv_rldseq {
  my ($a,$b,$c) = @_;
  if (!defined($c)) {
    my $size   = $a->sumover->max;
    my (@dims) = $a->dims;
    shift(@dims);
    $c = $b->zeroes($b->type,$size,@dims);
  }
  &PDL::_vv_rldseq_int($a,$b,$c);
  return $c;
}


*vv_rldseq = \&PDL::vv_rldseq;





=head2 vv_vsearchvec

=for sig

  Signature: (find(M); which(M,N); int [o]found())

=for ref

Routine for searching N-dimensional values - akin to vsearch() for vectors.

=for usage

 $found   = vsearchvec($find, $which);
 $nearest = $which->dice_axis(1,$found);

Returns for each row-vector in C<$find> the index along dimension N
of the least row vector of C<$which>
greater or equal to it.
C<$which> should be sorted in increasing order.
If the value of C<$find> is larger
than any member of C<$which>, the index to the last element of C<$which> is
returned.

See also: PDL::Primitive::vsearch().



=for bad

vv_vsearchvec does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*vv_vsearchvec = \&PDL::vv_vsearchvec;




=pod

=head1 Vector-Valued Sorting and Comparison

The following functions are provided for lexicographic sorting of
vectors, rsp. axis indices.   As of PDL::VectorValued v1.0.12, vv_qsortvec() and
vv_qsortveci() are just deprecated aliases for the builtin PDL functions of the same names.
Older versions of this module used a dedicated implementation as a workaround
for a bug in PDL-2.4.3, which has long since been fixed.

=cut





=head2 vv_cmpvec

=for sig

  Signature: (a(N); b(N); int [o]cmp())

=for ref

Lexicographically compare a pair of vectors.



=for bad

vv_cmpvec does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*vv_cmpvec = \&PDL::vv_cmpvec;




=head2 vv_qsortvec

=for sig

  Signature: (a(n,m); [o]b(n,m))


=for ref

Deprecated alias for L<PDL::Ufunc::qsortvec()|PDL::Ufunc/qsortvec>,
which see for details.


=head2 vv_qsortveci

=for sig

  Signature: (a(n,m); indx [o]ix(m))

=for ref

Deprecated alias for L<PDL::Ufunc::qsortveci()|PDL::Ufunc/qsortveci>,
which see for details.

=cut

BEGIN {
  *vv_qsortvec = *PDL::vv_qsortvec = *PDL::qsortvec;
  *vv_qsortveci = *PDL::vv_qsortveci = *PDL::qsortveci;
}




=pod

=head1 Vector-Valued Set Operations

The following functions are provided for set operations on
sorted vector-valued PDLs.

=cut





=head2 vv_union

=for sig

  Signature: (a(M,NA); b(M,NB); [o]c(M,NC); int [o]nc())


Union of two vector-valued PDLs.  Input PDLs $a() and $b() B<MUST> be
sorted in lexicographic order.
On return, $nc() holds the actual number of vector-values in the union.

In scalar context, slices $c() to the actual number of elements in the union
and returns the sliced PDL.




=for bad

vv_union does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::vv_union {
   my ($a,$b,$c,$nc) = @_;
   $c = PDL->null if (!defined($nc));
   $nc = PDL->null if (!defined($nc));
   &PDL::_vv_union_int($a,$b,$c,$nc);
   return ($c,$nc) if (wantarray);
   return $c->slice(",0:".($nc->max-1));
 }


*vv_union = \&PDL::vv_union;





=head2 vv_intersect

=for sig

  Signature: (a(M,NA); b(M,NB); [o]c(M,NC); int [o]nc())


Intersection of two vector-valued PDLs.
Input PDLs $a() and $b() B<MUST> be sorted in lexicographic order.
On return, $nc() holds the actual number of vector-values in the intersection.

In scalar context, slices $c() to the actual number of elements in the intersection
and returns the sliced PDL.



=for bad

vv_intersect does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::vv_intersect {
   my ($a,$b,$c,$nc) = @_;
   $c = PDL->null if (!defined($c));
   $nc = PDL->null if (!defined($nc));
   &PDL::_vv_intersect_int($a,$b,$c,$nc);
   return ($c,$nc) if (wantarray);
   my $nc_max = $nc->max;
   return ($nc_max > 0
	   ? $c->slice(",0:".($nc_max-1))
	   : $c->reshape($c->dim(0), 0, ($c->dims)[2..($c->ndims-1)]));
 }


*vv_intersect = \&PDL::vv_intersect;





=head2 vv_setdiff

=for sig

  Signature: (a(M,NA); b(M,NB); [o]c(M,NC); int [o]nc())


Set-difference ($a() \ $b()) of two vector-valued PDLs.
Input PDLs $a() and $b() B<MUST> be sorted in lexicographic order.
On return, $nc() holds the actual number of vector-values in the computed vector set.

In scalar context, slices $c() to the actual number of elements in the output vector set
and returns the sliced PDL.



=for bad

vv_setdiff does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::vv_setdiff {
  my ($a,$b,$c,$nc) = @_;
  $c = PDL->null if (!defined($c));
  $nc = PDL->null if (!defined($nc));
  &PDL::_vv_setdiff_int($a,$b,$c,$nc);
  return ($c,$nc) if (wantarray);
  my $nc_max = $nc->max;
  return ($nc_max > 0
	  ? $c->slice(",0:".($nc_max-1))
	  : $c->reshape($c->dim(0), 0, ($c->dims)[2..($c->ndims-1)]));
 }


*vv_setdiff = \&PDL::vv_setdiff;




=pod

=head1 Sorted Vector Set Operations

The following functions are provided for set operations on
flat sorted PDLs with unique values.  They may be more efficient to compute
than the corresponding implementations via PDL::Primitive::setops().

=cut





=head2 v_union

=for sig

  Signature: (a(NA); b(NB); [o]c(NC); int [o]nc())


Union of two flat sorted unique-valued PDLs.
Input PDLs $a() and $b() B<MUST> be sorted in lexicographic order and contain no duplicates.
On return, $nc() holds the actual number of values in the union.

In scalar context, reshapes $c() to the actual number of elements in the union and returns it.



=for bad

v_union does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::v_union {
   my ($a,$b,$c,$nc) = @_;
   $c = PDL->null if (!defined($c));
   $nc = PDL->null if (!defined($nc));
   &PDL::_v_union_int($a,$b,$c,$nc);
   return ($c,$nc) if (wantarray);
   return $c->slice("0:".($nc->max-1));
 }


*v_union = \&PDL::v_union;





=head2 v_intersect

=for sig

  Signature: (a(NA); b(NB); [o]c(NC); int [o]nc())


Intersection of two flat sorted unique-valued PDLs.
Input PDLs $a() and $b() B<MUST> be sorted in lexicographic order and contain no duplicates.
On return, $nc() holds the actual number of values in the intersection.

In scalar context, reshapes $c() to the actual number of elements in the intersection and returns it.



=for bad

v_intersect does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::v_intersect {
   my ($a,$b,$c,$nc) = @_;
   $c = PDL->null if (!defined($c));
   $nc = PDL->null if (!defined($nc));
   &PDL::_v_intersect_int($a,$b,$c,$nc);
   return ($c,$nc) if (wantarray);
   my $nc_max = $nc->max;
   return ($nc_max > 0
	   ? $c->slice("0:".($nc_max-1))
	   : $c->reshape(0, ($c->dims)[1..($c->ndims-1)]));
 }


*v_intersect = \&PDL::v_intersect;





=head2 v_setdiff

=for sig

  Signature: (a(NA); b(NB); [o]c(NC); int [o]nc())


Set-difference ($a() \ $b()) of two flat sorted unique-valued PDLs.
Input PDLs $a() and $b() B<MUST> be sorted in lexicographic order and contain no duplicate values.
On return, $nc() holds the actual number of values in the computed vector set.

In scalar context, reshapes $c() to the actual number of elements in the difference set and returns it.



=for bad

v_setdiff does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::v_setdiff {
   my ($a,$b,$c,$nc) = @_;
   $c = PDL->null if (!defined($c));
   $nc = PDL->null if (!defined($nc));
   &PDL::_v_setdiff_int($a,$b,$c,$nc);
   return ($c,$nc) if (wantarray);
   my $nc_max = $nc->max;
   return ($nc_max > 0
	   ? $c->slice("0:".($nc_max-1))
	   : $c->reshape(0, ($c->dims)[1..($c->ndims-1)]));
 }


*v_setdiff = \&PDL::v_setdiff;




=pod

=head1 Miscellaneous Vector-Valued Operations

=cut





=head2 vv_vcos

=for sig

  Signature: (a(M,N);b(M);float+ [o]vcos(N))


Computes the vector cosine similarity of a dense vector $b() with respect to each row $a(*,i)
of a dense PDL $a().  This is basically the same thing as:

 ($a * $b)->sumover / ($a->pow(2)->sumover->sqrt * $b->pow(2)->sumover->sqrt)

... but should be must faster to compute, and avoids allocating potentially large temporaries for
the vector magnitudes.  Output values in $vcos() are cosine similarities in the range [-1,1],
except for zero-magnitude vectors which will result in NaN values in $vcos().

You can use PDL threading to batch-compute distances for multiple $b() vectors simultaneously:

  $bx   = random($M, $NB);   ##-- get $NB random vectors of size $N
  $vcos = vv_vcos($a,$bx);   ##-- $vcos(i,j) ~ sim($a(,i),$b(,j))



=for bad

vv_vcos() will set the bad status flag on the output piddle $vcos() if it is set on either of the input
piddles $a() or $b(), but BAD values will otherwise be ignored for computing the cosine similarity.


=cut






*vv_vcos = \&PDL::vv_vcos;




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Perl by Larry Wall

=item *

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=item *

Code for rlevec() and rldvec() derived from the PDL builtin functions
rle() and rld() in $PDL_SRC_ROOT/Basic/Slices/slices.pd

=back

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Probably many.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>


=head1 COPYRIGHT

=over 4

=item *

Code for qsortvec() copyright (C) Tuomas J. Lukka 1997.
Contributions by Christian Soeller (c.soeller@auckland.ac.nz)
and Karl Glazebrook (kgb@aaoepp.aao.gov.au).  All rights
reserved. There is no warranty. You are allowed to redistribute this
software / documentation under certain conditions. For details, see
the file COPYING in the PDL distribution. If this file is separated
from the PDL distribution, the copyright notice should be included in
the file.


=item *

All other parts copyright (c) 2007-2022, Bryan Jurish.  All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=back


=head1 SEE ALSO

perl(1), PDL(3perl)

=cut



;



# Exit with OK status

1;

		   