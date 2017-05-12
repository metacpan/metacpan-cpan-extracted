#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Vocabulary.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  05/23/2005
# Revision:	$Id: Vocabulary.pm,v 1.4 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Vocabulary;

use strict;
use warnings;
no warnings 'redefine';
use XML::Namespace
	jena => 'http://jena.hpl.hp.com/2003/04/DB#';
use warnings 'redefine';
use ODO::Node;

use base qw/ODO::Vocabulary/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;
our $METHODS;

sub BEGIN {

	$METHODS = [
		'SystemGraph',
		'LayoutVersion',
		'EngineType',
		'DriverVersion',
		'FormatDate',
		'Graph',
		
		'LongObjectLength',
		'IndexKeyLength',
		'IsTransactionDb',
		'DoCompressURI',
		'CompressURILength',
		'TableNamePrefix',
		
		'GraphName',
		'GraphType',
		'GraphLSet',
		'GraphPrefix',
		'GraphId',
		'GraphDBSchema',
		'StmtTable',
		'ReifTable',
		
		'PrefixValue',
		'PrefixURI',
		
		'LSetName',
		'LSetType',
		'LSetPSet',
		
		'PSetName',
		'PSetType',
		'PSetTable',
		
		'undefined',
	];
	
	no strict;
	no warnings;
		
	# RDF URIs
	for my $field (@{ $METHODS }) {	
		my $name = __PACKAGE__ . "::$field";
		${ *$name } = ODO::Node::Resource->new(jena->uri($field));
	}	
}


1;

__END__
