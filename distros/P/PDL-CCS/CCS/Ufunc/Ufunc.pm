#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::CCS::Ufunc;

our @EXPORT_OK = qw(ccs_accum_prod ccs_accum_dprod ccs_accum_sum ccs_accum_dsum ccs_accum_or ccs_accum_and ccs_accum_bor ccs_accum_band ccs_accum_maximum ccs_accum_minimum ccs_accum_maximum_nz_ind ccs_accum_minimum_nz_ind ccs_accum_nbad ccs_accum_ngood ccs_accum_nnz ccs_accum_average );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '1.23.22';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::CCS::Ufunc $VERSION;







#line 13 "ccsufunc.pd"

#use PDL::CCS::Version;
use strict;

=pod

=head1 NAME

PDL::CCS::Ufunc - Ufuncs for compressed storage sparse PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Ufunc;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut
#line 46 "Ufunc.pm"

=head1 FUNCTIONS

=cut





#line 58 "ccsufunc.pd"

*ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices
#line 59 "Ufunc.pm"

=head2 ccs_accum_prod

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated product over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, then the quantity:

 $missing ** ($N - (rlevec($ixIn))[0])

is multiplied into $nzvalsOut: this is probably What You Want if you are computing the product over a virtual
dimension in a sparse index-encoded PDL (see PDL::CCS::Nd for a wrapper class).

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_prod processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_prod {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_prod_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_prod = \&PDL::ccs_accum_prod;






=head2 ccs_accum_dprod

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    double [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated double-precision product over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, then the quantity:

 $missing ** ($N - (rlevec($ixIn))[0])

is multiplied into $nzvalsOut: this is probably What You Want if you are computing the product over a virtual
dimension in a sparse index-encoded PDL (see PDL::CCS::Nd for a wrapper class).

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_dprod processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_dprod {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes((PDL::double()), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_dprod_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_dprod = \&PDL::ccs_accum_dprod;






=head2 ccs_accum_sum

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated sum over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, then the quantity:

 $missing * ($N - (rlevec($ixIn))[0])

is added to $nzvalsOut: this is probably What You Want if you are summing over a virtual
dimension in a sparse index-encoded PDL (see PDL::CCS::Nd for a wrapper class).

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_sum processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_sum {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_sum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_sum = \&PDL::ccs_accum_sum;






=head2 ccs_accum_dsum

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    double [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated double-precision sum over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, then the quantity:

 $missing * ($N - (rlevec($ixIn))[0])

is added to $nzvalsOut: this is probably What You Want if you are summing over a virtual
dimension in a sparse index-encoded PDL (see PDL::CCS::Nd for a wrapper class).

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_dsum processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_dsum {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes((PDL::double()), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_dsum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_dsum = \&PDL::ccs_accum_dsum;






=head2 ccs_accum_or

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated logical "or" over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, $missing() is logically (or)ed
into each result value at each output index with a run length of less than $N() in $ixIn().
This is probably What You Want.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_or processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_or {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_or_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_or = \&PDL::ccs_accum_or;






=head2 ccs_accum_and

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated logical "and" over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, $missing() is logically (and)ed
into each result value at each output index with a run length of less than $N() in $ixIn().
This is probably What You Want.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_and processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_and {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_and_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_and = \&PDL::ccs_accum_and;






=head2 ccs_accum_bor

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated bitwise "or" over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, $missing() is bitwise (or)ed
into each result value at each output index with a run length of less than $N() in $ixIn().
This is probably What You Want.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_bor processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_bor {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   $nzvalsIn = longlong($nzvalsIn) if ($nzvalsIn->type > longlong()); ##-- max_type_perl=longlong
   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_bor_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_bor = \&PDL::ccs_accum_bor;






=head2 ccs_accum_band

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated bitwise "and" over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, $missing() is bitwise (and)ed
into each result value at each output index with a run length of less than $N() in $ixIn().
This is probably What You Want.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_band processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_band {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   $nzvalsIn = longlong($nzvalsIn) if ($nzvalsIn->type > longlong()); ##-- max_type_perl=longlong
   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_band_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_band = \&PDL::ccs_accum_band;






=head2 ccs_accum_maximum

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated maximum over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero,
and if $missing() is greater than any listed value for a vector key with a run-length
of less than $N(), then $missing() is used as the output value for that key.
This is probably What You Want.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_maximum processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_maximum {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_maximum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_maximum = \&PDL::ccs_accum_maximum;






=head2 ccs_accum_minimum

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
       [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated minimum over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero,
and if $missing() is less than any listed value for a vector key with a run-length
of less than $N(), then $missing() is used as the output value for that key.
This is probably What You Want.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_minimum processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_minimum {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_minimum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_minimum = \&PDL::ccs_accum_minimum;






=head2 ccs_accum_maximum_nz_ind

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    indx [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated maximum_nz_ind over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

Output indices index $nzvalsIn, -1 indicates that the missing value is maximal.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_maximum_nz_ind processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_maximum_nz_ind {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes((ccs_indx()), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_maximum_nz_ind_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_maximum_nz_ind = \&PDL::ccs_accum_maximum_nz_ind;






=head2 ccs_accum_minimum_nz_ind

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    indx [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated minimum_nz_ind over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

Output indices index $nzvalsIn, -1 indicates that the missing value is minimal.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_minimum_nz_ind processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_minimum_nz_ind {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes((ccs_indx()), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_minimum_nz_ind_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_minimum_nz_ind = \&PDL::ccs_accum_minimum_nz_ind;






=head2 ccs_accum_nbad

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    int+ [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated number of bad values over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

Should handle missing values appropriately.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_nbad processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_nbad {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   $nzvalsIn = ccs_indx($nzvalsIn) if ($nzvalsIn->type > ccs_indx()); ##-- max_type_perl=ccs_indx
   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_nbad_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_nbad = \&PDL::ccs_accum_nbad;






=head2 ccs_accum_ngood

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    indx [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated number of good values over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

Should handle missing values appropriately.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_ngood processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_ngood {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   $nzvalsIn = ccs_indx($nzvalsIn) if ($nzvalsIn->type > ccs_indx()); ##-- max_type_perl=ccs_indx
   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_ngood_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_ngood = \&PDL::ccs_accum_ngood;






=head2 ccs_accum_nnz

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    indx [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated number of non-zero values over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

Should handle missing values appropriately.

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_nnz processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_nnz {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   $nzvalsIn = longlong($nzvalsIn) if ($nzvalsIn->type > longlong()); ##-- max_type_perl=longlong
   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_nnz_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_nnz = \&PDL::ccs_accum_nnz;






=head2 ccs_accum_average

=for sig

  Signature: (
    indx ixIn(Ndims,NnzIn);
    nzvalsIn(NnzIn);
    missing();
    indx N();
    indx [o]ixOut(Ndims,NnzOut);
    float+ [o]nzvalsOut(NnzOut);
    indx [o]nOut();
    )

Accumulated average over values $nzvalsIn() associated with vector-valued keys $ixIn().
On return,
$ixOut() holds the unique non-"missing" values of $ixIn(),
$nzvalsOut() holds the associated values,
and
$nOut() stores the number of unique non-missing values computed.

If $N() is specified and greater than zero, then the quantity:

 $missing * ($N - (rlevec($ixIn))[0]) / $N

is added to $nzvalsOut: this is probably What You Want if you are averaging over a virtual
dimension in a sparse index-encoded PDL (see PDL::CCS::Nd for a wrapper class).

Returned PDLs are implicitly sliced such that NnzOut==$nOut().

In scalar context, returns only $nzvalsOut().

=for bad

ccs_accum_average processes bad values.
The state of the bad-value flag of the output ndarrays is unknown.

=cut





 sub PDL::ccs_accum_average {
   my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
   my ($ndims,@nnzIn) = $ixIn->dims;
   my (@nnzOut);
   if (defined($ixOut)) {
     @nnzOut = $ixOut->dims;
     shift(@nnzOut);
   }

   @nnzOut = $nzvalsOut->dims if (!@nnzOut && defined($nzvalsOut) && !$nzvalsOut->isempty);
   @nnzOut = @nnzIn           if (!@nnzOut);
   $ixOut  = PDL->zeroes(ccs_indx(), $ndims,@nnzOut)
     if (!defined($ixOut)      || $ixOut->isempty);

   $nzvalsOut = PDL->zeroes(($nzvalsIn->type), @nnzOut)
     if (!defined($nzvalsOut) || $nzvalsOut->isempty);

   $nOut = PDL->pdl(ccs_indx(),0)                  if (!defined($nOut) || $nOut->isempty);
   ##
   ##-- guts
   &PDL::_ccs_accum_average_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
   ##
   ##-- auto-trim
   $ixOut      = $ixOut->slice(",0:".($nOut->max-1));
   $nzvalsOut  = $nzvalsOut->slice("0:".($nOut->max-1));
   ##
   ##-- return
   return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
 }



*ccs_accum_average = \&PDL::ccs_accum_average;





#line 615 "ccsufunc.pd"

=pod

=head1 TODO / NOT YET IMPLEMENTED

=over 4

=item extrema indices

maximum_ind, minimum_ind: not quite compatible...

=item statistical aggregates

daverage, medover, oddmedover, pctover, ...

=item cumulative functions

cumusumover, cumuprodover, ...

=item other stuff

zcover, intover, minmaximum

=back

=cut

#line 651 "ccsufunc.pd"
##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

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

=head2 Copyright Policy

Copyright (C) 2007-2022, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl)

=cut
#line 1405 "Ufunc.pm"

# Exit with OK status

1;
