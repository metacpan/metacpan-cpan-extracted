#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Grove.pm,v 1.1 1998/01/18 00:21:13 ken Exp $
#

package SGML::Grove;

use SGML::Element;
use SGML::SData;
use SGML::PI;
use SGML::Notation;
use SGML::Entity;
use SGML::ExtEntity;
use SGML::SubDocEntity;

use strict;
use vars qw($VERSION @ISA);
use Class::Visitor;

visitor_class 'SGML::Grove', 'Class::Visitor::Base',
    [
     'errors' => '@',		# [0]
     'entities' => '%',		# [1]
     'notations' => '%',	# [2]
     'contents' => '@',		# [3]
];

package SGML::Grove;

$VERSION = '2.03';

sub root {
    my $self = shift;

    return $self->contents->[0];
}

# synonomous to `accept'
sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_Grove ($self, @_);
}

sub children_accept_gi {
    my $self = shift;

    $self->root->accept_gi (@_);
}

1;
__END__

=head1 NAME

SGML::Grove - an SGML, XML, or HTML document

=head1 SYNOPSIS

  use SGML::Grove;
  $grove = A::GroveBuilder->new ($sysid);
  $root = $grove->root;
  $errors = $grove->errors;
  $entities = $grove->entities;
  $notations = $grove->notations;

  $grove->as_string([$context, ...]);

  $grove->iter;

  $grove->accept($visitor, ...);
  $grove->accept_gi($visitor, ...);
  $grove->children_accept($visitor, ...);
  $grove->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

C<SGML::Grove> represents a loaded document instance returned from a
grove building or parsing module, i.e. for SGML documents this may be
SGML::SPGroveBuilder.  The returned grove contains the root, or top,
element of the document and an array of any warnings or errors that
may have been generated while parsing the document.

C<$grove-E<gt>root> returns the C<SGML::Element> of the outermost
element of the document.

C<$grove-E<gt>errors> returns a reference to an array containing any
errors generated while parsing the document.

C<$grove-E<gt>entities> returns a reference to a hash containing any
entities referenced in this grove (as opposed to entities that may
have been declared but not used).

C<$grove-E<gt>notations> returns a reference to an array containing
any notations referenced in this grove.

C<$grove-E<gt>as_string> returns the entire grove as a string,
possibly modified by C<$context>.  See L<SGML::SData> and L<SGML::PI>
for more detail.

C<$grove->iter> returns an iterator for the grove object, see
C<Class::Visitor> for details.

C<$grove-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_Grove($element[, ...])>>.  See examples
C<visitor.pl> and C<simple-dump.pl> for more information.

C<$grove-E<gt>accept_gi($visitor[, ...])> is implemented as a synonym
for C<accept>.

C<children_accept> and C<children_accept_gi> call C<accept> and
C<accept_gi>, respectively, on the root element.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), Text::EntityMap(3), SGML::Element(3), SGML::SData(3),
SGML::PI(3), Class::Visitor(3).
<http://www.jclark.com/>

=cut
