
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::Bad;

@EXPORT_OK  = qw(  badflag check_badflag badvalue orig_badvalue nbad nbadover ngood ngoodover setbadat  PDLA::PP isbad PDLA::PP isgood PDLA::PP nbadover PDLA::PP ngoodover PDLA::PP setbadif PDLA::PP setvaltobad PDLA::PP setnantobad PDLA::PP setbadtonan PDLA::PP setbadtoval PDLA::PP copybad );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::Bad ;





=head1 NAME

PDLA::Bad - PDLA does process bad values

=head1 DESCRIPTION

PDLA has been compiled with WITH_BADVAL set to 1. Therefore,
you can enter the wonderful world of bad value support in
PDLA.

This module is loaded when you do C<use PDLA>,
C<Use PDLA::Lite> or C<PDLA::LiteF>.

Implementation details are given in
L<PDLA::BadValues>.

=head1 SYNOPSIS

 use PDLA::Bad;
 print "\nBad value support in PDLA is turned " .
     $PDLA::Bad::Status ? "on" : "off" . ".\n";

 Bad value support in PDLA is turned on.

 and some other things

=head1 VARIABLES

There are currently three variables that this module defines
which may be of use.

=over 4

=item $PDLA::Bad::Status

Set to 1

=item $PDLA::Bad::UseNaN

Set to 1 if PDLA was compiled with C<BADVAL_USENAN> set,
0 otherwise.

=item $PDLA::Bad::PerPdl

Set to 1 if PDLA was compiled with the I<experimental>
C<BADVAL_PER_PDLA> option set, 0 otherwise.

=back

=cut







=head1 FUNCTIONS



=cut





# really should be constants
$PDLA::Bad::Status = 1;
$PDLA::Bad::UseNaN = 0;
$PDLA::Bad::PerPdl = 0;

use strict;

use PDLA::Types;
use PDLA::Primitive;

############################################################
############################################################



############################################################
############################################################

*badflag         = \&PDLA::badflag;
*badvalue        = \&PDLA::badvalue;
*orig_badvalue   = \&PDLA::orig_badvalue;

############################################################
############################################################

=head2 badflag

=for ref

getter/setter for the bad data flag

=for example

  if ( $a->badflag() ) {
    print "Data may contain bad values.\n";
  }
  $a->badflag(1);      # set bad data flag
  $a->badflag(0);      # unset bad data flag

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
a PDLA::Type object, or one of C<$PDLA_B>, C<$PDLA_S>, etc.

=for example

   $badval = badvalue( float );
   $a = ones(ushort,10);
   print "The bad data value for ushort is: ",
      $a->badvalue(), "\n";

This can act as a setter (e.g. C<< $a->badvalue(23) >>)
if the data type is an integer or C<$PDLA::Bad::UseNaN == 0>.
Note that this B<never touches the data in the piddle>.
That is, if C<$a> already has bad values, they will not
be changed to use the given number and if any elements of
C<$a> have that value, they will unceremoniously be marked
as bad data. See L</setvaltobad>, L</setbadtoval>, and
L</setbadif> for ways to actually modify the data in piddles

If the C<$PDLA::Bad::PerPdl> flag is set then it is possible to
change the bad value on a per-piddle basis, so

    $a = sequence (10);
    $a->badvalue (3); $a->badflag (1);
    $b = sequence (10);
    $b->badvalue (4); $b->badflag (1);

will set $a to be C<[0 1 2 BAD 4 5 6 7 8 9]> and $b to be
C<[0 1 2 3 BAD 5 6 7 8 9]>. If the flag is not set then both
$a and $b will be set to C<[0 1 2 3 BAD 5 6 7 8 9]>. Please
note that the code to support per-piddle bad values is
I<experimental> in the current release, and it requires that
you modify the settings under which PDLA is compiled.

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
   $a = ones(ushort,10);
   print "The original bad data value for ushort is: ", 
      $a->orig_badvalue(), "\n";

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

*check_badflag = \&PDLA::check_badflag;

sub PDLA::check_badflag {
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
sub PDLA::badvalue {
    no strict 'refs';

    my ( $self, $val ) = @_;
    my $num;
    if ( UNIVERSAL::isa($self,"PDLA") ) {
	$num = $self->get_datatype;
	if ( $num < 4 and defined($val) and $self->badflag ) {
	    $self->inplace->setbadtoval( $val );
	    $self->badflag(1);
	}

	if ($PDLA::Config{BADVAL_PER_PDLA}) {
	    my $name = "PDLA::_badvalue_per_pdl_int$num";
	    if ( defined $val ) {
		return &{$name}($self, $val )->sclr;
	    } else {
		return &{$name}($self)->sclr;
	    }
	}

    } elsif ( UNIVERSAL::isa($self,"PDLA::Type") ) {
	$num = $self->enum;
    } else {
        # assume it's a number
        $num = $self;
    }

    my $name = "PDLA::_badvalue_int$num";
    if ( defined $val ) {
	return &{$name}( $val )->sclr;
    } else {
	return &{$name}()->sclr;
    }

} # sub: badvalue()

sub PDLA::orig_badvalue {
    no strict 'refs';

    my $self = shift;
    my $num;
    if ( UNIVERSAL::isa($self,"PDLA") ) {
	$num = $self->get_datatype;
    } elsif ( UNIVERSAL::isa($self,"PDLA::Type") ) {
	$num = $self->enum;
    } else {
        # assume it's a number
        $num = $self;
    }

    my $name = "PDLA::_default_badvalue_int$num";
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
Similar to L<isfinite|PDLA::Math/isfinite>.

=for example

 $a = pdl(1,2,3);
 $a->badflag(1);
 set($a,1,$a->badvalue);
 $b = isbad($a);
 print $b, "\n";
 [0 1 0]

=for bad

This method works with input piddles that are bad. The ouptut piddle
will never contain bad values, but its bad value flag will be the
same as the input piddle's flag.



=cut





*isbad = \&PDLA::isbad;





=head2 isgood

=for sig

  Signature: (a(); int [o]b())

=for ref

Is a value good?

Returns a 1 if the value is good, 0 otherwise.
Also see L<isfinite|PDLA::Math/isfinite>.

=for example

 $a = pdl(1,2,3);
 $a->badflag(1);
 set($a,1,$a->badvalue);
 $b = isgood($a);
 print $b, "\n";
 [1 0 1]

=for bad

This method works with input piddles that are bad. The ouptut piddle
will never contain bad values, but its bad value flag will be the
same as the input piddle's flag.



=cut





*isgood = \&PDLA::isgood;





=head2 nbadover

=for sig

  Signature: (a(n); int+ [o] b())

=for ref

Find the number of bad elements along the 1st dimension.

This function reduces the dimensionality of a piddle by one by finding the
number of bad elements along the 1st dimension. In this sense it shares
much in common with the functions defined in L<PDLA::Ufunc>. In particular,
by using L<xchg|PDLA::Slices/xchg> and similar dimension rearranging methods,
it is possible to perform this calculation over I<any> dimension.

=for usage

 $a = nbadover($b);

=for example

 $spectrum = nbadover $image->xchg(0,1)

=for bad

nbadover processes input values that are bad. The ouput piddle will not have
any bad values, but the bad flag will be set if the input piddle had its bad
flag set.



=cut





*nbadover = \&PDLA::nbadover;





=head2 ngoodover

=for sig

  Signature: (a(n); int+ [o] b())

=for ref

Find the number of good elements along the 1st dimension.

This function reduces the dimensionality of a piddle
by one by finding the number of good elements
along the 1st dimension.

By using L<xchg|PDLA::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $a = ngoodover($b);

=for example

 $spectrum = ngoodover $image->xchg(0,1)

=for bad

ngoodover processes input values that are bad. The ouput piddle will not have
any bad values, but the bad flag will be set if the input piddle had its bad
flag set.



=cut





*ngoodover = \&PDLA::ngoodover;




*nbad = \&PDLA::nbad;
sub PDLA::nbad {
	my($x) = @_; my $tmp;
	$x->clump(-1)->nbadover($tmp=PDLA->nullcreate($x) );
	return $tmp->at();
}



*ngood = \&PDLA::ngood;
sub PDLA::ngood {
	my($x) = @_; my $tmp;
	$x->clump(-1)->ngoodover($tmp=PDLA->nullcreate($x) );
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
This is a wrapper around L<set|PDLA::Core/set> and is
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
the position to set as bad. The ouptut piddle will have bad values
and will have its badflag turned on.

=cut

*setbadat = \&PDLA::setbadat;
sub PDLA::setbadat {
    barf 'Usage: setbadat($pdl, $x, $y, ...)' if $#_<1;
    my $self  = shift; 
    PDLA::Core::set_c ($self, [@_], $self->badvalue);
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

 pdl> $a = sequence(5,5)
 pdl> $a = $a->setbadif( $a % 2 )
 pdl> p "a badflag: ", $a->badflag, "\n"
 a badflag: 1
 pdl> p "a is\n$a"
 [
  [  0 BAD   2 BAD   4]
  [BAD   6 BAD   8 BAD]
  [ 10 BAD  12 BAD  14]
  [BAD  16 BAD  18 BAD]
  [ 20 BAD  22 BAD  24]
 ]

Unfortunately, this routine can I<not> be run inplace, since the
current implementation can not handle the same piddle used as
C<a> and C<mask> (eg C<< $a->inplace->setbadif($a%2) >> fails).
Even more unfortunate: we can't catch this error and tell you.

=for bad

The output always has its bad flag set, even if it does not contain
any bad values (use L<check_badflag|/check_badflag> to check
whether there are any bad values in the output). 
The input piddle can have bad values: any bad values in the input piddles
are copied across to the output piddle.

Also see L<setvaltobad|/setvaltobad> and L<setnantobad|/setnantobad>.



=cut





*setbadif = \&PDLA::setbadif;





=head2 setvaltobad

=for sig

  Signature: (a(); [o]b(); double value)

=for ref

Set bad all those elements which equal the supplied value.

=for example

 $a = sequence(10) % 3;
 $a->inplace->setvaltobad( 0 );
 print "$a\n";
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





*setvaltobad = \&PDLA::setvaltobad;





=head2 setnantobad

=for sig

  Signature: (a(); [o]b())

=for ref

Sets NaN/Inf values in the input piddle bad
(only relevant for floating-point piddles).
Can be done inplace.

=for usage

 $b = $a->setnantobad;
 $a->inplace->setnantobad;

=for bad

This method can process piddles with bad values: those bad values
are propagated into the output piddle. Any value that is not finite
is also set to bad in the output piddle. If all values from the input
piddle are good and finite, the output piddle will B<not> have its
bad flag set. One more caveat: if done inplace, and if the input piddle's
bad flag is set, it will no



=cut





*setnantobad = \&PDLA::setnantobad;





=head2 setbadtonan

=for sig

  Signature: (a(); [o] b();)

=for ref

Sets Bad values to NaN

This is only relevant for floating-point piddles. The input piddle can be
of any type, but if done inplace, the input must be floating point.

=for usage

 $b = $a->setbadtonan;
 $a->inplace->setbadtonan;

=for bad

This method processes input piddles with bad values. The output piddles will
not contain bad values (insofar as NaN is not Bad as far as PDLA is concerned)
and the output piddle does not have its bad flag set. As an inplace
operation, it clears the bad flag.



=cut





*setbadtonan = \&PDLA::setbadtonan;





=head2 setbadtoval

=for sig

  Signature: (a(); [o]b(); double newval)

=for ref

Replace any bad values by a (non-bad) value. 

Can be done inplace. Also see
L<badmask|PDLA::Math/badmask>.

=for example

 $a->inplace->setbadtoval(23); 
 print "a badflag: ", $a->badflag, "\n";
 a badflag: 0

=for bad

The output always has its bad flag cleared.
If the input piddle does not have its bad flag set, then
values are copied with no replacement.



=cut





*setbadtoval = \&PDLA::setbadtoval;





=head2 copybad

=for sig

  Signature: (a(); mask(); [o]b())

=for ref

Copies values from one piddle to another, setting them
bad if they are bad in the supplied mask.

Can be done inplace.

=for example

 $a = byte( [0,1,3] );
 $mask = byte( [0,0,0] );
 set($mask,1,$mask->badvalue);
 $a->inplace->copybad( $mask );
 p $a;
 [0 BAD 3]

It is equivalent to:

 $c = $a + $mask * 0

=for bad

This handles input piddles that are bad. If either C<$a>
or C<$mask> have bad values, those values will be marked
as bad in the output piddle and the output piddle will have
its bad value flag set to true.



=cut





*copybad = \&PDLA::copybad;



;


=head1 CHANGES

The I<experimental> C<BADVAL_PER_PDLA> configuration option,
which - when set - allows per-piddle bad values, was added
after the 2.4.2 release of PDLA.
The C<$PDLA::Bad::PerPdl> variable can be
inspected to see if this feature is available.


=head1 CONFIGURATION

The way the PDLA handles the various bad value settings depends on your
compile-time configuration settings, as held in C<perldl.conf>.

=over

=item C<$PDLA::Config{WITH_BADVAL}>

Set this configuration option to a true value if you want bad value
support. The default setting is for this to be true.

=item C<$PDLA::Config{BADVAL_USENAN}>

Set this configuration option to a true value if you want floating-pont
numbers to use NaN to represent the bad value. If set to false, you can
use any number to represent a bad value, which is generally more
flexible. In the default configuration, this is set to a false value.

=item C<$PDLA::Config{BADVAL_PER_PDLA}>

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
details, see the file COPYING in the PDLA distribution. If this file is
separated from the PDLA distribution, the copyright notice should be
included in the file.

=cut





# Exit with OK status

1;

		   