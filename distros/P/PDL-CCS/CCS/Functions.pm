## File: PDL::CCS::Functions.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: useful perl-level functions for PDL::CCS

package PDL::CCS::Functions;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Utils;
use PDL::VectorValued;
use PDL;
use strict;

my @ccs_binops = qw(
  plus minus mult divide modulo power
  gt ge lt le eq ne spaceship
  and2 or2 xor shiftleft shiftright
);

our $VERSION = '1.23.28'; ##-- update with perl-reversion from Perl::Version module
our @ISA = ('PDL::Exporter');
our @EXPORT_OK =
  (
   ##
   ##-- Decoding
   qw(ccs_decode), #ccs_pointerlen
   ##
   ##-- Vector Operations (compat)
   qw(ccs_binop_vector_mia),
   (map "ccs_${_}_vector_mia", @ccs_binops),
   ##
   ##-- qsort
   qw(ccs_qsort),
  );

our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );


##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS::Functions - Useful perl-level functions for PDL::CCS

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Functions;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut


##======================================================================
## Decoding
=pod

=head1 Decoding

=cut

##-- DEPRECATED STEALTH METHOD: formerly a PDL::PP function in PDL::CCS::Utils
#*PDL::ccs_pointerlen = \&ccs_pointerlen;
sub ccs_pointerlen :lvalue {
  my ($ptr,$len) = @_;
  if (!defined($len)) {
    $len = $ptr->slice("1:-1") - $ptr->slice("0:-2");
  } else {
    $len .= $ptr->slice("1:-1");
    $len -= $ptr->slice("0:-2");
  }
  return $len;
}


##---------------------------------------------------------------
## Decoding: generic
=pod

=head2 ccs_decode

=for sig

  Signature: (indx whichnd(Ndims,Nnz); nzvals(Nnz); missing(); \@Dims; [o]a(@Dims))

Decode a CCS-encoded matrix (no dataflow).

=cut

;#-- emacs

*PDL::ccs_decode = \&ccs_decode;
sub ccs_decode  :lvalue {
  my ($aw,$nzvals,$missing,$dims,$a) = @_;
  $missing = $PDL::undefval if (!defined($missing));
  if (!defined($dims)) {
    barf("PDL::CCS::ccs_decode(): whichnd() is empty; you must specify \@Dims!") if ($aw->isempty);
    $dims = [ map {$aw->slice("($_),")->max+1} (0..($aw->dim(0)-1))];
  }
  $a    = zeroes($nzvals->type, @$dims) if (!defined($a));
  $a   .= $missing;

  (my $tmp=$a->indexND($aw)) .= $nzvals; ##-- CPAN tests puke here with "Can't modify non-lvalue subroutine call" in 5.15.x (perl bug #107366)

  ##-- workaround for missing empty pdl support in PDL 2.4.10 release candidates (pdl bug #3462924), fixed in 2.4.9_993
  #$a->indexND($aw) .= $nzvals if (!$nzvals->isempty);
  #if (!$nzvals->isempty) {
  #  my $tmp = $a->indexND($aw);
  #  $tmp .= $nzvals;
  #}

  return $a;
}

##======================================================================
## Scalar Operations
=pod

=head1 Scalar Operations

Scalar operations can be performed in parallel directly on C<$nzvals>
(and if applicable on C<$missing> as well):

 $c = 42;

 $nzvals2 = $nzvals  + $c;        $missing2 = $missing  + $c;
 $nzvals2 = $nzvals  - $c;        $missing2 = $missing  - $c;
 $nzvals2 = $nzvals  * $c;        $missing2 = $missing  * $c;
 $nzvals2 = $nzvals  / $c;        $missing2 = $missing  / $c;

 $nzvals2 = $nzvals ** $c;        $missing2 = $missing ** $c;
 $nzvals2 = log($nzvals);         $missing2 = log($missing);
 $nzvals2 = exp($nzvals);         $missing2 = exp(missing);

 $nzvals2 = $nzvals->and2($c,0);  $missing2 = $missing->and($c,0);
 $nzvals2 = $nzvals->or2($c,0);   $missing2 = $missing->or2($c,0);
 $nzvals2 = $nzvals->not();       $missing2 = $missing->not();

Nothing prevents scalar operations from producing new "missing" values (e.g. $nzvals*0),
so you might want to re-encode your compressed data after applying the operation.

=cut


##======================================================================
## Vector Operations
=pod

=head1 Vector Operations

=head2 ccs_OP_vector_mia

=for sig

  Signature: (indx whichDimV(Nnz); nzvals(Nnz); vec(V); [o]nzvals_out(Nnz))

A number of row- and column-vector operations may be performed directly
on encoded Nd-PDLs, without the need for decoding to a (potentially huge)
dense temporary.  These operations assume that "missing" values are
annihilators with respect to the operation in question, i.e.
that it holds for all C<$x> in C<$vec> that:

 ($missing __OP__ $x) == $missing

This is in line with the usual PDL semantics if your C<$missing> value is C<BAD>,
but may produce unexpected results when e.g. adding a vector to a sparse PDL with C<$missing>==0.
If you really need to do something like the latter, then you're probably better off decoding to
a dense PDL anyway.

Predefined function names for encoded-PDL vector operations are all of the form:
C<ccs_${OPNAME}_ma>, where ${OPNAME} is the base name of the operation:

 plus       ##-- addition
 minus      ##-- subtraction
 mult       ##-- multiplication (NOT matrix-multiplication)
 divide     ##-- division
 modulo     ##-- modulo
 power      ##-- potentiation

 gt         ##-- greater-than
 ge         ##-- greater-than-or-equal
 lt         ##-- less-than
 le         ##-- less-than-or-equal
 eq         ##-- equality
 ne         ##-- inequality
 spaceship  ##-- 3-way comparison

 and2       ##-- binary AND
 or2        ##-- binary OR
 xor        ##-- binary XOR
 shiftleft  ##-- left-shift
 shiftright ##-- right-shift

=head2 \&CODE = ccs_binop_vector_mia($opName, \&PDLCODE);

Returns a generic vector-operation subroutine which reports errors as C<$opName>
and uses \&PDLCODE to perform underlying computation.

=cut

##======================================================================
## Vector Operations: Generic

*PDL::ccs_binop_vector_mia = \&ccs_binop_vector_mia;
sub ccs_binop_vector_mia {
  my ($opName,$pdlCode) = @_;
  return sub :lvalue {
    my ($wi, $nzvals_in, $vec) = @_;
    my $tmp = $pdlCode->($nzvals_in, $vec->index($wi), 0); # $tmp for perl -d
  };
}

for (@ccs_binops) {
  no strict 'refs';
  *{"PDL::ccs_${_}_vector_mia"} = *{"ccs_${_}_vector_mia"} = ccs_binop_vector_mia($_, PDL->can($_));
}

##======================================================================
## Sorting
=pod

=head1 Sorting

=head2 ccs_qsort

=for sig

  Signature: (indx which(Ndims,Nnz); nzvals(Nnz); missing(); Dim0(); indx [o]nzix(Nnz); indx [o]nzenum(Nnz))

Underlying guts for PDL::CCS::Nd::qsort() and PDL::CCS::Nd::qsorti().
Given a set of $Nnz items $i each associated with a vector-key C<$which(:,$i)>
and a value C<$nzvals($i)>, returns a vector of $Nnz item indices C<$nzix()>
such that C<$which(:,$nzix)> is vector-sorted in ascending order and
C<$nzvals(:,$nzix)> are sorted in ascending order for each unique key-vector in
C<$which()>, and an enumeration C<$nzenum()> of items for each unique key-vector
in terms of the sorted data: C<$nzenum($j)> is the logical position of the item
C<$nzix($j)>.

If C<$missing> and C<$Dim0> are defined,
items C<$i=$nzix($j)> with values C<$nzvals($i) E<gt> $missing>
will be logically enumerated at the end of the range [0,$Dim0-1]
and there will be a gap between C<$nzenum()> values for a C<$which()>-key
with fewer than $Dim0 instances; otherwise $nzenum() values will be
enumerated in ascending order starting from 0.

For an unsorted index+value dataset C<($which0,$nzvals0)> with

 ($nzix,$nzenum) = ccs_qsort($which0("1:-1,"),$nzvals0,$missing,$which0("0,")->max+1)

qsort() can be implemented as:

 $which  = $nzenum("*1,")->glue(0,$which0("1:-1,")->dice_axis(1,$nzix));
 $nzvals = $nzvals0->index($nzix);

and qsorti() as:

 $which  = $nzenum("*1,")->glue(0,$which0("1:-1,")->dice_axis(1,$nzix));
 $nzvals = $which0("(0),")->index($nzix);

=cut

## $bool = _checkdims(\@dims1,\@dims2,$label);  ##-- match      @dims1 ~ @dims2
## $bool = _checkdims( $pdl1,   $pdl2,$label);  ##-- match $pdl1->dims ~ $pdl2->dims
sub _checkdims {
  #my ($dims1,$dims2,$label) = @_;
  #my ($pdl1,$pdl2,$label) = @_;
  my $d0 = UNIVERSAL::isa($_[0],'PDL') ? pdl(ccs_indx(),$_[0]->dims) : pdl(ccs_indx(),$_[0]);
  my $d1 = UNIVERSAL::isa($_[1],'PDL') ? pdl(ccs_indx(),$_[1]->dims) : pdl(ccs_indx(),$_[0]);
  barf(__PACKAGE__ . "::_checkdims(): dimension mismatch for ".($_[2]||'pdl').": $d0!=$d1")
    if (($d0->nelem!=$d1->nelem) || !all($d0==$d1));
  return 1;
}

sub ccs_qsort {
  my ($which,$nzvals, $missing,$dim0, $nzix,$nzenum) = @_;

  ##-- prepare: $nzix
  $nzix = zeroes(ccs_indx(),$nzvals->dims) if (!defined($nzix));
  $nzix->reshape($nzvals) if ($nzix->isempty);
  _checkdims($nzvals,$nzix,'ccs_qsort: nzvals~nzix');
  ##
  ##-- prepare: $nzenum
  $nzenum = zeroes(ccs_indx(),$nzvals->dims) if (!defined($nzenum));
  $nzenum->reshape($nzvals) if ($nzenum->isempty);
  _checkdims($nzenum,$nzvals,'ccs_qsort: nzvals~nzenum');

  ##-- collect and sort base data (unsorted indices + values)
  my $vdata = $which->glue(0,$nzvals->slice("*1,"));
  $vdata->vv_qsortveci($nzix);

  ##-- get logical enumeration
  if (!defined($missing) || !defined($dim0)) {
    ##-- ... flat enumeration
    $which->dice_axis(1,$nzix)->enumvec($nzenum);
  } else {
    ##-- ... we have $missing and $dim0: split enumeration around $missing()
    my $whichx  = $which->dice_axis(1,$nzix);
    my $nzvalsx = $nzvals->index($nzix);
    my ($nzii_l,$nzii_r) = which_both($nzvalsx <= $missing);
    #$nzenum .= -1; ##-- debug
    $whichx->dice_axis(1,$nzii_l)->enumvec($nzenum->index($nzii_l)) if (!$nzii_l->isempty); ##-- enum: <=$missing
    if (!$nzii_r->isempty) {
      ##-- enum: >$missing
      my $nzenum_r = $nzenum->index($nzii_r);
      $whichx->dice_axis(1,$nzii_r)->slice(",-1:0")->enumvec($nzenum_r->slice("-1:0"));
      $nzenum_r *= -1;
      $nzenum_r += ($dim0-1);
    }
  }

  ##-- all done
  return wantarray ? ($nzix,$nzenum) : $nzix;
}


##======================================================================
## Vector Operations: Generic


##======================================================================
## POD: footer
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2007-2024, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1),
PDL(3perl),
PDL::CCS::Nd(3perl),


=cut


1; ##-- make perl happy
