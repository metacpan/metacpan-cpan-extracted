package Myco::Base::Entity::Meta::UI::List;

###############################################################################
# $Id: List.pm,v 1.1.1.1 2004/11/22 19:16:02 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::UI::List - a Myco entity class

=head1 VERSION

=over 4

=item Release

0.01

=cut

our $VERSION = 0.01;

=item Repository

$Revision$ $Date$

=back

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Base::Entity for more.
  my $obj = Myco::Base::Entity::Meta::UI::List->new;

  # Accessors.
  my $value = $obj->get_fooattrib;
  $obj->set_fooattrib($value);

  $obj->save;
  $obj->destroy;

=head1 DESCRIPTION

Blah blah blah... Blah blah blah... Blah blah blah...
Blah blah blah blah blah... Blah blah...

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################


##############################################################################
# Inheritance
##############################################################################
use base qw(Class::Tangram);

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Class::Tangram

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *  Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *  Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=cut

### Object Schema Definition
our $schema =
  {
   fields =>
    {
      transient =>
      { inline_sep => {},
	layout => {},
	type => {},
      },
    }
  };
Class::Tangram::import_schema(__PACKAGE__);

=head2 fooattrib

 type: string   default: 'hello'

A whole lot of nothing

=cut


=head2 barattrib

 type: int   required: not undef

Almost, but not quite, something.

=cut


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 foometh

  Myco::Base::Entity::Meta::UI::List->foometh(attribute => value, ...)

blah blah blah

=cut

#sub foometh {}


=head2 barmeth

  $obj->barmeth(attribute => $value, ...)

blah blah blah

=cut

#sub barmeth {}


1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::Meta::UI::List::Test|Myco::Base::Entity::Meta::UI::List::Test>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
