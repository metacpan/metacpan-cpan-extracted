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

package RDFStore::Vocabulary::RDF;
{
use vars qw ( $VERSION $type $Property $Statement $subject $predicate $object $Bag $Seq $Alt $value $List $nil $first $rest $XMLLiteral );
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
$RDFStore::Vocabulary::RDF::_Namespace= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::RDF::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# The subject is an instance of a class.
	$RDFStore::Vocabulary::RDF::type = createResource($_[0], "type");
	# The class of RDF properties.
	$RDFStore::Vocabulary::RDF::Property = createResource($_[0], "Property");
	# The class of RDF statements.
	$RDFStore::Vocabulary::RDF::Statement = createResource($_[0], "Statement");
	# The subject of the subject RDF statement.
	$RDFStore::Vocabulary::RDF::subject = createResource($_[0], "subject");
	# The predicate of the subject RDF statement.
	$RDFStore::Vocabulary::RDF::predicate = createResource($_[0], "predicate");
	# The object of the subject RDF statement.
	$RDFStore::Vocabulary::RDF::object = createResource($_[0], "object");
	# The class of unordered containers.
	$RDFStore::Vocabulary::RDF::Bag = createResource($_[0], "Bag");
	# The class of ordered containers.
	$RDFStore::Vocabulary::RDF::Seq = createResource($_[0], "Seq");
	# The class of containers of alternatives.
	$RDFStore::Vocabulary::RDF::Alt = createResource($_[0], "Alt");
	# Idiomatic property used for structured values.
	$RDFStore::Vocabulary::RDF::value = createResource($_[0], "value");
	# The class of RDF Lists.
	$RDFStore::Vocabulary::RDF::List = createResource($_[0], "List");
	# The empty list, with no items in it. If the rest of a list is nil then the list has no more items in it.
	$RDFStore::Vocabulary::RDF::nil = createResource($_[0], "nil");
	# The first item in the subject RDF list.
	$RDFStore::Vocabulary::RDF::first = createResource($_[0], "first");
	# The rest of the subject RDF list after the first item.
	$RDFStore::Vocabulary::RDF::rest = createResource($_[0], "rest");
	# The class of XML literal values.
	$RDFStore::Vocabulary::RDF::XMLLiteral = createResource($_[0], "XMLLiteral");
};
sub END {
	$RDFStore::Vocabulary::RDF::type = undef;
	$RDFStore::Vocabulary::RDF::Property = undef;
	$RDFStore::Vocabulary::RDF::Statement = undef;
	$RDFStore::Vocabulary::RDF::subject = undef;
	$RDFStore::Vocabulary::RDF::predicate = undef;
	$RDFStore::Vocabulary::RDF::object = undef;
	$RDFStore::Vocabulary::RDF::Bag = undef;
	$RDFStore::Vocabulary::RDF::Seq = undef;
	$RDFStore::Vocabulary::RDF::Alt = undef;
	$RDFStore::Vocabulary::RDF::value = undef;
	$RDFStore::Vocabulary::RDF::List = undef;
	$RDFStore::Vocabulary::RDF::nil = undef;
	$RDFStore::Vocabulary::RDF::first = undef;
	$RDFStore::Vocabulary::RDF::rest = undef;
	$RDFStore::Vocabulary::RDF::XMLLiteral = undef;
};
1;
};
