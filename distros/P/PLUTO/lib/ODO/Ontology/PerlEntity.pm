#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/PerlEntity.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/11/2005
# Revision:	$Id: PerlEntity.pm,v 1.2 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::PerlEntity;

use strict;
use warnings;

use base qw/ODO/;

__PACKAGE__->mk_accessors(qw/ontology/);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

sub __is_perl_package {
	my ($self, $perl_test_structure) = @_;

	return 1
		if(UNIVERSAL::can($perl_test_structure, 'new'));
	
	return 0;
}


sub init {
	my ($self, $config) = @_;	
	$self->params($config, qw/ontology/);
	return $self;
}


1;

__END__
