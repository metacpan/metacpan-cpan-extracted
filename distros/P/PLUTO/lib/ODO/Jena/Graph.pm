#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Graph.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/02/2004
# Revision:	$Id: Graph.pm,v 1.2 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Graph;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

our %DEFAULTS = (
	'graph_id'=> '0',
	'table_name_prefix'=> 'jena_',
	'properties_graph_name'=> 'JENA_DEFAULT_GRAPH_PROPERTIES',
);

our $SYSTEM_GRAPH_TABLE_NAME = 'sys_stmt';
our $LONG_LITERAL_TABLE_NAME = 'long_lit';
our $LONG_URI_TABLE_NAME = 'long_uri';
our $PREFIX_TABLE_NAME = 'prefix';
our $GRAPH_TABLE_NAME = 'graph';

our $DEFAULT_GRAPHID = '0';
our $DEFAULT_GRAPH_NAME = 'JENA_DEFAULT_GRAPH_PROPERTIES';

use base qw/ODO::Graph::Simple/;

=head1 NAME

ODO::Jena::Graph

=head1 SYNOPSIS

Synopsis

=head1 DESCRIPTION

Description

=head1 METHODS

=over

=back

=head1 JENA API METHODS

=over

=cut


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	return $self;
}

=back

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut


1;

__END__
