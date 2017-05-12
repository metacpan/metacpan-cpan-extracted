#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Vocabulary.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  03/02/2005
# Revision:	$Id: Vocabulary.pm,v 1.9 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Vocabulary;

use strict;
use warnings;

use ODO::Node;

use XML::Namespace	owl => 'http://www.w3.org/2002/07/owl#';

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.10 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Ontology::Vocabulary/;

our $METHODS;

our $OWL = owl->uri();

sub BEGIN {
	
	$METHODS = [
		'Class',
		'Individual',
		'Thing',
		
		'equivalentClass',
		'equivalentProperty',
		'sameAs',
		'differentFrom',
		'AllDifferent',
		'distinctMembers',
		
		'ObjectProperty',
		'DatatypeProperty',
		'inverseOf',
		'TransitiveProperty',
		'SymmetricProperty',
		'FunctionalProperty',
		'InverseFunctionalProperty',
		
		'DataRange',
		'Restriction',
		'PropertyRestrictions',
		'onProperty',
		'allValuesFrom',
		'someValuesFrom',
		'hasValue',
		
		'minCardinality',
		'maxCardinality',
		'cardinality',
		
		'Ontology',
		'imports',
		
		'oneOf',
		'complementOf',
		'intersectionOf',
		'unionOf',
		
		'versionInfo',
		'priorVersion',
		'backwardCompatibleWith',
		'incompatibleWith',
		'DeprecatedClass',
		'DeprecatedProperty',
		
		'AnnotationProperty',
		'OntologyProperty',
	];
	
	no strict;
	no warnings;
	
	# OWL-Lite URIs
	for my $field (@{ $METHODS }) {
		${ *$field } = ODO::Node::Resource->new(owl->uri($field));
	}		
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	
	no strict "refs";
	
	for my $field (@{ $METHODS }) {
		$self->{'uri_map_table'}->{'names'}->{ owl->uri($field) } = $field;
		my $name = __PACKAGE__ . "::$field";
		$self->{'uri_map_table'}->{'nodes'}->{ owl->uri($field) } = ${ *$name };
	}
	return $self;
}

1;

__END__
