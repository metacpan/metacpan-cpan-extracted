#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Bad;

our @EXPORT_OK = qw(badflag check_badflag badvalue orig_badvalue nbad nbadover ngood ngoodover setbadat  isbad isgood nbadover ngoodover setbadif setvaltobad setnantobad setinftobad setnonfinitetobad setbadtonan setbadtoval copybad locf );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Bad ;






#line 20 "bad.pd"


=head1 NAME

PDL::Bad - PDL always processes bad values

=head1 DESCRIPTION

This module is loaded when you do C<use PDL>,
C<Use PDL::Lite> or C<PDL::LiteF>.

Implementation details are given in
L<PDL::BadValues>.

=head1 SYNOPSIS

 use PDL::Bad;
 print "\nBad value per PDL support in PDL is turned " .
     $PDL::Bad::PerPdl ? "on" : "off" . ".\n";

=head1 VARIABLES

=over 4

=item $PDL::Bad::UseNaN

Set to 0 as of PDL 2.040, as no longer available, though NaN can be used
as a badvalue for a given PDL object.

=item $PDL::Bad::PerPdl

Set to 1 as of PDL 2.040 as always available.

=item $PDL::Bad::Status

Set to 1 as of PDL 2.035 as always available.

=back

=cut
#line 66 "Bad.pm"






=head1 FUNCTIONS

=cut




#line 63 "bad.pd"


# really should be constants
$PDL::Bad::Status = 1;
$PDL::Bad::UseNaN = 0;
$PDL::Bad::PerPdl = 1;

use strict;

use PDL::Types;
use PDL::Primitive;

############################################################
############################################################
#line 95 "Bad.pm"



#line 114 "bad.pd"

############################################################
############################################################

*badflag         = \&PDL::badflag;
*badvalue        = \&PDL::badvalue;
*orig_badvalue   = \&PDL::orig_badvalue;

############################################################
############################################################

=head2 badflag

=for ref

getter/setter for the bad data flag

=for example

  if ( $x->badflag() ) {
    print "Data may contain bad values.\n";
  }
  $x->badflag(1);      # set bad data flag
  $x->badflag(0);      # unset bad data flag

When called as a setter, this modifies the ndarray on which
it is called. This always returns a Perl scalar with the
final value of the bad flag.

A return value of 1 does not guarantee the presence of
bad data in an ndarray; all it does is say that we need to
I<check> for the presence of such beasties. To actually
find out if there are any bad values present in an ndarray,
use the L</check_badflag> method.

=for bad

This function works with ndarrays that have bad values. It
always returns a Perl scalar, so it never returns bad values.

=head2 badvalue

=for ref

returns the value used to indicate a missing (or bad) element
for the given ndarray type. You can give it an ndarray,
a PDL::Type object, or one of C<$PDL_B>, C<$PDL_S>, etc.

=for example

   $badval = badvalue( float );
   $x = ones(ushort,10);
   print "The bad data value for ushort is: ",
      $x->badvalue(), "\n";

This can act as a setter (e.g. C<< $x->badvalue(23) >>),
including with the value C<NaN> for floating-point types.
Note that this B<never touches the data in the ndarray>.
That is, if C<$x> already has bad values, they will not
be changed to use the given number and if any elements of
C<$x> have that value, they will unceremoniously be marked
as bad data. See L</setvaltobad>, L</setbadtoval>, and
L</setbadif> for ways to actually modify the data in ndarrays

It is possible to change the bad value on a per-ndarray basis, so

    $x = sequence (10);
    $x->badvalue (3); $x->badflag (1);
    $y = sequence (10);
    $y->badvalue (4); $y->badflag (1);

will set $x to be C<[0 1 2 BAD 4 5 6 7 8 9]> and $y to be
C<[0 1 2 3 BAD 5 6 7 8 9]>.

=for bad

This method does not care if you call it on an input ndarray
that has bad values. It always returns a Perl scalar
with the current or new bad value.

=head2 orig_badvalue

=for ref

returns the original value used to represent bad values for
a given type.

This routine operates the same as L</badvalue>,
except you can not change the values.

It also has an I<awful> name.

=for example

   $orig_badval = orig_badvalue( float );
   $x = ones(ushort,10);
   print "The original bad data value for ushort is: ", 
      $x->orig_badvalue(), "\n";

=for bad

This method does not care if you call it on an input ndarray
that has bad values. It always returns a Perl scalar
with the original bad value for the associated type.

=head2 check_badflag

=for ref

Clear the bad-value flag of an ndarray if it does not
contain any bad values

Given an ndarray whose bad flag is set, check whether it
actually contains any bad values and, if not, clear the flag.
It returns the final state of the bad-value flag.

=for example

 print "State of bad flag == ", $pdl->check_badflag;

=for bad

This method accepts ndarrays with or without bad values. It
returns an ndarray with the final bad-value.

=cut

*check_badflag = \&PDL::check_badflag;

sub PDL::check_badflag {
    my $pdl = shift;
    $pdl->badflag(0) if $pdl->badflag and $pdl->nbad == 0;
    return $pdl->badflag;
} # sub: check_badflag()
#line 234 "Bad.pm"



#line 325 "bad.pd"


# note:
#  if sent an ndarray, we have to change its bad values
#  (but only if it contains bad values)
#  - there's a slight overhead in that the badflag is
#    cleared and then set (hence propagating to all
#    children) but we'll ignore that)
#  - we can ignore this for float/double types
#    since we can't change the bad value
#
sub PDL::badvalue {
    no strict 'refs';
    my ( $self, $val ) = @_;
    my $num;
    if ( UNIVERSAL::isa($self,"PDL") ) {
	$num = $self->get_datatype;
	if ( $num < $PDL_F && defined($val) && $self->badflag ) {
	    $self->inplace->setbadtoval( $val );
	    $self->badflag(1);
	}
	return PDL::_badvalue_per_pdl_int($self, $val, $num);
    } elsif ( UNIVERSAL::isa($self,"PDL::Type") ) {
	$num = $self->enum;
    } else {
        # assume it's a number
        $num = $self;
    }
    PDL::_badvalue_int( $val, $num );
}

sub PDL::orig_badvalue {
    no strict 'refs';
    my $self = shift;
    my $num;
    if ( UNIVERSAL::isa($self,"PDL") ) {
	$num = $self->get_datatype;
    } elsif ( UNIVERSAL::isa($self,"PDL::Type") ) {
	$num = $self->enum;
    } else {
        # assume it's a number
        $num = $self;
    }
    PDL::_default_badvalue_int($num);
}

############################################################
############################################################
#line 287 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 isbad

=for sig

  Signature: (a(); int [o]b())

=for ref

Returns a binary mask indicating which values of
the input are bad values

Returns a 1 if the value is bad, 0 otherwise.
Similar to L<isfinite|PDL::Math/isfinite>.

=for example

 $x = pdl(1,2,3);
 $x->badflag(1);
 set($x,1,$x->badvalue);
 $y = isbad($x);
 print $y, "\n";
 [0 1 0]

=for bad

This method works with input ndarrays that are bad. The output ndarray
will never contain bad values, but its bad value flag will be the
same as the input ndarray's flag.



=cut
#line 327 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*isbad = \&PDL::isbad;
#line 334 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 isgood

=for sig

  Signature: (a(); int [o]b())

=for ref

Is a value good?

Returns a 1 if the value is good, 0 otherwise.
Also see L<isfinite|PDL::Math/isfinite>.

=for example

 $x = pdl(1,2,3);
 $x->badflag(1);
 set($x,1,$x->badvalue);
 $y = isgood($x);
 print $y, "\n";
 [1 0 1]

=for bad

This method works with input ndarrays that are bad. The output ndarray
will never contain bad values, but its bad value flag will be the
same as the input ndarray's flag.



=cut
#line 373 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*isgood = \&PDL::isgood;
#line 380 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 nbadover

=for sig

  Signature: (a(n); indx [o] b())

=for ref

Find the number of bad elements along the 1st dimension.

This function reduces the dimensionality of an ndarray by one by finding the
number of bad elements along the 1st dimension. In this sense it shares
much in common with the functions defined in L<PDL::Ufunc>. In particular,
by using L<xchg|PDL::Slices/xchg> and similar dimension rearranging methods,
it is possible to perform this calculation over I<any> dimension.

=for usage

 $x = nbadover($y);

=for example

 $spectrum = nbadover $image->transpose

=for bad

nbadover processes input values that are bad. The output ndarray will not have
any bad values, but the bad flag will be set if the input ndarray had its bad
flag set.



=cut
#line 421 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*nbadover = \&PDL::nbadover;
#line 428 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 ngoodover

=for sig

  Signature: (a(n); indx [o] b())

=for ref

Find the number of good elements along the 1st dimension.

This function reduces the dimensionality of an ndarray
by one by finding the number of good elements
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $x = ngoodover($y);

=for example

 $spectrum = ngoodover $image->transpose

=for bad

ngoodover processes input values that are bad. The output ndarray will not have
any bad values, but the bad flag will be set if the input ndarray had its bad
flag set.



=cut
#line 470 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*ngoodover = \&PDL::ngoodover;
#line 477 "Bad.pm"



#line 560 "bad.pd"


*nbad = \&PDL::nbad;
sub PDL::nbad {
	my($x) = @_; my $tmp;
	$x->clump(-1)->nbadover($tmp=PDL->nullcreate($x) );
	return $tmp;
}
#line 490 "Bad.pm"



#line 560 "bad.pd"


*ngood = \&PDL::ngood;
sub PDL::ngood {
	my($x) = @_; my $tmp;
	$x->clump(-1)->ngoodover($tmp=PDL->nullcreate($x) );
	return $tmp;
}
#line 503 "Bad.pm"



#line 572 "bad.pd"


=head2 nbad

=for ref

Returns the number of bad values in an ndarray

=for usage

 $x = nbad($data);

=for bad

Accepts good and bad input ndarrays; output is a Perl scalar
and therefore is always good.

=head2 ngood

=for ref

Returns the number of good values in an ndarray

=for usage

 $x = ngood($data);

=for bad

Accepts good and bad input ndarrays; output is a Perl scalar
and therefore is always good.

=head2 setbadat

=for ref

Set the value to bad at a given position.

=for usage

 setbadat $ndarray, @position

C<@position> is a coordinate list, of size equal to the
number of dimensions in the ndarray.
This is a wrapper around L<set|PDL::Core/set> and is
probably mainly useful in test scripts!

=for example

 pdl> $x = sequence 3,4
 pdl> $x->setbadat 2,1
 pdl> p $x
 [
  [  0   1   2]
  [  3   4 BAD]
  [  6   7   8]
  [  9  10  11]
 ]

=for bad

This method can be called on ndarrays that have bad values.
The remainder of the arguments should be Perl scalars indicating
the position to set as bad. The output ndarray will have bad values
and will have its badflag turned on.

=cut

*setbadat = \&PDL::setbadat;
sub PDL::setbadat {
    barf 'Usage: setbadat($pdl, $x, $y, ...)' if $#_<1;
    my $self  = shift; 
    PDL::Core::set_c ($self, [@_], $self->badvalue);
    $self->badflag(1);
    return $self;
}
#line 584 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setbadif

=for sig

  Signature: (a(); int mask(); [o]b())

=for ref

Set elements bad based on the supplied mask, otherwise
copy across the data.

=for example

 pdl> $x = sequence(5,5)
 pdl> $x = $x->setbadif( $x % 2 )
 pdl> p "a badflag: ", $x->badflag, "\n"
 a badflag: 1
 pdl> p "a is\n$x"
 [
  [  0 BAD   2 BAD   4]
  [BAD   6 BAD   8 BAD]
  [ 10 BAD  12 BAD  14]
  [BAD  16 BAD  18 BAD]
  [ 20 BAD  22 BAD  24]
 ]

Unfortunately, this routine can I<not> be run inplace, since the
current implementation can not handle the same ndarray used as
C<a> and C<mask> (eg C<< $x->inplace->setbadif($x%2) >> fails).
Even more unfortunate: we can't catch this error and tell you.

=for bad

The output always has its bad flag set, even if it does not contain
any bad values (use L</check_badflag> to check
whether there are any bad values in the output). 
The input ndarray can have bad values: any bad values in the input ndarrays
are copied across to the output ndarray.

Also see L</setvaltobad> and L</setnantobad>.



=cut
#line 636 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setbadif = \&PDL::setbadif;
#line 643 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setvaltobad

=for sig

  Signature: (a(); [o]b(); double value)

=for ref

Set bad all those elements which equal the supplied value.

=for example

 $x = sequence(10) % 3;
 $x->inplace->setvaltobad( 0 );
 print "$x\n";
 [BAD 1 2 BAD 1 2 BAD 1 2 BAD]

This is a simpler version of L</setbadif>, but this
function can be done inplace.  See L</setnantobad>
if you want to convert NaN to the bad value.

=for bad

The output always has its bad flag set, even if it does not contain
any bad values (use L</check_badflag> to check
whether there are any bad values in the output). 
Any bad values in the input ndarrays are copied across to the output ndarray.



=cut
#line 682 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setvaltobad = \&PDL::setvaltobad;
#line 689 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setnantobad

=for sig

  Signature: (a(); [o]b())

=for ref

Sets NaN values (for complex, where either is NaN) in the input ndarray bad
(only relevant for floating-point ndarrays).
Can be done inplace.

=for usage

 $y = $x->setnantobad;
 $x->inplace->setnantobad;

=for bad

This method can process ndarrays with bad values: those bad values
are propagated into the output ndarray. Any value that is not a number
(before version 2.040 the test was for "not finite")
is also set to bad in the output ndarray. If all values from the input
ndarray are good, the output ndarray will B<not> have its
bad flag set.



=cut
#line 726 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setnantobad = \&PDL::setnantobad;
#line 733 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setinftobad

=for sig

  Signature: (a(); [o]b())

=for ref

Sets non-finite values (for complex, where either is non-finite) in
the input ndarray bad (only relevant for floating-point ndarrays).
Can be done inplace.

=for usage

 $y = $x->setinftobad;
 $x->inplace->setinftobad;

=for bad

This method can process ndarrays with bad values: those bad values
are propagated into the output ndarray. Any value that is not finite
is also set to bad in the output ndarray. If all values from the input
ndarray are finite, the output ndarray will B<not> have its
bad flag set.



=cut
#line 769 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setinftobad = \&PDL::setinftobad;
#line 776 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setnonfinitetobad

=for sig

  Signature: (a(); [o]b())

=for ref

Sets non-finite values (for complex, where either is non-finite) in
the input ndarray bad (only relevant for floating-point ndarrays).
Can be done inplace.

=for usage

 $y = $x->setnonfinitetobad;
 $x->inplace->setnonfinitetobad;

=for bad

This method can process ndarrays with bad values: those bad values
are propagated into the output ndarray. Any value that is not finite
is also set to bad in the output ndarray. If all values from the input
ndarray are finite, the output ndarray will B<not> have its
bad flag set.



=cut
#line 812 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setnonfinitetobad = \&PDL::setnonfinitetobad;
#line 819 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setbadtonan

=for sig

  Signature: (a(); [o] b();)

=for ref

Sets Bad values to NaN

This is only relevant for floating-point ndarrays. The input ndarray can be
of any type, but if done inplace, the input must be floating point.

=for usage

 $y = $x->setbadtonan;
 $x->inplace->setbadtonan;

=for bad

This method processes input ndarrays with bad values. The output ndarrays will
not contain bad values (insofar as NaN is not Bad as far as PDL is concerned)
and the output ndarray does not have its bad flag set. As an inplace
operation, it clears the bad flag.



=cut
#line 855 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setbadtonan = \&PDL::setbadtonan;
#line 862 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 setbadtoval

=for sig

  Signature: (a(); [o]b(); double newval)

=for ref

Replace any bad values by a (non-bad) value. 

Can be done inplace. Also see
L<badmask|PDL::Math/badmask>.

=for example

 $x->inplace->setbadtoval(23);
 print "a badflag: ", $x->badflag, "\n";
 a badflag: 0

=for bad

The output always has its bad flag cleared.
If the input ndarray does not have its bad flag set, then
values are copied with no replacement.



=cut
#line 898 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*setbadtoval = \&PDL::setbadtoval;
#line 905 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 copybad

=for sig

  Signature: (a(); mask(); [o]b())

=for ref

Copies values from one ndarray to another, setting them
bad if they are bad in the supplied mask.

Can be done inplace.

=for example

 $x = byte( [0,1,3] );
 $mask = byte( [0,0,0] );
 $mask->badflag(1);
 set($mask,1,$mask->badvalue);
 $x->inplace->copybad( $mask );
 p $x;
 [0 BAD 3]

It is equivalent to:

 $c = $x + $mask * 0

=for bad

This handles input ndarrays that are bad. If either C<$x>
or C<$mask> have bad values, those values will be marked
as bad in the output ndarray and the output ndarray will have
its bad value flag set to true.



=cut
#line 950 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*copybad = \&PDL::copybad;
#line 957 "Bad.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 locf

=for sig

  Signature: (a(n); [o]b(n))

=for ref

Last Observation Carried Forward - replace
every BAD value with the most recent non-BAD value prior to it.
Any leading BADs will be set to 0.


=for bad

locf processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 985 "Bad.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*locf = \&PDL::locf;
#line 992 "Bad.pm"





#line 1142 "bad.pd"


=head1 AUTHOR

Doug Burke (djburke@cpan.org), 2000, 2001, 2003, 2006.

The per-ndarray bad value support is by Heiko Klein (2006).

CPAN documentation fixes by David Mertens (2010, 2013).

All rights reserved. There is no warranty. You are allowed to
redistribute this software / documentation under certain conditions. For
details, see the file COPYING in the PDL distribution. If this file is
separated from the PDL distribution, the copyright notice should be
included in the file.

=cut
#line 1016 "Bad.pm"




# Exit with OK status

1;
