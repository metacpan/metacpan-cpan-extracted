# 
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite/Restriction.pm,v $
# Created by:  Edward Kawas
# Created on:  16/10/2009
# Revision:	$Id: Restriction.pm,v 1.3 2009-11-25 17:58:26 ubuntu Exp $
#
#
package ODO::Ontology::OWL::Lite::Restriction;

use strict;
use warnings;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO/;
__PACKAGE__->mk_accessors(qw/onProperty propertyName restrictionURI minCardinality maxCardinality/);

sub init {
	my ( $self, $config ) = @_;
	$self->params( $config, qw/onProperty propertyName restrictionURI minCardinality maxCardinality/ );	
	return $self;
}
1;
__END__;
