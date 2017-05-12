#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Entity.pm,v 1.2 1998/01/18 00:21:13 ken Exp $
#

package SGML::Entity;

use strict;
use Class::Visitor;

visitor_class 'SGML::Entity', 'Class::Visitor::Base', {
    'name' => '$',
    'data' => '$',		# if ext, will be valid if loaded
};

=head1 NAME

SGML::Entity - an entity defined in an SGML or XML document

=head1 SYNOPSIS

  $name = $entity->name;
  $data = $entity->data;

  $entity->iter;

  $entity->accept($visitor, ...);

  The following are defined for type compatibilty:

  $entity->as_string([$context, ...]);
  $entity->accept_gi($visitor, ...);
  $entity->children_accept($visitor, ...);
  $entity->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

An C<SGML::Entity> contains an entity defined in a document instance.
Within a grove, any entity with the same name refers to the same
C<SGML::Entity> object.

C<SGML::Entity> objects occur in a value of an element attribute or as
children of entities.

C<$entity-E<gt>name> returns the name of the Entity object.

C<$entity-E<gt>data> returns the data of the Entity object.

C<$entity-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_Entity($entity[, ...])>>.  See examples
C<visitor.pl> and C<simple-dump.pl> for more information.

C<$entity-E<gt>as_string> returns an empty string.

C<$entity-E<gt>accept_gi($visitor[, ...])> is implemented as a synonym
for C<accept>.

C<children_accept> and C<children_accept_gi> do nothing.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), SGML::Grove(3), Text::EntityMap(3), SGML::Element(3),
SGML::PI(3).

=cut

sub as_string {
    my $self = shift;
    my $context = shift;

    return ("");
}

sub accept {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_Entity ($self, @_);
}

# synonomous to `accept'
sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_Entity ($self, @_);
}

# these are here just for type compatibility
sub children_accept { }
sub children_accept_gi { }
sub contents { return [] }

1;
