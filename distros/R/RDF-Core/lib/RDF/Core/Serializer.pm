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

package RDF::Core::Serializer;

use strict;


use Carp;

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    carp "InlineURI parameter is deprecated" if $self->{_options}->{InlineURI};
    #Implemented options are:
    #getNamespaces, getSubjects, getStatements, existsStatement callback functions
    #output - output filehandle reference (a reference to a typeglob or FileHandle) or scalar variable reference (default \*STDOUT)
    $self->{_options} = \%options;
    $self->{_options}->{Output} = \*STDOUT
      unless defined $self->{_options}->{Output};
    # $self->{_options}->{BaseURI};
    $self->{_options}->{InlinePrefix} ||= 'genid'
      unless defined $self->{_options}->{InlinePrefix};
    $self->{_descriptions} = undef;
    $self->{_namespaces} = undef;
    $self->{_recursionlvl} = 0;
    $self->{_idAttr} = 1;
    $self->{_anonym} = undef;
    bless $self, $pkg;
}
  sub getOptions {
      my $self = shift;
      return $self->{_options};
  }
sub serialize {
    my $self = shift;
    #get options if passed
    $self->{_options} = $_[0]
      if (@_ gt 0);
    $self->_rdfOpen;
    my $description = $self->_descriptionNext;
    while (defined $description) {
	$self->_descriptionProcess($description);
	$description = $self->_descriptionNext;
    }
    $self->_rdfClose;
}
#callback functions
sub getNamespaces {
    my $self = shift;
    $self->{_namespaces} ||= &{$self->getOptions->{getNamespaces}}(@_);
    return $self->{_namespaces};
}
sub getSubjects {
    #Subjects are stored with 2 flags that say that corresponding description item was open/closed.
    #Array ($subject, openedFlag, closedFlag) will be called description not to mess with $subject itself (RDF::Core::Resource instance)
    my $self = shift;
    $self->{_descriptions} ||= &{$self->getOptions->{getSubjects}}(@_);
    return $self->{_descriptions};
}
sub getStatements {
    my $self = shift;
    return &{$self->getOptions->{getStatements}}(@_);
}
sub countStatements {
    my $self = shift;
    return &{$self->getOptions->{countStatements}}(@_);
}
sub existsStatement {
    my $self = shift;
    return &{$self->getOptions->{existsStatement}}(@_);
}
sub _rdfOpen {
    my $self = shift;
    my $namespaces = '';
    foreach (keys %{$self->getNamespaces()}) {
	$namespaces .= "xmlns:".$self->getNamespaces->{$_}."=\"$_\"\n";
    }
    $self->_print ("<rdf:RDF\n$namespaces>\n");
}
sub _rdfClose {
    my $self = shift;
    $self->_print ("</rdf:RDF>\n");
}
#get next description to be processed
sub _descriptionNext {
    my $self = shift;
    my $retval = undef;
    my %searched;
    #first, look for subjects that are not objects of any statement
    foreach (values %{$self->getSubjects}) {
	unless ($_->[1]) {	#search in not yet opened descriptions
	    unless ($self->existsStatement(undef,undef,$_->[0])) {
		$retval = $_;
		last;
	    }
	}
    }
    #then look for subjects that are objects of a statement already serialized
    unless ($retval) {
	foreach (values %{$self->getSubjects}) {
	    unless ($_->[1]) {	#search in not yet opened descriptions
		my $enum = $self->getStatements(undef,undef,$_->[0]);
		my $stmt = $enum->getNext;
		while (defined $stmt) {
		    if ($self->getSubjects->{$stmt->getSubject->getURI}->[2]) {
			$retval = $_;
			last;
		    }
		    $stmt = $enum->getNext;
		}
		$enum->close;
	    }
	    last if $retval;
	}
    }
    #at last, return any subject not serialized yet
    unless ($retval) {
	foreach (values %{$self->getSubjects}) {
	    unless ($_->[1]) {	#search in not yet opened descriptions
		$retval = $_;
		last;
	    }
	}
    }
    return $retval;
}
sub _descriptionProcess {
    my ($self, $description) = @_;
    $self->_descriptionOpen($description);
    my $enumerator = $self->getStatements($description->[0],undef,undef);
    my $statement = $enumerator->getNext;
    while (defined $statement) {
	$self->_descriptionData($statement);
	$statement = $enumerator->getNext;
    }
    $enumerator->close;
    $self->_descriptionClose($description);
}
sub _descriptionOpen {
    my ($self,$description) = @_;
    my $subjectID = $description->[0]->getURI;
    my $idAboutAttr;
    #Anonymous subject can be serialized as anonymous if it's an object of one or zero statements
    #and the referencing statement's subject has already been opened
    my $InlineURI = "_:";
    my $baseURI = $self->getOptions->{BaseURI};
    if ($subjectID =~ /^$InlineURI/i) {
	my $cnt = $self->countStatements(undef,undef,$description->[0]);
	if (!$cnt || ($self->{_recursionlvl} && $cnt < 2)){
	    $idAboutAttr = '';
	} else {
	    #deanonymize resource
	    my $idNew = $self->getOptions->{InlinePrefix}.$self->{idAttr}++;
	    $idAboutAttr = " rdf:nodeID=\"$idNew\"";
	    #carp "Giving attribute $idAboutAttr to blank node $subjectID.";
	    #store its ID to reference it in other statements
	    $self->{_anonym}->{$subjectID} = $idNew;
	}
    } elsif ($baseURI && $subjectID =~ /^$baseURI/i) {
	#relative URI - choose whether idAttr or aboutAttr should be produced
	#suggestion - produce aboutAttr every time
	my $id = $';
#	$id =~ s/^#//
#	  if $baseURI !~ /#$/;
	$idAboutAttr = " rdf:about=\"$'\"";
    } else {
	#absolute URI - produce aboutAttr
	$idAboutAttr = " rdf:about=\"$subjectID\"";
    }
    $idAboutAttr = $self->_escapeXML($idAboutAttr);
    $self->_print ("<rdf:Description$idAboutAttr>\n");
    $self->{_recursionlvl}++;
    $description->[1] = 1;
}
sub _descriptionClose {
    my ($self,$description) = @_;
    $self->{_recursionlvl}--;
    $self->_print ("</rdf:Description>\n");
    $description->[2] = 1;
}
sub _predicateOpen {
    my ($self,$statement,$inline) = @_; #inline says that nested resource should be scripted inline, not referenced
    my $prefix = $self->{_namespaces}->{$statement->getPredicate->getNamespace};
    my $propName = $prefix . ":".$statement->getPredicate->getLocalValue;
    my $propertyElt;
    if ($statement->getObject->isLiteral) {
	#don't express xml:lang if not necessary
	my $lang = $statement->getObject->getLang ? 
	  " xml:lang=\"".($statement->getObject->getLang)."\"" : "";
	my $datatype = $statement->getObject->getDatatype ? 
	  " rdf:datatype=\"".$statement->getObject->getDatatype."\"" : "";
	$propertyElt="<${propName}${lang}${datatype}>";
    } else {
	if ($inline) {
	    $propertyElt="<$propName>\n";
	} else {
	    my $objectURI = $statement->getObject->getURI;
	    my $resAttr = "rdf:resource";
	    if ($self->{_anonym}->{$objectURI}) {
		$objectURI = $self->{_anonym}->{$objectURI};
		$resAttr = "rdf:nodeID";
	    }
	    $propertyElt="<$propName $resAttr=\"".$self->_cutBaseURI($objectURI)."\"/>\n";
	}
    }
    $self->_print ($propertyElt);
}
sub _predicateClose {
    my ($self,$statement,$inline) = @_;
    my $prefix = $self->{_namespaces}->{$statement->getPredicate->getNamespace};
    my $propName = $prefix . ":".$statement->getPredicate->getLocalValue;
    my $propertyElt;
    if ($inline || $statement->getObject->isLiteral) {
	$propertyElt="</$propName>\n";
    } else {
	$propertyElt="";
    }
    $self->_print ($propertyElt);
}
sub _descriptionData {
    my ($self,$statement) = @_;
    if (!$statement->getObject->isLiteral && #object is resource
	defined $self->getSubjects->{$statement->getObject->getURI} && #and statement about the resource exists
	!$self->getSubjects->{$statement->getObject->getURI}->[1]) { #and is opened not yet
        $self->_predicateOpen($statement,1);
	$self->_descriptionProcess($self->getSubjects->{$statement->getObject->getURI});
	$self->_predicateClose($statement,1);
    } else {
	$self->_predicateOpen($statement,0);
	if ($statement->getObject->isLiteral) {
	    my $literal = $statement->getObject->getValue;
	    $self->_print($self->_escapeXML($literal));
	}
	$self->_predicateClose($statement,0);

    }
}
sub _print {
    my ($self,@params) = @_;
    if (ref($self->{_options}->{Output}) eq 'SCALAR') {
	foreach (@params) {
	    ${$self->getOptions->{Output}} .= $_;
	}
    } elsif (ref($self->{_options}->{Output}) =~ /^GLOB|^FileHandle/) {
	print {$self->getOptions->{Output}} @params;
    }

}
sub _cutBaseURI {
    my ($self, $uriRef) = @_;
    my $baseURI = $self->getOptions->{BaseURI};
    if ($baseURI) {
	$uriRef =~ s/^$baseURI//i;
    }
    return $uriRef;
}

sub _escapeXML {
    my ($self, $string) = @_;
    $string =~ s/\&/\&amp;/g;
    $string =~ s/\</\&lt;/g;
    return $string;
}

1;
__END__

=head1 NAME

RDF::Core::Serializer - produce XML code for RDF model

=head1 SYNOPSIS

  require RDF::Core::Serializer;

  my %options = (getSubjects => \&getSubjectsHandler,
                 getNamespaces => \&getNamespacesHandler,
                 getStatements => \&getStatementsHandler,
                 countStatements => \&countStatementsHandler,
                 existsStatement => \&existsStatementHandler,
                 BaseURI => 'http://www.foo.com/',
                );
  my $serializer = new RDF::Core::Serializer(%options);
  $serializer->serialize;

=head1 DESCRIPTION

Serializer takes RDF data provided by handlers and generates a XML document. Besides the trivial job of generating one description for one statement the serializer attempts to group statements with common subject into one description and makes referenced descriptions nested into referencing ones. Using baseURI option helps to keep relative resources instead of making them absolute. Blank nodes are preserved where possible, though the new rdf:nodeID attribute production is not implemented yet.

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * getSubjects

A reference to a subroutine that provides all distinct subjects in serialized model.

=item * getNamespaces

A reference to a subroutine that provides all predicates' namespaces.

=item * getStatements($subject, $predicate, $object)

A reference to a subroutine that provides all statements conforming given mask.

=item * existsStatement($subject, $predicate, $object)

A reference to a subroutine that returns true if a statement exists conforming the mask.

=item * Output

Output can be assigned a filehandle reference (a reference to a typeglob or FileHandle object), or a reference to a scalar variable. If a filehendle is set, serializer assumes it's open and valid, just prints there and doesn't close it. If a variable is set, XML is appended to it.
Serializer writes to STDOUT with default settings.

=item * BaseURI

A base URI of a document that is created. If a subject of a statement matches the URI, rdf:about attribute with relative URI is generated. 


=item * InlinePrefix

When rdf:nodeID attribute is assigned to an anonymous resource, it's generated as InlinePrefix concatenated with unique number. Unique is meant in the scope of the document. Default prefix is 'genid'. 

=back

=item * serialize

Does the job.

=back

=head2 Handlers

B<getSubjects> should return an array of references, each reference pointing to an array of one item ($subject), where $subject is a reference to RDF::Core::Resource. (I.e. C<$subject = $returnValue-E<gt>[$someElementOfArray]-E<gt>[0]>)

B<getNamespaces> should return a hash reference where keys are namespaces and values are namespace prefixes. There must be a rdf namespace present with value 'rdf'

B<getStatements($subject, $predicate, $object)> should return all statements that match given mask. That is the statements' subject is equal to $subject or $subject is not defined and the same for predicate and subject. Return value is a reference to RDF::Core::Enumerator object.

B<countStatements($subject, $predicate, $object)> should return number of statements that match given mask.

B<existsStatement($subject, $predicate, $object)> should return true if exists statement that matches given mask and false otherwise.

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

 FileHandle, RDF::Core::Model::Serializer, RDF::Core::Enumerator

=cut
