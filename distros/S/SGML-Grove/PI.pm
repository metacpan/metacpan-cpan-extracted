#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: PI.pm,v 1.2 1998/01/18 00:21:15 ken Exp $
#

# Internally, an SGML::PI is blessed scalar
# See below for Iter package definition.

package SGML::PI;

use strict;

=head1 NAME

SGML::PI - an SGML, XML, or HTML document processing instruction

=head1 SYNOPSIS

  $data = $pi->data;

  $pi->as_string([$context, ...]);

  $pi->iter;

  $pi->accept($visitor, ...);
  $pi->accept_gi($visitor, ...);
  $pi->children_accept($visitor, ...);
  $pi->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

An C<SGML::PI> contains the data in a Processing Instruction (PI).

C<$pi-E<gt>data> returns the data of the PI object.

C<$pi-E<gt>as_string> returns an empty string.

C<$pi-E<gt>iter> returns an iterator for the PI object, see
C<Class::Visitor> for details.

C<$pi-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_PI($sdata[, ...])>>.  See examples
C<visitor.pl> and C<simple-dump.pl> for more information.

C<$pi-E<gt>accept_gi($visitor[, ...])> is implemented as a synonym
for C<accept>.

C<children_accept> and C<children_accept_gi> do nothing.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), SGML::Grove(3), Text::EntityMap(3), SGML::Element(3),
SGML::SData(3), Class::Visitor(3).

=cut

sub data {
    return ${$_[0]};
}

sub as_string {
    my $self = shift;
    my $context = shift;

    return ("");
}

sub accept {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_PI ($self, @_);
}

# synonomous to `accept'
sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    $visitor->visit_SGML_PI ($self, @_);
}

# these are here just for type compatibility
sub children_accept { }
sub children_accept_gi { }
sub contents { return [] }

package SGML::PI::Iter;
use vars qw{@ISA};
@ISA = qw{Class::Iter};

1;
