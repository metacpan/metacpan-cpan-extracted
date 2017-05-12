#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: SData.pm,v 1.2 1998/01/18 00:21:15 ken Exp $
#

package SGML::SData;

use strict;
use Class::Visitor;

visitor_class 'SGML::SData', 'Class::Visitor::Base',
    [
     'data' => '@',		# [0]
     'name' => '$',		# [1]
];

=head1 NAME

SGML::SData - an SGML, XML, or HTML document SData replacement

=head1 SYNOPSIS

  $sdata = SGML::SData->new ($replacement[, $entity_name]);

  $name = $sdata->name;
  $data = $sdata->data;

  $sdata->as_string([$context, ...]);

  $sdata->iter;

  $sdata->accept($visitor, ...);
  $sdata->accept_gi($visitor, ...);
  $sdata->children_accept($visitor, ...);
  $sdata->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

An C<SGML::SData> contains the entity name and replacement value of a
character entity reference.

C<$sdata-E<gt>name> returns the entity name of the SData object.

C<$sdata-E<gt>data> returns the data of the SData object.

The Perl module C<Text::EntityMap> can be used to map commonly used
character entity sets to common output formats.

C<$sdata-E<gt>as_string([$context, ...])> returns C<data> surrounded
by brackets (`[ ... ]') unless C<$context-E<gt>{sdata_mapper}> is
defined, in which case it returns the result of calling the
C<sdata_mapper> subroutine with C<data> and the remaining arguments.
The actual implementation is:

    &{$context->{sdata_mapper}} ($self->data, @_);

C<$sdata-E<gt>iter> returns an iterator for the sdata object, see
C<Class::Visitor> for details.

C<$sdata-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_SData($sdata[, ...])>>.  See examples
C<visitor.pl> and C<simple-dump.pl> for more information.

C<$sdata-E<gt>accept_gi($visitor[, ...])> is implemented as a synonym
for C<accept>.

C<children_accept> and C<children_accept_gi> do nothing.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), SGML::Grove(3), Text::EntityMap(3), SGML::Element(3),
SGML::PI(3), Class::Visitor(3).

=cut

sub as_string {
    my $self = shift;
    my $context = shift;

    if (defined ($context->{'sdata_mapper'})) {
	return &{$context->{'sdata_mapper'}} ($self->data, @_);
    } else {
	return ("[" . $self->data . "]");
    }
}

sub accept {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_SData ($self, @_);
}

# synonomous to `accept'
sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_SData ($self, @_);
}

# these are here just for type compatibility
sub children_accept { }
sub children_accept_gi { }
sub contents { return [] }

1;
