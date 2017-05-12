# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *

package RDFStore::Vocabulary::RDFS;
{
use vars qw ( $VERSION $Resource $Class $subClassOf $subPropertyOf $comment $Literal $label $domain $range $seeAlso $isDefinedBy $Container $ContainerMembershipProperty $member $Datatype );
$VERSION='0.41';
use strict;
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Vocabulary::Generator
#

# Namespace URI of this schema
$RDFStore::Vocabulary::RDFS::_Namespace= "http://www.w3.org/2000/01/rdf-schema#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::RDFS::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# The class resource, everything.
	$RDFStore::Vocabulary::RDFS::Resource = createResource($_[0], "Resource");
	# The class of classes.
	$RDFStore::Vocabulary::RDFS::Class = createResource($_[0], "Class");
	# The subject is a subclass of a class.
	$RDFStore::Vocabulary::RDFS::subClassOf = createResource($_[0], "subClassOf");
	# The subject is a subproperty of a property.
	$RDFStore::Vocabulary::RDFS::subPropertyOf = createResource($_[0], "subPropertyOf");
	# A description of the subject resource.
	$RDFStore::Vocabulary::RDFS::comment = createResource($_[0], "comment");
	# The class of literal values, eg. textual strings and integers.
	$RDFStore::Vocabulary::RDFS::Literal = createResource($_[0], "Literal");
	# A human-readable name for the subject.
	$RDFStore::Vocabulary::RDFS::label = createResource($_[0], "label");
	# A domain of the subject property.
	$RDFStore::Vocabulary::RDFS::domain = createResource($_[0], "domain");
	# A range of the subject property.
	$RDFStore::Vocabulary::RDFS::range = createResource($_[0], "range");
	# Further information about the subject resource.
	$RDFStore::Vocabulary::RDFS::seeAlso = createResource($_[0], "seeAlso");
	# The defininition of the subject resource.
	$RDFStore::Vocabulary::RDFS::isDefinedBy = createResource($_[0], "isDefinedBy");
	# The class of RDF containers.
	$RDFStore::Vocabulary::RDFS::Container = createResource($_[0], "Container");
	# The class of container membership properties, rdf:_1, rdf:_2, ...,                     all of which are sub-properties of 'member'.
	$RDFStore::Vocabulary::RDFS::ContainerMembershipProperty = createResource($_[0], "ContainerMembershipProperty");
	# A member of the subject resource.
	$RDFStore::Vocabulary::RDFS::member = createResource($_[0], "member");
	# The class of RDF datatypes.
	$RDFStore::Vocabulary::RDFS::Datatype = createResource($_[0], "Datatype");
};
sub END {
	$RDFStore::Vocabulary::RDFS::Resource = undef;
	$RDFStore::Vocabulary::RDFS::Class = undef;
	$RDFStore::Vocabulary::RDFS::subClassOf = undef;
	$RDFStore::Vocabulary::RDFS::subPropertyOf = undef;
	$RDFStore::Vocabulary::RDFS::comment = undef;
	$RDFStore::Vocabulary::RDFS::Literal = undef;
	$RDFStore::Vocabulary::RDFS::label = undef;
	$RDFStore::Vocabulary::RDFS::domain = undef;
	$RDFStore::Vocabulary::RDFS::range = undef;
	$RDFStore::Vocabulary::RDFS::seeAlso = undef;
	$RDFStore::Vocabulary::RDFS::isDefinedBy = undef;
	$RDFStore::Vocabulary::RDFS::Container = undef;
	$RDFStore::Vocabulary::RDFS::ContainerMembershipProperty = undef;
	$RDFStore::Vocabulary::RDFS::member = undef;
	$RDFStore::Vocabulary::RDFS::Datatype = undef;
};
1;
};
