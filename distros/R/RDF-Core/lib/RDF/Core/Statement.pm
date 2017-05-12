# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Statement;

use strict;

require Exporter;

use Carp;

sub new {
    my ($pkg,$subject, $predicate, $object)=@_;
    $pkg = ref $pkg || $pkg;
    my $self={};

    $self->{_subject} = $subject;
    $self->{_predicate} = $predicate;
    $self->{_object} = $object;
    bless $self,$pkg;
}
sub getSubject {
    my $self = shift;
    return $self->{_subject};
}
sub getPredicate {
    my $self = shift;
    return $self->{_predicate};
}
sub getObject {
    my $self = shift;
    return $self->{_object};
}
sub getLabel {
    my $self = shift;
    my $rval;
    my $subjectLabel = $self->getSubject()->getURI();
    unless ($subjectLabel =~ /^_:/) {
	$subjectLabel = '<' .$subjectLabel.'> ';
    }
    $rval = $subjectLabel;
    $rval .= '<' . $self->getPredicate()->getURI() . '> ';
    if ($self->getObject()->isLiteral()) {
	my $literal = $self->getObject()->getValue();
	$literal =~ s/\\/\\\\/g;
	$literal =~ s/\n/\\n/g;
	$literal =~ s/\r/\\r/g;
	$literal =~ s/\t/\\t/g;
	$literal =~ s/"/\\"/g;
	$rval .= '"' . $literal . '"';
	if (my $lang=$self->getObject()->getLang()) {
	    $rval .= "\@$lang"
	}
	if (my $datatype=$self->getObject()->getDatatype()) {
	    $rval .= "^^<$datatype>"
	}
    } else {	
	my $objectLabel = $self->getObject()->getURI();
	unless ($objectLabel =~ /^_:/) {
	    $objectLabel = '<' .$objectLabel.'> ';
	}
	$rval .= $objectLabel;
    }
    ;
    $rval .= "." ;
    return $rval;
}
sub clone {
    my $self = shift;
    return  $self->new($self->getSubject->clone, 
		       $self->getPredicate->clone, 
		       $self->getObject->clone);
}
1;
__END__

=head1 NAME

RDF::Core::Statement - RDF statement

=head1 SYNOPSIS

  require RDF::Core::Statement;

  my $subject = new RDF::Core::Resource('http://www.gingerall.cz/employees/Jim');
  my $predicate = $subject->new('http://www.gingerall.cz/rdfns#name');
  my $object = new RDF::Core::Literal('Jim Brown');

  my $statement = new RDF::Core::Statement($subject, $predicate, $object);

  print $statement->getObject->getLabel."\n"

=head1 DESCRIPTION



=head2 Interface

=over 4

=item * new($subject, $predicate, $object)

Variables $subject and $predicate are resources, $object can be resource or literal

=item * getSubject

=item * getPredicate

=item * getObject

=item * getLabel

returns a content of statement in n-triple format.

=item * clone

returns copy of statement

=back


=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Resource, RDF::Core::Literal

=cut
