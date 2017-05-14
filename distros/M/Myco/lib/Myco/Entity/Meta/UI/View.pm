package Myco::Entity::Meta::UI::View;

###############################################################################
# $Id: View.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::UI::View - a Myco entity class

=head1 SYNOPSIS

  use Myco::Entity::Meta::UI::View;

=head1 DESCRIPTION

Used by the myco entity framework. Don't hack it unless you know what
you're doing :_)

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;

##############################################################################
# Inheritance
##############################################################################
use base qw(Class::Tangram);

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
      { fields => {},
        layout => {},
      },
    }
  };

=head2 fields

 type: hash ref


=cut

=head2 layout

 type: array ref

=cut


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

None

=cut


1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Charles Owens <czbsd@cpan.org>

=head1 SEE ALSO

L<Myco::Entity::Meta::UI::View::Test|Myco::Entity::Meta::UI::View::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
