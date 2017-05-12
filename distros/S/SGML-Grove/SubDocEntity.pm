#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: SubDocEntity.pm,v 1.2 1998/01/18 00:21:17 ken Exp $
#

package SGML::ExtEntity;

use strict;
use Class::Visitor;

visitor_class 'SGML::SubDocEntity', 'SGML::Entity', {
    'system_id' => '$',
    'public_id' => '$',
    'generated_id' => '$',
    'attributes' => '@',
    'notation' => '$',
};

=head1 NAME

SGML::SubDocEntity - a SubDoc entity defined in an SGML or XML document

=head1 SYNOPSIS

  $name = $subdoc_entity->name;
  $data = $subdoc_entity->data;
  $system_id = $subdoc_entity->system_id;
  $public_id = $subdoc_entity->public_id;
  $generated_id = $subdoc_entity->generated_id;
  $attributes = $subdoc_entity->attributes;
  $notation = $subdoc_entity->notation;

  $subdoc_entity->iter;

  $subdoc_entity->accept($visitor, ...);

  The following are defined for type compatibilty:

  $subdoc_entity->as_string([$context, ...]);
  $subdoc_entity->accept_gi($visitor, ...);
  $subdoc_entity->children_accept($visitor, ...);
  $subdoc_entity->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

An C<SGML::SubDocEntity> contains a subdoc entity defined in a
document instance.  Within a grove, any entity with the same name
refers to the same C<SGML::SubDocEntity> object.

C<$subdoc_entity-E<gt>name> returns the entity name of the subdoc
entity object.

C<$subdoc_entity-E<gt>data> returns the grove object of the subdoc if
it has been loaded (XXX but that's not been defined yet).

C<$subdoc_entity-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_SubDocEntity($subdoc_entity[, ...])>>.
See examples C<visitor.pl> and C<simple-dump.pl> for more information.

C<$subdoc_entity-E<gt>as_string> returns an empty string.

C<$subdoc_entity-E<gt>accept_gi($visitor[, ...])> is implemented as a
synonym for C<accept>.

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

    # XXX hmm...
}

sub accept {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_SubDocEntity ($self, @_);
}

# synonomous to `accept'
sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_SubDocEntity ($self, @_);
}

# these are here just for type compatibility
sub children_accept { }
sub children_accept_gi { }
sub contents { return [] }

1;
