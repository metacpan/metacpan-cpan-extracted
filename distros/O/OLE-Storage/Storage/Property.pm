#
# $Id: Property.pm,v 1.1.1.1 1998/02/25 21:13:00 schwartz Exp $
#
# OLE::Storage::Property
#
# Copyright (C) 1996, 1997, 1998 Martin Schwartz 
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, you should find it at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/COPYING
#
# Contact: schwartz@cs.tu-berlin.de
#
package OLE::Storage::Property;
use strict;
my $VERSION=do{my@R=('$Revision: 1.1.1.1 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

#
# Restrict OLE::Storage::Std imports, as name space mismatch could occur!
#
use OLE::Storage::Std qw(get_long);
use vars qw($AUTOLOAD);

sub AUTOLOAD {
#
# $string = $Property->string
# @strings = string { @Properties }
#
   (my $to = $AUTOLOAD) =~ s/.*://;
   if (wantarray) {
      map (     $_->_var->_RETRIEVE(   $_->type, $to,    $_->_data), @_)
   } else {
      return $_[0]->_var->_RETRIEVE($_[0]->type, $to, $_[0]->_data);
   }
}

sub cast {
#
# new Property = $Property -> cast ($type)
#
   my ($S, $type) = @_;
   $S->_var()->property (\$S->$type(), 0, $type);
}

sub array     { $_[0]->_data }
sub is_scalar { $_[0]->_var()->_IS_SCALAR($_[0]->type()) }
sub is_array  { $_[0]->_var()->_IS_ARRAY($_[0]->type()) }
sub is_varray { $_[0]->_var()->_IS_VARRAY($_[0]->type()) }
sub stype     { $_[0]->_var()->_TO_SCALAR($_[0]->type()) }
sub type      { $_[0]->_type }
sub typestr {
   my $S=shift;
   my $str = $S->_var->_TYPESTR($S->stype);
   $str .= "[]" if $S->is_array;
   $str;
}
sub var       { $_[0]->_var }

#
# -- Private ---------------------------------------------------------------
#

sub new {
#
# $Property = new Property ($Var, \$buf, $o||\$o [,$type])
#
   my ($proto, $Var, $bufR, $o, $type) = @_;
   my $class = ref($proto) || $proto;
   my $S = {
      V  => $Var, 	# _var,  Variable Handler
      T  => undef,	# _type, Property Type
      D  => undef,	# _data, Property Data, maintained by $Var
   };
   bless ($S, $class) -> 
      _property($bufR, ref($o) ? $o : \$o, $type)
   ;
}

sub dump {
   my $S = $_[0];
   my ($k, $v);
   print "$S\n";
   while ( ($k, $v) = each %$S ) {
      print "   {$k} = $v\n";
      if (($k eq "D") && ref($v)) {
         printf "       [0] = %s\n", $v->[0];
         printf "       [1] = %s (%s)\n", $v->[1], ${$v->[1]};
      }
   }
   print "\n";
}

sub DESTROY {
   #print "Deleting "; shift->dump();
}

sub _property {
#
# $Prop = _property(\$buf, $oR [,$type])
#
# Structure:
#
# Error_Property    = { T=>error, D=>$errstr }
# Standard_Property = { T=>$type, D=>$data }
# Vector_Property   = { T=>$type, D=>[$Property, $Property, ... ] }
#
   my $S = shift;
   my ($bufR, $oR, $type) = @_;
   $type = get_long($bufR, $oR) if !defined $type;

   if ($S->is_scalar($S->_type($type))) {
      $S->_data($S->_var->_STORE($bufR, $oR, $type));
   } else {
      if ($S->is_varray) {
         $type = undef;
      } else {
         $type = $S->stype;
      }
      $S->_data([map(
         $S->_var->property($bufR, $oR, $type), (1 .. get_long($bufR, $oR))
      )]);
   }
$S}

#
# Member methods
#

sub _data { my $S=shift; $S->{D}=shift if @_; $S->{D} }
sub _type { my $S=shift; $S->{T}=shift if @_; $S->{T} }
sub _var  { my $S=shift; $S->{V}=shift if @_; $S->{V} }

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::Storage::Property - maintain Properties for OLE::Storage::Var

$Revision: 1.1.1.1 $ $Date: 1998/02/25 21:13:00 $

=head1 SYNOPSIS

OLE::Storage and OLE::PropertySet are returning from time to time a
kind of variables called Properties (I<$Prop>). Properties could be handled
as follows:

 sub work {
    my $Prop = shift;
    if (is_scalar $Prop) {
       do_something_with ($Prop); # $Prop definitively is a scalar.
    } else {
       foreach $P (@{array $Prop}) {
          work ($P);              # $P could be an array itself.
       }
    }
 }

I<$string> = I<$Prop> -> string()

I<$NewProp> = I<$OldProp> -> cast ("C<string>")

=head1 DESCRIPTION

OLE::Storage::Property is maintaining the Properties, that are initially
instantiated by other packages. It gives storage places to
OLE::Storage::Var, manages Property to Property conversions, Property to
scalar conversions and type information. Though you will use the member
functions of OLE::Storage::Property quite often, you should never create a
Property directly with this package. Therefore "use OLE::Storage::Property"
even was useless.

Type implementation itself is done at OLE::Storage::Var, that offers some
private methods for OLE::Storage::Property. Both, type conversions and type
availability are quite far from being complete (as you will notice when
looking at Var.pm). For this release I cared only to have the
something->string conversions working, and therefore only them are
documented above.

=over 4

=item array

I<\@Properties> = I<$Prop> -> array()

Returns a reference to a Property list. You have to use this to find
out, which properties are hiding inside an array property.

=item Conversion: Property to perl scalar

I<$scalar> = I<$Prop> -> method()

Returns a scalar variable, that perl understands. Momentarily method()
should be string() only.

=item Conversion: Property to Property

I<$NewProp> = I<$OldProp> -> cast ("C<method>")

Returns a Property of type C<method>. 

=item is_scalar

C<1>||C<0> == I<$Prop> -> is_scalar()

Returns 1 if $Prop is a scalar variable, 0 otherwise. A property is 
scalar, if it is not an array. 

=item is_array

C<1>||C<0> == I<$Prop> -> is_array()

Returns 1 if $Prop is some array variable, 0 otherwise.

=item is_varray

C<1>||C<0> == I<$Prop> -> is_varray()

Returns 1 if $Prop is a variant array variable, 0 otherwise. A variant array
is an array, that consists out of elements with different types. 

=item stype 

I<$type> = I<$Prop> -> stype()

Returns the scalar type of property $Prop. This is useful if $Prop is an
array and you want to know, what kind of variables it consists of.

=item type

I<$type> = I<$Prop> -> type()

Returns the type of the Property. It is a number if it is a real property
type, and it is a string, if it is an internal property type.

=item typestr

I<$typestr> = I<$Prop> -> typestr()

Returns the name of the property type as string.

=back

=head1 KNOWN BUGS

Property handling is I<very> slow.

=head1 SEE ALSO

L<OLE::Storage::Var>, demonstration program "ldat"

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>. 

=cut

