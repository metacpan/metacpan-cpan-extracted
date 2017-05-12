# --8<--8<--8<--8<--
#
# Copyright (C) 2012 Smithsonian Astrophysical Observatory
#
# This file is part of MooX-Attributes-Shadow
#
# MooX-Attributes-Shadow is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package MooX::Attributes::Shadow::Role;

use strict;

our $VERSION = '0.02';

use Moo::Role;

use MooX::Attributes::Shadow ':all';

## no critic (ProhibitSubroutinePrototypes)
sub shadowable_attrs (@) {

    my $attrs = [@_];

    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    no warnings 'redefine';

    *{ caller() . '::shadowable_attrs' } = sub (@) { @{$attrs} };

    return;
}

sub new_from_attrs (@) {

    my $contained = shift;

    my $container = shift;

    # handle the following cases:
    # @args = ( \%options );
    # @args = ( \%options, %attr );
    # @args = ( \%options, \%attrs );
    # @args = ( %attr );

    my $options = {};
    my %attrs;

    if ( @_ == 1 ) {

	$options = shift;

    }

    elsif ( @_ == 2 && 'HASH' eq ref $_[0] && 'HASH' eq ref $_[1] ) {

	$options = shift;
	%attrs = %{ shift() };

    }

    elsif ( @_ % 2 ) {

	$options = shift;
	%attrs = @_;

    }

    else {

	%attrs = @_;

    }

    return $contained->new( $contained->xtract_attrs( $container, $options ), %attrs );
}

1;


__END__

=head1 NAME

MooX::Attributes::Shadow::Role - enumerate shadowable attributes in a contained class

=head1 SYNOPSIS

  # in the contained class
  package Foo;
  use Moo;
  with 'MooX::Attributes::Shadow::Role';

  shadowable_attrs 'x', 'y';

  has x => ( is => 'ro' );
  has y => ( is => 'ro' );


  # in the container class

  package Bar;

  use Moo;
  use Foo;

  # create accessors with a prefix to avoid collisions; no need to
  # specify which ones
  Foo->shadow_attrs( fmt => sub { 'pfx_' . shift } );

  # create an attribute which holds the contained oject, and
  # delegate the shadowed accessors to it.
  has foo   => ( is => 'ro',
                 lazy => 1,
                 default => sub { Foo->new_from_attrs( shift ) },
                 handles => Foo->shadowed_attrs,
               );


=head1 DESCRIPTION

B<MooX::Attributes::Shadow::Role> provides a means for a class to
identify attributes which should be shadowed to classes which contain
it.  (See B<MooX::Attributes::Shadow> for more on what this means).
A class containing a class composed with this role need know nothing about
the attributes which will be shadowed, and can use the class methods to
integrate the shadowable attributes into their interface.


=head1 INTERFACE

=head2 Contained class functions

=over

=item B<shadowable_attrs>

  shadowable_attrs @attrs;

This is called by the contained class to identify which attributes are
available for shadowing.  It does B<not> create them, it merely
records them.

Subsequent calls will return the names of the attributes which may be
shadowed as an array:

   Class->shadowable_attrs( qw[ a b c ] );
   @attrs = Class->shadowable_attrs;


=back


=head2 Class methods for use by the Container Classes

=over

=item B<shadow_attrs>

   ContainedClass->shadow_attrs( %options );

This method creates read-only attributes shadowing the
I<ContainedClass>'s shadowable attributes in the class which calls it.

It takes the following options:

=over

=item fmt

This is a reference to a subroutine which should return a modified
attribute name (e.g. to prevent attribute collisions).  It is passed
the attribute name as its first parameter.

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=item private

If true, the actual attribute name is mangled; the attribute
initialization name is left untouched (see the C<init_arg> option to
the B<Moo> C<has> subroutine).  This defaults to true.

=back

=item B<shadowed_attrs>

  $attrs = ContainedClass->( [$container,] \%options );

Return a hash of attributes shadowed into C<$container>.  If
C<$container> is provided it may be either a class name or an
object. If it is not provided, the package name of the calling routine
is used.

It takes the following options:

=over

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=back

The keys in the returned hash are the attribute initialization names
(not the mangled ones) in the I<container> class; the hash values are
the attribute names in the I<contained> class.  This makes it easy to
delegate accessors to the contained class:

  has foo   => ( is => 'ro',
                 lazy => 1,
                 default => sub { Foo->new( Foo->xtract_attrs( shift ) ) },
                 handles => Foo->shadowed_attrs,
               );

=item B<xtract_attrs>

  %attrs = ContainedClass->xtract_attrs( $container_obj, \%options );

After the container class is instantiated, B<xtract_attrs> is used to
extract attributes for the contained object from the container object.

It takes the following options:

=over

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=back

=item B<new_from_attrs>

  $obj = ContainedClass->new_from_attrs( $container_obj );
  $obj = ContainedClass->new_from_attrs( $container_obj, %attr );
  $obj = ContainedClass->new_from_attrs( $container_obj, \%options );
  $obj = ContainedClass->new_from_attrs( $container_obj, \%options, \%attr );
  $obj = ContainedClass->new_from_attrs( $container_obj, \%options,  %attr );

Create a new contained object from the attributes shadowed in the
container object.  Additional attributes and values may be passed.

It takes the following options:

=over

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=back


=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>
