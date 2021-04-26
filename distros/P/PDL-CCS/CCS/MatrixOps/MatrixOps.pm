
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::CCS::MatrixOps;

@EXPORT_OK  = qw( PDL::PP ccs_matmult2d_sdd PDL::PP ccs_matmult2d_zdd PDL::PP ccs_vnorm  ccs_vcos_zdd PDL::PP _ccs_vcos_zdd PDL::PP ccs_vcos_pzd );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::CCS::MatrixOps::VERSION = 1.23.14;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::CCS::MatrixOps $VERSION;





#use PDL::CCS::Version;
use strict;

=pod

=head1 NAME

PDL::CCS::MatrixOps - Low-level matrix operations for compressed storage sparse PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::MatrixOps;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut







=head1 FUNCTIONS



=cut




*ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices




=head2 ccs_matmult2d_sdd

=for sig

  Signature: (
    indx ixa(NdimsA,NnzA); nza(NnzA); missinga();
    b(O,M);
    zc(O);
    [o]c(O,N)
    )


Two-dimensional matrix multiplication of a sparse index-encoded PDL
$a() with a dense pdl $b(), with output to a dense pdl $c().

The sparse input PDL $a() should be passed here with 0th
dimension "M" and 1st dimension "N", just as for the
built-in PDL::Primitive::matmult().

"Missing" values in $a() are treated as $missinga(), which shouldn't
be BAD or infinite, but otherwise ought to be handled correctly.
The input pdl $zc() is used to pass the cached contribution of
a $missinga()-row ("M") to an output column ("O"), i.e.

 $zc = ((zeroes($M,1)+$missinga) x $b)->flat;

$SIZE(Ndimsa) is assumed to be 2.


=for bad

ccs_matmult2d_sdd does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ccs_matmult2d_sdd = \&PDL::ccs_matmult2d_sdd;





=head2 ccs_matmult2d_zdd

=for sig

  Signature: (
    indx ixa(Ndimsa,NnzA); nza(NnzA);
    b(O,M);
    [o]c(O,N)
    )


Two-dimensional matrix multiplication of a sparse index-encoded PDL
$a() with a dense pdl $b(), with output to a dense pdl $c().

The sparse input PDL $a() should be passed here with 0th
dimension "M" and 1st dimension "N", just as for the
built-in PDL::Primitive::matmult().

"Missing" values in $a() are treated as zero.
$SIZE(Ndimsa) is assumed to be 2.


=for bad

ccs_matmult2d_zdd does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ccs_matmult2d_zdd = \&PDL::ccs_matmult2d_zdd;





=head2 ccs_vnorm

=for sig

  Signature: (
    indx acols(NnzA); avals(NnzA);
    float+ [o]vnorm(M);
    ; int sizeM=>M)


Computes the Euclidean lengths of each column-vector $a(i,*) of a sparse index-encoded pdl $a()
of logical dimensions (M,N), with output to a dense piddle $vnorm().
"Missing" values in $a() are treated as zero,
and $acols() specifies the (unsorted) indices along the logical dimension M of the corresponding non-missing
values in $avals().
This is basically the same thing as:

 $vnorm = ($a**2)->xchg(0,1)->sumover->sqrt;

... but should be must faster to compute for sparse index-encoded piddles.



=for bad

ccs_vnorm() always clears the bad-status flag on $vnorm().

=cut






*ccs_vnorm = \&PDL::ccs_vnorm;




=pod

=head2 ccs_vcos_zdd

=for sig

  Signature: (
    indx ixa(2,NnzA); nza(NnzA);
    b(N);
    float+ [o]vcos(M);
    float+ [t]anorm(M);
    int sizeM=>M;
  )


Computes the vector cosine similarity of a dense row-vector $b(N) with respect to each column $a(i,*)
of a sparse index-encoded PDL $a() of logical dimensions (M,N), with output to a dense piddle
$vcos(M).
"Missing" values in $a() are treated as zero,
and magnitudes for $a() are passed in the optional parameter $anorm(), which will be implicitly
computed using L<ccs_vnorm|/ccs_vnorm> if the $anorm() parameter is omitted or empty.
This is basically the same thing as:

 $anorm //= ($a**2)->xchg(0,1)->sumover->sqrt;
 $vcos    = ($a * $b->slice("*1,"))->xchg(0,1)->sumover / ($anorm * ($b**2)->sumover->sqrt);

... but should be must faster to compute.

Output values in $vcos() are cosine similarities in the range [-1,1],
except for zero-magnitude vectors which will result in NaN values in $vcos().
If you need non-negative distances, follow this up with a:

 $vcos->minus(1,$vcos,1)
 $vcos->inplace->setnantobad->inplace->setbadtoval(0); ##-- minimum distance for NaN values

to get distances values in the range [0,2].  You can use PDL threading to batch-compute distances for
multiple $b() vectors simultaneously:

  $bx   = random($N, $NB);                   ##-- get $NB random vectors of size $N
  $vcos = ccs_vcos_zdd($ixa,$nza, $bx, $M);  ##-- $vcos is now ($M,$NB)


=for bad

ccs_vcos_zdd() always clears the bad status flag on the output piddle $vcos.

=cut

sub ccs_vcos_zdd {
  my ($ixa,$nza,$b) = @_;
  barf("Usage: ccs_vcos_zdd(ixa, nza, b, vcos?, anorm?, M?)") if (grep {!defined($_)} ($ixa,$nza,$b));

  my ($anorm,$vcos,$M);
  foreach (@_[3..$#_]) {
    if    (!defined($M) && !UNIVERSAL::isa($_,"PDL")) { $M=$_; }
    elsif (!defined($vcos))  { $vcos = $_; }  ##-- compat: pass $vcos() in first
    elsif (!defined($anorm)) { $anorm = $_; }
  }

  ##-- get M
  $M = $vcos->dim(0)  if (!defined($M) && defined($vcos) && !$vcos->isempty);
  $M = $anorm->dim(0) if (!defined($M) && defined($anorm) && !$anorm->isempty);
  $M = $ixa->slice("(0),")->max+1 if (!defined($M));

  ##-- compat: create output piddles, implicitly computing anorm() if required
  $anorm = $ixa->slice("(0),")->ccs_vnorm($nza, $M) if (!defined($anorm) || $anorm->isempty);
  $vcos  = PDL->zeroes($anorm->type, $M, ($b->dims)[1..$b->ndims-1]) if (!defined($vcos) || $vcos->isempty);

  ##-- guts
  $ixa->_ccs_vcos_zdd($nza,$b, $anorm, $vcos);
  return $vcos;
}

*PDL::ccs_vcos_zdd = \&ccs_vcos_zdd;





=head2 _ccs_vcos_zdd

=for sig

  Signature: (
    indx ixa(Two,NnzA); nza(NnzA);
    b(N);
    float+ anorm(M);
    float+ [o]vcos(M);)

=for ref

Guts for L<ccs_vcos_zdd()|/ccs_vcos_zdd>, with slightly different calling conventions.

=for bad

Always clears the bad status flag on the output piddle $vcos.

=cut






*_ccs_vcos_zdd = \&PDL::_ccs_vcos_zdd;





=head2 ccs_vcos_pzd

=for sig

  Signature: (
    indx aptr(Nplus1); indx acols(NnzA); avals(NnzA);
    indx brows(NnzB);                     bvals(NnzB);
    anorm(M);
    float+ [o]vcos(M);)


Computes the vector cosine similarity of a sparse index-encoded row-vector $b() of logical dimension (N)
with respect to each column $a(i,*) a sparse Harwell-Boeing row-encoded PDL $a() of logical dimensions (M,N),
with output to a dense piddle $vcos(M).
"Missing" values in $a() are treated as zero,
and magnitudes for $a() are passed in the obligatory parameter $anorm().
Usually much faster than L<ccs_vcos_zdd()|/ccs_vcos_zdd> if a CRS pointer over logical dimension (N) is available
for $a().


=for bad

ccs_vcos_pzd() always clears the bad status flag on the output piddle $vcos.

=cut






*ccs_vcos_pzd = \&PDL::ccs_vcos_pzd;




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

We should really implement matrix multiplication in terms of
inner product, and have a good sparse-matrix only implementation
of the former.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

All other parts Copyright (C) 2009-2015, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl)

=cut



;



# Exit with OK status

1;

		   