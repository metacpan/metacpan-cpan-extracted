
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Bad;

@EXPORT_OK  = qw(  badflag check_badflag badvalue orig_badvalue nbad nbadover ngood ngoodover setbadat  PDL::PP isbad PDL::PP isgood PDL::PP nbadover PDL::PP ngoodover PDL::PP setbadif PDL::PP setvaltobad PDL::PP setnantobad PDL::PP setbadtonan PDL::PP setbadtoval PDL::PP copybad );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Bad ;





=head1 NAME

PDL::Bad - PDL does process bad values

=head1 DESCRIPTION

PDL has been compiled with WITH_BADVAL set to 1. Therefore,
you can enter the wonderful world of bad value support in
PDL.

This module is loaded when you do C<use PDL>,
C<Use PDL::Lite> or C<PDL::LiteF>.

Implementation details are given in
L<PDL::BadValues>.

=head1 SYNOPSIS

 use PDL::Bad;
 print "\nBad value support in PDL is turned " .
     $PDL::Bad::Status ? "on" : "off" . ".\n";

 Bad value support in PDL is turned on.

 and some other things

=head1 VARIABLES

There are currently three variables that this module defines
which may be of use.

=over 4

=item $PDL::Bad::Status

Set to 1

=item $PDL::Bad::UseNaN

Set to 1 if PDL was compiled with C<BADVAL_USENAN> set,
0 otherwise.

=item $PDL::Bad::PerPdl

Set to 1 if PDL was compiled with the I<experimental>
C<BADVAL_PER_PDL> option set, 0 otherwise.

=back

=cut







=head1 FUNCTIONS



=cut





# really should be constants
$PDL::Bad::Status = 1;
$PDL::Bad::UseNaN = 0;
$PDL::Bad::PerPdl = 0;

use strict;

use PDL::Types;
use PDL::Primitive;

############################################################
############################################################



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

When called as a setter, this modifies the piddle on which
it is called. This always returns a Perl scalar with the
final value of the bad flag.

A return value of 1 does not guarantee the presence of
bad data in a piddle; all it does is say that we need to
I<check> for the presence of such beasties. To actually
find out if there are any bad values present in a piddle,
use the L<check_badflag|/check_badflag> method.

=for bad

This function works with piddles that have bad values. It
always returns a Perl scalar, so it never returns bad values.

=head2 badvalue

=for ref

returns the value used to indicate a missing (or bad) element
for the given piddle type. You can give it a piddle,
a PDL::Type object, or one of C<$PDL_B>, C<$PDL_S>, etc.

=for example

   $badval = badvalue( float );
   $x = ones(ushort,10);
   print "The bad data value for ushort is: ",
      $x->badvalue(), "\n";

This can act as a setter (e.g. C<< $x->badvalue(23) >>)
if the data type is an integer or C<$PDL::Bad::UseNaN == 0>.
Note that this B<never touches the data in the piddle>.
That is, if C<$x> already has bad values, they will not
be changed to use the given number and if any elements of
C<$x> have that value, they will unceremoniously be marked
as bad data. See L</setvaltobad>, L</setbadtoval>, and
L</setbadif> for ways to actually modify the data in piddles

If the C<$PDL::Bad::PerPdl> flag is set then it is possible to
change the bad value on a per-piddle basis, so

    $x = sequence (10);
    $x->badvalue (3); $x->badflag (1);
    $y = sequence (10);
    $y->badvalue (4); $y->badflag (1);

will set $x to be C<[0 1 2 BAD 4 5 6 7 8 9]> and $y to be
C<[0 1 2 3 BAD 5 6 7 8 9]>. If the flag is not set then both
$x and $y will be set to C<[0 1 2 3 BAD 5 6 7 8 9]>. Please
note that the code to support per-piddle bad values is
I<experimental> in the current release, and it requires that
you modify the settings under which PDL is compiled.

=for bad

This method does not care if you call it on an input piddle
that has bad values. It always returns a Perl scalar
with the current or new bad value.

=head2 orig_badvalue

=for ref

returns the original value used to represent bad values for
a given type.

This routine operates the same as L<badvalue|/badvalue>,
except you can not change the values.

It also has an I<awful> name.

=for example

   $orig_badval = orig_badvalue( float );
   $x = ones(ushort,10);
   print "The original bad data value for ushort is: ", 
      $x->orig_badvalue(), "\n";

=for bad

This method does not care if you call it on an input piddle
that has bad values. It always returns a Perl scalar
with the original bad value for the associated type.

=head2 check_badflag

=for ref

Clear the bad-value flag of a piddle if it does not
contain any bad values

Given a piddle whose bad flag is set, check whether it
actually contains any bad values and, if not, clear the flag.
It returns the final state of the bad-value flag.

=for example

 print "State of bad flag == ", $pdl->check_badflag;

=for bad

This method accepts piddles with or without bad values. It
returns a Perl scalar with the final bad-value flag, so it
never returns bad values itself.

=cut

*check_badflag = \&PDL::check_badflag;

sub PDL::check_badflag {
    my $pdl = shift;
    $pdl->badflag(0) if $pdl->badflag and $pdl->nbad == 0;
    return $pdl->badflag;
} # sub: check_badflag()




# note:
#  if sent a piddle, we have to change it's bad values
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

	if ($PDL::Config{BADVAL_PER_PDL}) {
	    my $name = "PDL::_badvalue_per_pdl_int$num";
	    if ( defined $val ) {
		return &{$name}($self, $val )->sclr;
	    } else {
		return &{$name}($self, undef)->sclr;
	    }
	}

    } elsif ( UNIVERSAL::isa($self,"PDL::Type") ) {
	$num = $self->enum;
    } else {
        # assume it's a number
        $num = $self;
    }

    my $name = "PDL::_badvalue_int$num";
    if ( defined $val ) {
	return &{$name}( $val )->sclr;
    } else {
	return &{$name}( undef )->sclr;
    }

} # sub: badvalue()

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

    my $name = "PDL::_default_badvalue_int$num";
    return &${name}();

} # sub: orig_badvalue()

############################################################
############################################################





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

This method works with input piddles that are bad. The output piddle
will never contain bad values, but its bad value flag will be the
same as the input piddle's flag.



=cut





*isbad = \&PDL::isbad;





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

This method works with input piddles that are bad. The output piddle
will never contain bad values, but its bad value flag will be the
same as the input piddle's flag.



=cut





*isgood = \&PDL::isgood;





=head2 nbadover

=for sig

  Signature: (a(n); indx [o] b())

=for ref

Find the number of bad elements along the 1st dimension.

This function reduces the dimensionality of a piddle by one by finding the
number of bad elements along the 1st dimension. In this sense it shares
much in common with the functions defined in L<PDL::Ufunc>. In particular,
by using L<xchg|PDL::Slices/xchg> and similar dimension rearranging methods,
it is possible to perform this calculation over I<any> dimension.

=for usage

 $x = nbadover($y);

=for example

 $spectrum = nbadover $image->xchg(0,1)

=for bad

nbadover processes input values that are bad. The output piddle will not have
any bad values, but the bad flag will be set if the input piddle had its bad
flag set.



=cut





*nbadover = \&PDL::nbadover;





=head2 ngoodover

=for sig

  Signature: (a(n); indx [o] b())

=for ref

Find the number of good elements along the 1st dimension.

This function reduces the dimensionality of a piddle
by one by finding the number of good elements
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $x = ngoodover($y);

=for example

 $spectrum = ngoodover $image->xchg(0,1)

=for bad

ngoodover processes input values that are bad. The output piddle will not have
any bad values, but the bad flag will be set if the input piddle had its bad
flag set.



=cut





*ngoodover = \&PDL::ngoodover;




*nbad = \&PDL::nbad;
sub PDL::nbad {
	my($x) = @_; my $tmp;
	$x->clump(-1)->nbadover($tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



*ngood = \&PDL::ngood;
sub PDL::ngood {
	my($x) = @_; my $tmp;
	$x->clump(-1)->ngoodover($tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 nbad

=for ref

Returns the number of bad values in a piddle

=for usage

 $x = nbad($data);

=for bad

Accepts good and bad input piddles; output is a Perl scalar
and therefore is always good.

=head2 ngood

=for ref

Returns the number of good values in a piddle

=for usage

 $x = ngood($data);

=for bad

Accepts good and bad input piddles; output is a Perl scalar
and therefore is always good.

=head2 setbadat

=for ref

Set the value to bad at a given position.

=for usage

 setbadat $piddle, @position

C<@position> is a coordinate list, of size equal to the
number of dimensions in the piddle.
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

This method can be called on piddles that have bad values.
The remainder of the arguments should be Perl scalars indicating
the position to set as bad. The output piddle will have bad values
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
current implementation can not handle the same piddle used as
C<a> and C<mask> (eg C<< $x->inplace->setbadif($x%2) >> fails).
Even more unfortunate: we can't catch this error and tell you.

=for bad

The output always has its bad flag set, even if it does not contain
any bad values (use L<check_badflag|/check_badflag> to check
whether there are any bad values in the output). 
The input piddle can have bad values: any bad values in the input piddles
are copied across to the output piddle.

Also see L<setvaltobad|/setvaltobad> and L<setnantobad|/setnantobad>.



=cut





*setbadif = \&PDL::setbadif;





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

This is a simpler version of L<setbadif|/setbadif>, but this
function can be done inplace.  See L<setnantobad|/setnantobad>
if you want to convert NaN/Inf to the bad value.

=for bad

The output always has its bad flag set, even if it does not contain
any bad values (use L<check_badflag|/check_badflag> to check
whether there are any bad values in the output). 
Any bad values in the input piddles are copied across to the output piddle.



=cut





*setvaltobad = \&PDL::setvaltobad;





=head2 setnantobad

=for sig

  Signature: (a(); [o]b())

=for ref

Sets NaN/Inf values in the input piddle bad
(only relevant for floating-point piddles).
Can be done inplace.

=for usage

 $y = $x->setnantobad;
 $x->inplace->setnantobad;

=for bad

This method can process piddles with bad values: those bad values
are propagated into the output piddle. Any value that is not finite
is also set to bad in the output piddle. If all values from the input
piddle are good and finite, the output piddle will B<not> have its
bad flag set. One more caveat: if done inplace, and if the input piddle's
bad flag is set, it will no



=cut





*setnantobad = \&PDL::setnantobad;





=head2 setbadtonan

=for sig

  Signature: (a(); [o] b();)

=for ref

Sets Bad values to NaN

This is only relevant for floating-point piddles. The input piddle can be
of any type, but if done inplace, the input must be floating point.

=for usage

 $y = $x->setbadtonan;
 $x->inplace->setbadtonan;

=for bad

This method processes input piddles with bad values. The output piddles will
not contain bad values (insofar as NaN is not Bad as far as PDL is concerned)
and the output piddle does not have its bad flag set. As an inplace
operation, it clears the bad flag.



=cut





*setbadtonan = \&PDL::setbadtonan;





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
If the input piddle does not have its bad flag set, then
values are copied with no replacement.



=cut





*setbadtoval = \&PDL::setbadtoval;





=head2 copybad

=for sig

  Signature: (a(); mask(); [o]b())

=for ref

Copies values from one piddle to another, setting them
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

This handles input piddles that are bad. If either C<$x>
or C<$mask> have bad values, those values will be marked
as bad in the output piddle and the output piddle will have
its bad value flag set to true.



=cut





*copybad = \&PDL::copybad;



;


=head1 CHANGES

The I<experimental> C<BADVAL_PER_PDL> configuration option,
which - when set - allows per-piddle bad values, was added
after the 2.4.2 release of PDL.
The C<$PDL::Bad::PerPdl> variable can be
inspected to see if this feature is available.


=head1 CONFIGURATION

The way the PDL handles the various bad value settings depends on your
compile-time configuration settings, as held in C<perldl.conf>.

=over

=item C<$PDL::Config{WITH_BADVAL}>

Set this configuration option to a true value if you want bad value
support. The default setting is for this to be true.

=item C<$PDL::Config{BADVAL_USENAN}>

Set this configuration option to a true value if you want floating-pont
numbers to use NaN to represent the bad value. If set to false, you can
use any number to represent a bad value, which is generally more
flexible. In the default configuration, this is set to a false value.

=item C<$PDL::Config{BADVAL_PER_PDL}>

Set this configuration option to a true value if you want each of your
piddles to keep track of their own bad values. This means that for one
piddle you can set the bad value to zero, while in another piddle you
can set the bad value to NaN (or any other useful number). This is
usually set to false.

=back

=head1 AUTHOR

Doug Burke (djburke@cpan.org), 2000, 2001, 2003, 2006.

The per-piddle bad value support is by Heiko Klein (2006).

CPAN documentation fixes by David Mertens (2010, 2013).

All rights reserved. There is no warranty. You are allowed to
redistribute this software / documentation under certain conditions. For
details, see the file COPYING in the PDL distribution. If this file is
separated from the PDL distribution, the copyright notice should be
included in the file.

=cut





# Exit with OK status

1;

		   