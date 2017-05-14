package Myco::Query::Part;

###############################################################################
# $Id: Part.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Query::Part - a Myco entity class

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Entity for more.
  my $obj = Myco::Query::Part->new;

  # Accessors:
  #   see attribute list below

  $obj->save;
  $obj->destroy;

=head1 DESCRIPTION

This class abstracts the idea of a B<part> of a L<Myco::QueryTemplate> object.
A part can be a filter (see L<Myco::Query::Part::Filter>) or clause
(L<Myco::Query::Part::Clause>). A filter can itself contain clauses, thereby
introducing the possibility (indeed, the routine requirement) of
recursiveness in the construction of a query object.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Myco::Entity::Meta;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################


##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw(Class::Tangram);
my $md = Myco::Entity::Meta->new( name => __PACKAGE__ );

###########################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Entity.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *

Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *

Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=head2 part_join_oper

 type: string  values: &, ||, 'and', 'or'

The perl (tangram) operator used to join one Myco::Query::Part object to the
next.

=cut

$md->add_attribute( name => 'part_join_oper',
                    type => 'transient',
                    values => [ qw(& |) ],
                    value_labels => { '&' => 'and',
                                      '|' => 'or' },
                  );


=head2 optional

 type: int  values: 1, 0 (yes/no)

Boolean value indicating whether the given query clause (and its attendant
parameters) is optional.

=cut

$md->add_attribute( name => 'optional',
                    type => 'yesno', );



##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Query::Part::Test|Myco::Query::Part::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
