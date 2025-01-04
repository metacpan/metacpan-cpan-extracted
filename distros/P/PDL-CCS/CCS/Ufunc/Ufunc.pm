#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::CCS::Ufunc;

our @EXPORT_OK = qw(ccs_accum_prod ccs_accum_dprod ccs_accum_sum ccs_accum_dsum ccs_accum_or ccs_accum_and ccs_accum_bor ccs_accum_band ccs_accum_maximum ccs_accum_minimum ccs_accum_maximum_nz_ind ccs_accum_minimum_nz_ind ccs_accum_nbad ccs_accum_ngood ccs_accum_nnz ccs_accum_average );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '1.24.1';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::CCS::Ufunc $VERSION;






#line 13 "ccsufunc.pd"


=pod

=head1 NAME

PDL::CCS::Ufunc - Ufuncs for compressed storage sparse PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Ufunc;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut
#line 43 "Ufunc.pm"






=head1 FUNCTIONS

=cut




#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated product over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 106 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_prod {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_prod_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 129 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_prod = \&PDL::ccs_accum_prod;
#line 136 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated double-precision product over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 189 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_dprod {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_dprod_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 212 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_dprod = \&PDL::ccs_accum_dprod;
#line 219 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated sum over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 272 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_sum {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_sum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 295 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_sum = \&PDL::ccs_accum_sum;
#line 302 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated double-precision sum over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 355 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_dsum {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_dsum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 378 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_dsum = \&PDL::ccs_accum_dsum;
#line 385 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated logical "or" over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 435 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_or {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_or_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 458 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_or = \&PDL::ccs_accum_or;
#line 465 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated logical "and" over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 515 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_and {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_and_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 538 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_and = \&PDL::ccs_accum_and;
#line 545 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated bitwise "or" over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 595 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_bor {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_bor_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 618 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_bor = \&PDL::ccs_accum_bor;
#line 625 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated bitwise "and" over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 675 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_band {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_band_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 698 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_band = \&PDL::ccs_accum_band;
#line 705 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated maximum over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 756 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_maximum {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_maximum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 779 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_maximum = \&PDL::ccs_accum_maximum;
#line 786 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated minimum over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 837 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_minimum {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_minimum_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 860 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_minimum = \&PDL::ccs_accum_minimum;
#line 867 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated maximum_nz_ind over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 915 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_maximum_nz_ind {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_maximum_nz_ind_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 938 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_maximum_nz_ind = \&PDL::ccs_accum_maximum_nz_ind;
#line 945 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated minimum_nz_ind over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 993 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_minimum_nz_ind {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_minimum_nz_ind_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 1016 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_minimum_nz_ind = \&PDL::ccs_accum_minimum_nz_ind;
#line 1023 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_accum_nbad

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


Accumulated number of bad values over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1071 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_nbad {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_nbad_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 1094 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_nbad = \&PDL::ccs_accum_nbad;
#line 1101 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated number of good values over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1149 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_ngood {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_ngood_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 1172 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_ngood = \&PDL::ccs_accum_ngood;
#line 1179 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated number of non-zero values over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1227 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_nnz {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_nnz_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 1250 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_nnz = \&PDL::ccs_accum_nnz;
#line 1257 "Ufunc.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



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


Accumulated average over values $nzvalsIn() associated with non-missing vector-valued keys $ixIn().
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1310 "Ufunc.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


        sub PDL::ccs_accum_average {
          my ($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut) = @_;
          $nOut //= PDL->null;
          $ixOut //= PDL->null;
          $nzvalsOut //= PDL->null;
          &PDL::_ccs_accum_average_int($ixIn,$nzvalsIn, $missing,$N, $ixOut,$nzvalsOut,$nOut);
          ##
          ##-- auto-trim
          my $trim_slice = "0:".($nOut->max-1);
          $ixOut     = $ixOut->slice(",$trim_slice");
          $nzvalsOut = $nzvalsOut->slice($trim_slice);
          ##
          ##-- return
          return wantarray ? ($ixOut,$nzvalsOut,$nOut) : $nzvalsOut;
        }
    
#line 1333 "Ufunc.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_accum_average = \&PDL::ccs_accum_average;
#line 1340 "Ufunc.pm"



#line 558 "ccsufunc.pd"


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
#line 1372 "Ufunc.pm"



#line 594 "ccsufunc.pd"


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

Copyright (C) 2007-2024, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl)

=cut
#line 1420 "Ufunc.pm"






# Exit with OK status

1;
