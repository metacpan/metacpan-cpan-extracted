#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::CCS::Utils;

our @EXPORT_OK = qw(nnz nnza ccs_encode_pointers ccs_decode_pointer ccs_xindex1d ccs_xindex2d ccs_dump_which );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '1.24.1';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::CCS::Utils $VERSION;






#line 13 "ccsutils.pd"


#use PDL::CCS::Config;
use strict;

=pod

=head1 NAME

PDL::CCS::Utils - Low-level utilities for compressed storage sparse PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Utils;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut
#line 46 "Utils.pm"






=head1 FUNCTIONS

=cut




#line 52 "ccsutils.pd"

*ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices (deprecated)
#line 63 "Utils.pm"



#line 70 "ccsutils.pd"


=pod

=head1 Non-missing Value Counts

=cut
#line 75 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 nnz

=for sig

  Signature: (a(N); indx [o]nnz())

Get number of non-zero values in a PDL $a();
For 1d PDLs, should be equivalent to:

 $nnz = nelem(which($a!=0));

For k>1 dimensional PDLs, projects via number of nonzero elements
to N-1 dimensions by computing the number of nonzero elements
along the the 1st dimension.



=for bad

The output PDL $nnz() never contains BAD values.

=cut
#line 105 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*nnz = \&PDL::nnz;
#line 112 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 nnza

=for sig

  Signature: (a(N); eps(); indx [o]nnz())

Like nnz() using tolerance constant $eps().
For 1d PDLs, should be equivalent to:

 $nnz = nelem(which(!$a->approx(0,$eps)));



=for bad

The output PDL $nnz() never contains BAD values.

=cut
#line 138 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*nnza = \&PDL::nnza;
#line 145 "Utils.pm"



#line 156 "ccsutils.pd"


=pod

=head1 Encoding Utilities

=cut
#line 157 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_encode_pointers

=for sig

  Signature: (indx ix(Nnz); indx N(); indx [o]ptr(Nplus1); indx [o]ixix(Nnz))

General CCS encoding utility.

Get a compressed storage "pointer" vector $ptr
for a dimension of size $N with non-missing values at indices $ix.  Also returns a vector
$ixix() which may be used as an index for $ix() to align its elements with $ptr()
along the compressed dimension.

The induced vector $ix-E<gt>index($ixix) is
guaranteed to be stably sorted along dimension $N():

 \forall $i,$j with 1 <= $i < $j <= $Nnz :

  $ix->index($ixix)->at($i) < $ix->index($ixix)->at($j)   ##-- primary sort on $ix()
 or
  $ixix->at($i)             < $ixix->at($j)               ##-- ... stable



=for bad

ccs_encode_pointers does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 196 "Utils.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


    sub PDL::ccs_encode_pointers {
      my ($ix,$N,$ptr,$ixix) = @_;
      barf("Usage: ccs_encode_pointers(ix(Nnz), N(), [o]ptr(N+1), [o]ixix(Nnz)") if (!defined($ix));
      &PDL::_ccs_encode_pointers_int($ix, ($N // $ix->max+1), ($ptr //= null), ($ixix //= null));
      return ($ptr,$ixix);
    }
  
#line 210 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_encode_pointers = \&PDL::ccs_encode_pointers;
#line 217 "Utils.pm"



#line 239 "ccsutils.pd"


=pod

=head1 Decoding Utilities

=cut
#line 229 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_decode_pointer

=for sig

  Signature: (indx ptr(Nplus1); indx proj(Nproj); indx [o]projix(NnzProj); indx [o]nzix(NnzProj); PDL_Indx nnzProj)

General CCS decoding utility.

Project indices $proj() from a compressed storage "pointer" vector $ptr().
If unspecified, $proj() defaults to:

 sequence($ptr->dim(0) - 1)



=for bad

ccs_decode_pointer does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 259 "Utils.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


    sub PDL::ccs_decode_pointer {
      my ($ptr,$proj,$projix,$nzix,$nnzproj) = @_;
      barf("Usage: ccs_decode_pointer(ptr(N+1), proj(Nproj), [o]projix(NnzProj), [o]nzix(NnzProj), NnzProj?")
        if (!defined($ptr));
      if (!defined($proj)) {
        $proj    = PDL->sequence(ccs_indx(), $ptr->dim(0)-1);
        $nnzproj //= $ptr->at(-1);
      }
      $projix //= null;
      $nzix //= null;
      $nnzproj //= ($projix->isnull && $nzix->isnull
                    ? ($ptr->index($proj+1)-$ptr->index($proj))->sum
                    : -1);
      return (null,null) if (!$nnzproj);
      &PDL::_ccs_decode_pointer_int($ptr,$proj, $projix,$nzix, $nnzproj);
      return ($projix,$nzix);
    }
  
#line 284 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_decode_pointer = \&PDL::ccs_decode_pointer;
#line 291 "Utils.pm"



#line 311 "ccsutils.pd"


=pod

=head1 Indexing Utilities

=cut
#line 303 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_xindex1d

=for sig

  Signature: (indx which(Ndims,Nnz); indx a(Na); indx [o]nzia(NnzA); indx [o]nnza(); PDL_Indx sizeNnzA)

Compute indices $nzai() along dimension C<Nnz> of $which() whose initial values $which(0,$nzai)
match some element of $a().  Appropriate for indexing a sparse encoded PDL
with non-missing entries at $which()
along the 0th dimension, a la L<dice_axis(0,$a)|PDL::Slices/dice_axis>.
$which((0),) and $a() must be both sorted in ascending order.

In list context, returns a list ($nzai,$nnza), where $nnza() is the number of indices found,
and $nzai are those C<Nnz> indices.  In scalar context, trims the output vector $nzai() to $nnza()
elements.



=for bad

ccs_xindex1d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 336 "Utils.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


    sub PDL::ccs_xindex1d {
      my ($which,$a,$nzia,$nnza) = @_;
      barf("Usage: ccs_xindex2d(which(Ndims,Nnz), a(Na), [o]nzia(NnzA), [o]nnza()")
        if ((grep {!defined($_)} @_[0..1]) || $which->ndims < 2 || $which->dim(0) < 1);
      $nzia //= null;
      $nnza //= null;
      &PDL::_ccs_xindex1d_int($which,$a,$nzia,$nnza, ($nnza ? $nnza->sclr : -1));
      return wantarray ? ($nzia,$nnza) : $nzia->reshape($nnza->sclr);
    }
  
#line 353 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_xindex1d = \&PDL::ccs_xindex1d;
#line 360 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_xindex2d

=for sig

  Signature: (indx which(Ndims,Nnz); indx a(Na); indx b(Nb); indx [o]ab(Nab); indx [o]nab())

Compute indices along dimension C<NNz> of $which() corresponding to any combination
of values in the Cartesian product of $a() and $b().  Appropriate for indexing a
2d sparse encoded PDL with non-missing entries at $which() via the ND-index piddle
$a-E<gt>slice("*1,")-E<gt>cat($b)-E<gt>clump(2)-E<gt>xchg(0,1), i.e. all pairs $ai,$bi with $ai in $a()
and $bi in $b().  $a() and $b() values must be be sorted in ascending order

In list context, returns a list ($ab,$nab), where $nab() is the number of indices found,
and $ab are those C<Nnz> indices.  In scalar context, trims the output vector $ab() to $nab()
elements.



=for bad

ccs_xindex2d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 393 "Utils.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


    sub PDL::ccs_xindex2d {
      my ($which,$a,$b,$ab,$nab) = @_;
      barf("Usage: ccs_xindex2d(which(2,Nnz), a(Na), b(Nb), [o]nab(), [o]ab(Nab)")
        if ((grep {!defined($_)} @_[0..2]) || $which->ndims != 2 || $which->dim(0) < 2);
      &PDL::_ccs_xindex2d_int($which,$a,$b, ($ab//=null), ($nab//=null));
      return wantarray ? ($ab,$nab) : $ab->reshape($nab->sclr);
    }
  
#line 408 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_xindex2d = \&PDL::ccs_xindex2d;
#line 415 "Utils.pm"



#line 487 "ccsutils.pd"


=pod

=head1 Debugging Utilities

=cut
#line 427 "Utils.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_dump_which

=for sig

  Signature: (indx which(Ndims,Nnz); SV *HANDLE; char *fmt; char *fsep; char *rsep)

Print a text dump of an index PDL to the filehandle C<HANDLE>, which default to C<STDUT>.
C<$fmt> is a printf() format to use for output, which defaults to "%td".
C<$fsep> and C<$rsep> are field-and record separators, which default to
a single space and C<$/>, respectively.



=for bad

ccs_dump_which does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 455 "Utils.pm"



#line 950 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"


    sub PDL::ccs_dump_which {
      my ($which,$fh,$fmt,$fsep,$rsep) = @_;
      $fmt  = '%td'  if (!defined($fmt)  || $fmt eq '');
      $fsep = " "   if (!defined($fsep) || $fsep eq '');
      $rsep = "$/"  if (!defined($rsep) || $rsep eq '');
      $fh = \*STDOUT if (!defined($fh));
      &PDL::_ccs_dump_which_int($which,$fh,$fmt,$fsep,$rsep);
    }
  
#line 471 "Utils.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_dump_which = \&PDL::ccs_dump_which;
#line 478 "Utils.pm"



#line 558 "ccsutils.pd"


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
#line 526 "Utils.pm"






# Exit with OK status

1;
