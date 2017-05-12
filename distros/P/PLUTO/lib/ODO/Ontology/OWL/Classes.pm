#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Classes.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  06/09/2005
# Revision:	$Id: Classes.pm,v 1.2 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Classes;

use strict;
use warnings;

use ODO::Ontology::OWL::Fragments;
use ODO::Ontology::OWL::Lite::Properties;

use base qw/ODO::Ontology::OWL::Lite::Classes/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

sub fillClass {
	my $self = shift;
	
	$self = $self->SUPER::fillClass(@_);
	
	my $class = shift;
	my $classURI = $class->{'object'}->value();

	$class->{'union'} = $self->fragments()->getClassUnionOf($classURI);
}


sub init {
	my ($self, $conifg) = @_;
	return $self;
}


1;

__END__