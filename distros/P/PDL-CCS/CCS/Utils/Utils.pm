
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::CCS::Utils;

@EXPORT_OK  = qw( PDL::PP nnz PDL::PP nnza PDL::PP ccs_encode_pointers PDL::PP ccs_decode_pointer PDL::PP ccs_pointerlen PDL::PP ccs_xindex1d PDL::PP ccs_xindex2d PDL::PP ccs_dump_which );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::CCS::Utils::VERSION = 1.23.13;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::CCS::Utils $VERSION;





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







=head1 FUNCTIONS



=cut




*ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices



=pod

=head1 Non-missing Value Counts

=cut





=head2 nnz

=for sig

  Signature: (a(N); int+ [o]nnz())

Get number of non-zero values in a PDL $a();
For 1d PDLs, should be equivalent to:

 $nnz = nelem(which($a!=0));

For k>1 dimensional PDLs, projects via number of nonzero elements
to N-1 dimensions by computing the number of nonzero elements
along the the 1st dimension.


=for bad

nnz does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*nnz = \&PDL::nnz;





=head2 nnza

=for sig

  Signature: (a(N); eps(); int+ [o]nnz())

Like nnz() using tolerance constant $eps().
For 1d PDLs, should be equivalent to:

 $nnz = nelem(which(!$a->approx(0,$eps)));


=for bad

nnza does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*nnza = \&PDL::nnza;




=pod

=head1 Encoding Utilities

=cut





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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::ccs_encode_pointers {
   my ($ix,$N,$ptr,$ixix) = @_;
   barf("Usage: ccs_encode_pointers(ix(Nnz), N(), [o]ptr(N+1), [o]ixix(Nnz)") if (!defined($ix));
   $N    = $ix->max()+1                               if (!defined($N));
   $ptr = PDL->zeroes(ccs_indx(), $N+1)              if (!defined($ptr));
   $ixix = PDL->zeroes(ccs_indx(), $ix->dim(0))      if (!defined($ixix));
   &PDL::_ccs_encode_pointers_int($ix,$N,$ptr,$ixix);
   return ($ptr,$ixix);
 }


*ccs_encode_pointers = \&PDL::ccs_encode_pointers;




=pod

=head1 Decoding Utilities

=cut





=head2 ccs_decode_pointer

=for sig

  Signature: (indx ptr(Nplus1); indx proj(Nproj); indx [o]projix(NnzProj); indx [o]nzix(NnzProj))

General CCS decoding utility.

Project indices $proj() from a compressed storage "pointer" vector $proj().
If unspecified, $proj() defaults to:

 sequence($ptr->dim(0))



=for bad

ccs_decode_pointer does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::ccs_decode_pointer {
   my ($ptr,$proj,$projix,$nzix) = @_;
   barf("Usage: ccs_decode_pointer(ptr(N+1), proj(Nproj), [o]projix(NnzProj), [o]nzix(NnzProj)")
     if (!defined($ptr));
   my ($nnzproj);
   if (!defined($proj)) {
     $proj    = PDL->sequence(ccs_indx(), $ptr->dim(0)-1);
     $nnzproj = $ptr->at(-1);
   }
   if (!defined($projix) || !defined($nzix)) {
     $nnzproj = ($ptr->index($proj+1)-$ptr->index($proj))->sum if (!defined($nnzproj));
     return (null,null) if (!$nnzproj);
     $projix  = PDL->zeroes(ccs_indx(), $nnzproj) if (!defined($projix));
     $nzix    = PDL->zeroes(ccs_indx(), $nnzproj) if (!defined($nzix));
   }
   &PDL::_ccs_decode_pointer_int($ptr,$proj,$projix,$nzix);
   return ($projix,$nzix);
 }


*ccs_decode_pointer = \&PDL::ccs_decode_pointer;





=head2 ccs_pointerlen

=for sig

  Signature: (ptr(Nplus1); [o]ptrlen(N))


Get number of non-missing values for each axis value from a CCS-encoded
offset pointer vector $ptr().



=for bad

ccs_pointerlen does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





sub PDL::ccs_pointerlen {
  my ($ptr,$len) = @_;
  $len = zeroes($ptr->type, $ptr->nelem-1) if (!defined($len));
  &PDL::_ccs_pointerlen_int($ptr,$len);
  return $len;
}


*ccs_pointerlen = \&PDL::ccs_pointerlen;




=pod

=head1 Indexing Utilities

=cut





=head2 ccs_xindex1d

=for sig

  Signature: (which(Ndims,Nnz); a(Na); [o]nzia(NnzA); [o]nnza())


Compute indices $nzai() along dimension C<NNz> of $which() whose initial values $which(0,$nzai)
match some element of $a().  Appropriate for indexing a sparse encoded PDL
with non-missing entries at $which()
along the 0th dimension, a la L<dice_axis(0,$a)|PDL::Slices/dice_axis>.
$which((0),) and $a() must be both sorted in ascending order.

In list context, returns a list ($nzai,$nnza), where $nnza() is the number of indices found,
and $nzai are those C<Nnz> indices.  In scalar context, trims the output vector $nzai() to $nnza()
elements.



=for bad

ccs_xindex1d does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::ccs_xindex1d {
   my ($which,$a,$nzia,$nnza) = @_;
   barf("Usage: ccs_xindex2d(which(Ndims,Nnz), a(Na), [o]nzia(NnzA), [o]nnza()")
     if ((grep {!defined($_)} @_[0..1]) || $which->ndims < 2 || $which->dim(0) < 1);
   $nnza = $nzia->dim(0) if (defined($nzia) && !defined($nnza));
   $nnza = $which->dim(1) if (!defined($nnza));
   $nnza = pdl($which->type, $nnza) if (!ref($nnza));
   $nzia  = PDL->zeroes($which->type, $nnza->sclr) if (!defined($nzia));
   &PDL::_ccs_xindex1d_int($which,$a,$nzia,$nnza);
   return ($nzia,$nnza) if (wantarray);
   return $nzia->reshape($nnza->sclr);
 }


*ccs_xindex1d = \&PDL::ccs_xindex1d;





=head2 ccs_xindex2d

=for sig

  Signature: (which(Ndims,Nnz); a(Na); b(Nb); [o]ab(Nab); [o]nab())


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::ccs_xindex2d {
   my ($which,$a,$b,$ab,$nab) = @_;
   barf("Usage: ccs_xindex2d(which(2,Nnz), a(Na), b(Nb), [o]nab(), [o]ab(Nab)")
     if ((grep {!defined($_)} @_[0..2]) || $which->ndims != 2 || $which->dim(0) < 2);
   $nab = $ab->dim(0) if (defined($ab) && !defined($nab));
   if (!defined($nab)) {
     $nab = $a->nelem*$b->nelem;
     $nab = $which->dim(1) if ($which->dim(1)) < $nab;
   }
   $nab = pdl($which->type, $nab) if (!ref($nab));
   $ab = PDL->zeroes($which->type, $nab->sclr) if (!defined($ab));
   &PDL::_ccs_xindex2d_int($which,$a,$b,$ab,$nab);
   return ($ab,$nab) if (wantarray);
   return $ab->reshape($nab->sclr);
 }


*ccs_xindex2d = \&PDL::ccs_xindex2d;




=pod

=head1 Debugging Utilities

=cut





=head2 ccs_dump_which

=for sig

  Signature: (indx which(Ndims,Nnz); SV *HANDLE; char *fmt; char *fsep; char *rsep)


Print a text dump of an index PDL to the filehandle C<HANDLE>, which default to C<STDUT>.
C<$fmt> is a printf() format to use for output, which defaults to "%d".
C<$fsep> and C<$rsep> are field-and record separators, which default to
a single space and C<$/>, respectively.



=for bad

ccs_dump_which does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





 sub PDL::ccs_dump_which {
   my ($which,$fh,$fmt,$fsep,$rsep) = @_;
   $fmt  = '%d'  if (!defined($fmt)  || $fmt eq '');
   $fsep = " "   if (!defined($fsep) || $fsep eq '');
   $rsep = "$/"  if (!defined($rsep) || $rsep eq '');
   $fh = \*STDOUT if (!defined($fh));
   &PDL::_ccs_dump_which_int($which,$fh,$fmt,$fsep,$rsep);
 }


*ccs_dump_which = \&PDL::ccs_dump_which;




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

Copyright (C) 2007-2013, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl)

=cut



;



# Exit with OK status

1;

		   