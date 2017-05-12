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

package RDFStore::Vocabulary::DAML;
{
use vars qw ( $VERSION $Class $Datatype $Thing $Nothing $equivalentTo $Property $sameClassAs $samePropertyAs $sameIndividualAs $disjointWith $differentIndividualFrom $unionOf $List $disjointUnionOf $intersectionOf $complementOf $oneOf $Restriction $onProperty $toClass $hasValue $hasClass $minCardinality $maxCardinality $cardinality $hasClassQ $minCardinalityQ $maxCardinalityQ $cardinalityQ $ObjectProperty $DatatypeProperty $inverseOf $TransitiveProperty $UniqueProperty $UnambiguousProperty $nil $first $rest $item $Ontology $versionInfo $imports $subPropertyOf $Literal $type $value $subClassOf $domain $range $label $comment $seeAlso $isDefinedBy );
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
$RDFStore::Vocabulary::DAML::_Namespace= "http://www.daml.org/2001/03/daml+oil#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::DAML::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	#      The class of all "object" classes   
	$RDFStore::Vocabulary::DAML::Class = createResource($_[0], "Class");
	#      The class of all datatype classes   
	$RDFStore::Vocabulary::DAML::Datatype = createResource($_[0], "Datatype");
	#      The most general (object) class in DAML.     This is equal to the union of any class and its complement.   
	$RDFStore::Vocabulary::DAML::Thing = createResource($_[0], "Thing");
	# the class with no things in it.
	$RDFStore::Vocabulary::DAML::Nothing = createResource($_[0], "Nothing");
	#      for equivalentTo(X, Y), read X is an equivalent term to Y.   
	$RDFStore::Vocabulary::DAML::equivalentTo = createResource($_[0], "equivalentTo");
	$RDFStore::Vocabulary::DAML::Property = createResource($_[0], "Property");
	#      for sameClassAs(X, Y), read X is an equivalent class to Y.     cf OIL Equivalent   
	$RDFStore::Vocabulary::DAML::sameClassAs = createResource($_[0], "sameClassAs");
	#      for samePropertyAs(P, R), read P is an equivalent property to R.   
	$RDFStore::Vocabulary::DAML::samePropertyAs = createResource($_[0], "samePropertyAs");
	#      for sameIndividualAs(a, b), read a is the same individual as b.   
	$RDFStore::Vocabulary::DAML::sameIndividualAs = createResource($_[0], "sameIndividualAs");
	#      for disjointWith(X, Y) read: X and Y have no members in common.     cf OIL Disjoint   
	$RDFStore::Vocabulary::DAML::disjointWith = createResource($_[0], "disjointWith");
	#      for differentIndividualFrom(a, b), read a is not the same individual as b.   
	$RDFStore::Vocabulary::DAML::differentIndividualFrom = createResource($_[0], "differentIndividualFrom");
	#      for unionOf(X, Y) read: X is the union of the classes in the list Y;     i.e. if something is in any of the classes in Y, it's in X, and vice versa.     cf OIL OR   
	$RDFStore::Vocabulary::DAML::unionOf = createResource($_[0], "unionOf");
	$RDFStore::Vocabulary::DAML::List = createResource($_[0], "List");
	#      for disjointUnionOf(X, Y) read: X is the disjoint union of the classes in     the list Y: (a) for any c1 and c2 in Y, disjointWith(c1, c2),     and (b) unionOf(X, Y). i.e. if something is in any of the classes in Y, it's     in X, and vice versa.     cf OIL disjoint-covered   
	$RDFStore::Vocabulary::DAML::disjointUnionOf = createResource($_[0], "disjointUnionOf");
	#      for intersectionOf(X, Y) read: X is the intersection of the classes in the list Y;     i.e. if something is in all the classes in Y, then it's in X, and vice versa.     cf OIL AND   
	$RDFStore::Vocabulary::DAML::intersectionOf = createResource($_[0], "intersectionOf");
	#      for complementOf(X, Y) read: X is the complement of Y; if something is in Y,     then it's not in X, and vice versa.     cf OIL NOT   
	$RDFStore::Vocabulary::DAML::complementOf = createResource($_[0], "complementOf");
	#       for oneOf(C, L) read everything in C is one of the      things in L;      This lets us define classes by enumerating the members.      cf OIL OneOf   
	$RDFStore::Vocabulary::DAML::oneOf = createResource($_[0], "oneOf");
	#      something is in the class R if it satisfies the attached restrictions,      and vice versa.   
	$RDFStore::Vocabulary::DAML::Restriction = createResource($_[0], "Restriction");
	#      for onProperty(R, P), read:     R is a restricted with respect to property P.   
	$RDFStore::Vocabulary::DAML::onProperty = createResource($_[0], "onProperty");
	#      for onProperty(R, P) and toClass(R, X), read:     i is in class R if and only if for all j, P(i, j) implies type(j, X).     cf OIL ValueType   
	$RDFStore::Vocabulary::DAML::toClass = createResource($_[0], "toClass");
	#      for onProperty(R, P) and hasValue(R, V), read:     i is in class R if and only if P(i, V).     cf OIL HasFiller   
	$RDFStore::Vocabulary::DAML::hasValue = createResource($_[0], "hasValue");
	#      for onProperty(R, P) and hasClass(R, X), read:     i is in class R if and only if for some j, P(i, j) and type(j, X).     cf OIL HasValue   
	$RDFStore::Vocabulary::DAML::hasClass = createResource($_[0], "hasClass");
	#      for onProperty(R, P) and minCardinality(R, n), read:     i is in class R if and only if there are at least n distinct j with P(i, j).     cf OIL MinCardinality   
	$RDFStore::Vocabulary::DAML::minCardinality = createResource($_[0], "minCardinality");
	#      for onProperty(R, P) and maxCardinality(R, n), read:     i is in class R if and only if there are at most n distinct j with P(i, j).     cf OIL MaxCardinality   
	$RDFStore::Vocabulary::DAML::maxCardinality = createResource($_[0], "maxCardinality");
	#      for onProperty(R, P) and cardinality(R, n), read:     i is in class R if and only if there are exactly n distinct j with P(i, j).     cf OIL Cardinality   
	$RDFStore::Vocabulary::DAML::cardinality = createResource($_[0], "cardinality");
	#      property for specifying class restriction with cardinalityQ constraints   
	$RDFStore::Vocabulary::DAML::hasClassQ = createResource($_[0], "hasClassQ");
	#      for onProperty(R, P), minCardinalityQ(R, n) and hasClassQ(R, X), read:     i is in class R if and only if there are at least n distinct j with P(i, j)      and type(j, X).     cf OIL MinCardinality   
	$RDFStore::Vocabulary::DAML::minCardinalityQ = createResource($_[0], "minCardinalityQ");
	#      for onProperty(R, P), maxCardinalityQ(R, n) and hasClassQ(R, X), read:     i is in class R if and only if there are at most n distinct j with P(i, j)     and type(j, X).     cf OIL MaxCardinality   
	$RDFStore::Vocabulary::DAML::maxCardinalityQ = createResource($_[0], "maxCardinalityQ");
	#      for onProperty(R, P), cardinalityQ(R, n) and hasClassQ(R, X), read:     i is in class R if and only if there are exactly n distinct j with P(i, j)     and type(j, X).     cf OIL Cardinality   
	$RDFStore::Vocabulary::DAML::cardinalityQ = createResource($_[0], "cardinalityQ");
	#      if P is an ObjectProperty, and P(x, y), then y is an object.   
	$RDFStore::Vocabulary::DAML::ObjectProperty = createResource($_[0], "ObjectProperty");
	#      if P is a DatatypeProperty, and P(x, y), then y is a data value.   
	$RDFStore::Vocabulary::DAML::DatatypeProperty = createResource($_[0], "DatatypeProperty");
	#      for inverseOf(R, S) read: R is the inverse of S; i.e.     if R(x, y) then S(y, x) and vice versa.     cf OIL inverseRelationOf   
	$RDFStore::Vocabulary::DAML::inverseOf = createResource($_[0], "inverseOf");
	#      if P is a TransitiveProperty, then if P(x, y) and P(y, z) then P(x, z).     cf OIL TransitiveProperty.   
	$RDFStore::Vocabulary::DAML::TransitiveProperty = createResource($_[0], "TransitiveProperty");
	#      compare with maxCardinality=1; e.g. integer successor:     if P is a UniqueProperty, then if P(x, y) and P(x, z) then y=z.     cf OIL FunctionalProperty.   
	$RDFStore::Vocabulary::DAML::UniqueProperty = createResource($_[0], "UniqueProperty");
	#      if P is an UnambiguousProperty, then if P(x, y) and P(z, y) then x=z.     aka injective. e.g. if firstBorne(m, Susan)     and firstBorne(n, Susan) then m and n are the same.   
	$RDFStore::Vocabulary::DAML::UnambiguousProperty = createResource($_[0], "UnambiguousProperty");
	#       the empty list; this used to be called Empty.   
	$RDFStore::Vocabulary::DAML::nil = createResource($_[0], "nil");
	$RDFStore::Vocabulary::DAML::first = createResource($_[0], "first");
	$RDFStore::Vocabulary::DAML::rest = createResource($_[0], "rest");
	#      for item(L, I) read: I is an item in L; either first(L, I)     or item(R, I) where rest(L, R).   
	$RDFStore::Vocabulary::DAML::item = createResource($_[0], "item");
	#      An Ontology is a document that describes     a vocabulary of terms for communication between     (human and) automated agents.   
	$RDFStore::Vocabulary::DAML::Ontology = createResource($_[0], "Ontology");
	#      generally, a string giving information about this     version; e.g. RCS/CVS keywords   
	$RDFStore::Vocabulary::DAML::versionInfo = createResource($_[0], "versionInfo");
	#      for imports(X, Y) read: X imports Y;     i.e. X asserts the* contents of Y by reference;     i.e. if imports(X, Y) and you believe X and Y says something,     then you should believe it.     Note: "the contents" is, in the general case,     an il-formed definite description. Different     interactions with a resource may expose contents     that vary with time, data format, preferred language,     requestor credentials, etc. So for "the contents",     read "any contents".   
	$RDFStore::Vocabulary::DAML::imports = createResource($_[0], "imports");
	$RDFStore::Vocabulary::DAML::subPropertyOf = createResource($_[0], "subPropertyOf");
	$RDFStore::Vocabulary::DAML::Literal = createResource($_[0], "Literal");
	$RDFStore::Vocabulary::DAML::type = createResource($_[0], "type");
	$RDFStore::Vocabulary::DAML::value = createResource($_[0], "value");
	$RDFStore::Vocabulary::DAML::subClassOf = createResource($_[0], "subClassOf");
	$RDFStore::Vocabulary::DAML::domain = createResource($_[0], "domain");
	$RDFStore::Vocabulary::DAML::range = createResource($_[0], "range");
	$RDFStore::Vocabulary::DAML::label = createResource($_[0], "label");
	$RDFStore::Vocabulary::DAML::comment = createResource($_[0], "comment");
	$RDFStore::Vocabulary::DAML::seeAlso = createResource($_[0], "seeAlso");
	$RDFStore::Vocabulary::DAML::isDefinedBy = createResource($_[0], "isDefinedBy");
};
sub END {
	$RDFStore::Vocabulary::DAML::Class = undef;
	$RDFStore::Vocabulary::DAML::Datatype = undef;
	$RDFStore::Vocabulary::DAML::Thing = undef;
	$RDFStore::Vocabulary::DAML::Nothing = undef;
	$RDFStore::Vocabulary::DAML::equivalentTo = undef;
	$RDFStore::Vocabulary::DAML::Property = undef;
	$RDFStore::Vocabulary::DAML::sameClassAs = undef;
	$RDFStore::Vocabulary::DAML::samePropertyAs = undef;
	$RDFStore::Vocabulary::DAML::sameIndividualAs = undef;
	$RDFStore::Vocabulary::DAML::disjointWith = undef;
	$RDFStore::Vocabulary::DAML::differentIndividualFrom = undef;
	$RDFStore::Vocabulary::DAML::unionOf = undef;
	$RDFStore::Vocabulary::DAML::List = undef;
	$RDFStore::Vocabulary::DAML::disjointUnionOf = undef;
	$RDFStore::Vocabulary::DAML::intersectionOf = undef;
	$RDFStore::Vocabulary::DAML::complementOf = undef;
	$RDFStore::Vocabulary::DAML::oneOf = undef;
	$RDFStore::Vocabulary::DAML::Restriction = undef;
	$RDFStore::Vocabulary::DAML::onProperty = undef;
	$RDFStore::Vocabulary::DAML::toClass = undef;
	$RDFStore::Vocabulary::DAML::hasValue = undef;
	$RDFStore::Vocabulary::DAML::hasClass = undef;
	$RDFStore::Vocabulary::DAML::minCardinality = undef;
	$RDFStore::Vocabulary::DAML::maxCardinality = undef;
	$RDFStore::Vocabulary::DAML::cardinality = undef;
	$RDFStore::Vocabulary::DAML::hasClassQ = undef;
	$RDFStore::Vocabulary::DAML::minCardinalityQ = undef;
	$RDFStore::Vocabulary::DAML::maxCardinalityQ = undef;
	$RDFStore::Vocabulary::DAML::cardinalityQ = undef;
	$RDFStore::Vocabulary::DAML::ObjectProperty = undef;
	$RDFStore::Vocabulary::DAML::DatatypeProperty = undef;
	$RDFStore::Vocabulary::DAML::inverseOf = undef;
	$RDFStore::Vocabulary::DAML::TransitiveProperty = undef;
	$RDFStore::Vocabulary::DAML::UniqueProperty = undef;
	$RDFStore::Vocabulary::DAML::UnambiguousProperty = undef;
	$RDFStore::Vocabulary::DAML::nil = undef;
	$RDFStore::Vocabulary::DAML::first = undef;
	$RDFStore::Vocabulary::DAML::rest = undef;
	$RDFStore::Vocabulary::DAML::item = undef;
	$RDFStore::Vocabulary::DAML::Ontology = undef;
	$RDFStore::Vocabulary::DAML::versionInfo = undef;
	$RDFStore::Vocabulary::DAML::imports = undef;
	$RDFStore::Vocabulary::DAML::subPropertyOf = undef;
	$RDFStore::Vocabulary::DAML::Literal = undef;
	$RDFStore::Vocabulary::DAML::type = undef;
	$RDFStore::Vocabulary::DAML::value = undef;
	$RDFStore::Vocabulary::DAML::subClassOf = undef;
	$RDFStore::Vocabulary::DAML::domain = undef;
	$RDFStore::Vocabulary::DAML::range = undef;
	$RDFStore::Vocabulary::DAML::label = undef;
	$RDFStore::Vocabulary::DAML::comment = undef;
	$RDFStore::Vocabulary::DAML::seeAlso = undef;
	$RDFStore::Vocabulary::DAML::isDefinedBy = undef;
};
1;
};
