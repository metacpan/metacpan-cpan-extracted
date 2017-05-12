#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/RDFS/Vocabulary.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  03/02/2005
# Revision:	$Id: Vocabulary.pm,v 1.7 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::RDFS::Vocabulary;

use strict;
use warnings;

use ODO::Node;

use base qw/ODO::Ontology::Vocabulary/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

use XML::Namespace
	rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	rdfs => 'http://www.w3.org/2000/01/rdf-schema#';

our $RDF = rdf->uri();
our $RDFS = rdfs->uri();

our $RDF_METHODS;
our $RDFS_METHODS;

our $RDFS_SCHEMA_DATA=<<EOT;
<!-- 
The RDFS Schema contained below was exerpted from:

	http://www.w3.org/TR/2004/REC-rdf-schema-20040210/
	Copyright (C) 2004 W3C (R) (MIT,  ERCIM  , Keio), All Rights Reserved.	
	W3C liability, trademark, document use and software licensing rules apply.
	
See http://www.w3.org/Consortium/Legal/2002/copyright-documents-20021231 for more 
information.

Document STATUS:  W3C Recommendation

-->
<rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:owl="http://www.w3.org/2002/07/owl#">

<owl:Ontology rdf:about="http://www.w3.org/2000/01/rdf-schema#"/>

<rdfs:Class rdf:about="http://www.w3.org/2000/01/rdf-schema#Resource">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>Resource</rdfs:label>
  <rdfs:comment>The class resource, everything.</rdfs:comment>
</rdfs:Class>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#type">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>type</rdfs:label>
  <rdfs:comment>The subject is an instance of a class.</rdfs:comment>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Class"/>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdfs:Class rdf:about="http://www.w3.org/2000/01/rdf-schema#Class">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>Class</rdfs:label>
  <rdfs:comment>The class of classes.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdfs:Class>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#subClassOf">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>subClassOf</rdfs:label>
  <rdfs:comment>The subject is a subclass of a class.</rdfs:comment>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Class"/>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Class"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#subPropertyOf">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>subPropertyOf</rdfs:label>
  <rdfs:comment>The subject is a subproperty of a property.</rdfs:comment>
  <rdfs:range rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"/>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"/>
</rdf:Property>

<rdfs:Class rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>Property</rdfs:label>
  <rdfs:comment>The class of RDF properties.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdfs:Class>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#comment">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>comment</rdfs:label>
  <rdfs:comment>A description of the subject resource.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Literal"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#label">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>label</rdfs:label>
  <rdfs:comment>A human-readable name for the subject.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Literal"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#domain">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>domain</rdfs:label>
  <rdfs:comment>A domain of the subject property.</rdfs:comment>
 <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Class"/>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#range">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>range</rdfs:label>
  <rdfs:comment>A range of the subject property.</rdfs:comment>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Class"/>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#seeAlso">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>seeAlso</rdfs:label>
  <rdfs:comment>Further information about the subject resource.</rdfs:comment>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:domain   rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#isDefinedBy">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:subPropertyOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#seeAlso"/>
  <rdfs:label>isDefinedBy</rdfs:label>
  <rdfs:comment>The defininition of the subject resource.</rdfs:comment>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdfs:Class rdf:about="http://www.w3.org/2000/01/rdf-schema#Literal">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>Literal</rdfs:label>
  <rdfs:comment>The class of literal values, eg. textual strings and integers.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdfs:Class>

<rdfs:Class rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>Statement</rdfs:label>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:comment>The class of RDF statements.</rdfs:comment>
</rdfs:Class>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#subject">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>subject</rdfs:label>
  <rdfs:comment>The subject of the subject RDF statement.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>predicate</rdfs:label>
  <rdfs:comment>The predicate of the subject RDF statement.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#object">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>object</rdfs:label>
  <rdfs:comment>The object of the subject RDF statement.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdfs:Class rdf:about="http://www.w3.org/2000/01/rdf-schema#Container">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>Container</rdfs:label>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:comment>The class of RDF containers.</rdfs:comment>
</rdfs:Class>

<rdfs:Class rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>Bag</rdfs:label>
  <rdfs:comment>The class of unordered containers.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Container"/>
</rdfs:Class>

<rdfs:Class rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>Seq</rdfs:label>
  <rdfs:comment>The class of ordered containers.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Container"/>
</rdfs:Class>

<rdfs:Class rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>Alt</rdfs:label>
  <rdfs:comment>The class of containers of alternatives.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Container"/>
</rdfs:Class>

<rdfs:Class rdf:about="http://www.w3.org/2000/01/rdf-schema#ContainerMembershipProperty">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>ContainerMembershipProperty</rdfs:label>
  <rdfs:comment>The class of container membership properties, rdf:_1, rdf:_2, ...,
                    all of which are sub-properties of 'member'.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"/>
</rdfs:Class>

<rdf:Property rdf:about="http://www.w3.org/2000/01/rdf-schema#member">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>member</rdfs:label>
  <rdfs:comment>A member of the subject resource.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#value">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>value</rdfs:label>
  <rdfs:comment>Idiomatic property used for structured values.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<!-- the following are new additions, Nov 2002 -->

<rdfs:Class rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#List">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>List</rdfs:label>
  <rdfs:comment>The class of RDF Lists.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/></rdfs:Class>

<rdf:List rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#nil">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>nil</rdfs:label>
  <rdfs:comment>The empty list, with no items in it. If the rest of a list is nil then the list has no more items in it.</rdfs:comment>
</rdf:List>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#first">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>first</rdfs:label>
  <rdfs:comment>The first item in the subject RDF list.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#List"/>
  <rdfs:range rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Property>

<rdf:Property rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#rest">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>rest</rdfs:label>
  <rdfs:comment>The rest of the subject RDF list after the first item.</rdfs:comment>
  <rdfs:domain rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#List"/>
  <rdfs:range rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#List"/>
</rdf:Property>

<rdfs:Class rdf:about="http://www.w3.org/2000/01/rdf-schema#Datatype">
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/2000/01/rdf-schema#"/>
  <rdfs:label>Datatype</rdfs:label>
  <rdfs:comment>The class of RDF datatypes.</rdfs:comment>
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Class"/>
</rdfs:Class>
	
<rdfs:Datatype rdf:about="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral">
  <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/01/rdf-schema#Literal"/> 
  <rdfs:isDefinedBy rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <rdfs:label>XMLLiteral</rdfs:label>
  <rdfs:comment>The class of XML literal values.</rdfs:comment>
</rdfs:Datatype>

<rdf:Description rdf:about="http://www.w3.org/2000/01/rdf-schema#">
  <rdfs:seeAlso rdf:resource="http://www.w3.org/2000/01/rdf-schema-more"/>
</rdf:Description>

</rdf:RDF>
<!-- End excerpt from http://www.w3.org/TR/2004/REC-rdf-schema-20040210/ -->
EOT

sub BEGIN {
	
	$RDF_METHODS = [
		# Classes
		'XMLLiteral',
		'Property',
		'Statement',
		'Bag',
		'Seq',
		'Alt',
		'List',
		
		# Properties
		'type',
		'first',
		'rest',
		'nil',
		'value',
		'statement',
		'subject',
		'predicate',
		'object',
	];

	$RDFS_METHODS = [
		# Classes
		'Resource',
		'Literal',
		'Class',
		'Datatype',
		'Container',
		
		# Properties
		'subClassOf',
		'subPropertyOf',
		'domain',
		'range',
		'label',
		'comment',
		'member',
		'seeAlso',
		'isDefinedBy',
		'ContainerMembershipProperty',
	];

	no strict;
	no warnings;
		
	# RDF URIs
	for my $field (@{ $RDF_METHODS }) {	
		my $name = __PACKAGE__ . "::$field";
		${ *$name } = ODO::Node::Resource->new(rdf->uri($field));
	}
	
	# RDFS URIs
	for my $field (@{ $RDFS_METHODS }) {
		my $name = __PACKAGE__ . "::$field";
		${ *$name } = ODO::Node::Resource->new(rdfs->uri($field));
	}
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	
	no strict "refs";
	
	for my $field (@{ $RDF_METHODS }) {
		$self->{'uri_map_table'}->{'names'}->{ rdf->uri($field) } = $field;
		my $name = __PACKAGE__ . "::$field";
		$self->{'uri_map_table'}->{'nodes'}->{ rdf->uri($field) } = ${ *$name };
	}
	
	for my $field (@{ $RDFS_METHODS }) {
		$self->{'uri_map_table'}->{'names'}->{ rdfs->uri($field) } = $field;
		my $name = __PACKAGE__ . "::$field";
		$self->{'uri_map_table'}->{'nodes'}->{ rdfs->uri($field) } = ${ *$name };
	}
	
	return $self;
}

1;

__END__
