#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: ExtEntity.pm,v 1.2 1998/01/18 00:21:13 ken Exp $
#

package SGML::ExtEntity;

use strict;
use Class::Visitor;

visitor_class 'SGML::ExtEntity', 'SGML::Entity', {
    'type' => '$',		# cdata, sdata, ndata
    'system_id' => '$',
    'public_id' => '$',
    'generated_id' => '$',
    'attributes' => '@',
    'notation' => '$',
};

=head1 NAME

SGML::ExtEntity - an external entity defined in an SGML or XML document

=head1 SYNOPSIS

  $name = $ext_entity->name;
  $data = $ext_entity->data;
  $type = $ext_entity->type;
  $system_id = $ext_entity->system_id;
  $public_id = $ext_entity->public_id;
  $generated_id = $ext_entity->generated_id;
  $attributes = $ext_entity->attributes;
  $notation = $ext_entity->notation;

  $ext_entity->iter;

  $ext_entity->accept($visitor, ...);

  The following are defined for type compatibilty:

  $ext_entity->as_string([$context, ...]);
  $ext_entity->accept_gi($visitor, ...);
  $ext_entity->children_accept($visitor, ...);
  $ext_entity->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

An C<SGML::ExtEntity> contains an external entity defined in a
document instance.  Within a grove, any entity with the same name
refers to the same C<SGML::ExtEntity> object.

C<$ext_entity-E<gt>name> returns the name of the external entity object.

C<$ext_entity-E<gt>data> returns the data of the entity if it has been
loaded (XXX but that's not been defined yet).

C<$ext_entity-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_ExtEntity($ext_entity[, ...])>>.  See
examples C<visitor.pl> and C<simple-dump.pl> for more information.

C<$ext_entity-E<gt>as_string> returns an empty string.

C<$ext_entity-E<gt>accept_gi($visitor[, ...])> is implemented as a synonym
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

    $visitor->visit_SGML_ExtEntity ($self, @_);
}

# synonomous to `accept'
sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_ExtEntity ($self, @_);
}

# these are here just for type compatibility
sub children_accept { }
sub children_accept_gi { }
sub contents { return [] }

1;
