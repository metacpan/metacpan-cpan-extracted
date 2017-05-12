#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Vocabulary.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/15/2007
# Revision:	$Id: Vocabulary.pm,v 1.2 2009-11-25 17:46:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Vocabulary;

use strict;
use warnings;

use base qw/ODO/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_ro_accessors(qw/uri_map_table/);

sub uri_to_node {
	my ($self, $uri) = @_;
	
	$self = $self->new()
		unless(ref $self);
	
	return $self->uri_map_table()->{'nodes'}->{ $uri };
}

sub uri_to_name {
	my ($self, $uri) = @_;
	
	$self = $self->new()
		unless(ref $self);
	
	return $self->uri_map_table()->{'names'}->{ $uri };
}
sub init {
	my ($self, $config) = @_;
	$self->{'uri_map_table'} = {'nodes'=> {}, 'names'=> {}};
	return $self;
}

1;

__END__
