#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Graph/Storage.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/20/2006
# Revision:	$Id: Storage.pm,v 1.2 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Graph::Storage;

use strict;
use warnings;

use base qw/ODO/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use Class::Interfaces('ODO::Graph::Storage'=> 
	{
		'isa'=> 'ODO',
		'methods'=> [ 'add', 'remove', 'clear', 'size', 'issue_query', 'issue_simple_query' ],
	}
  );

__PACKAGE__->mk_ro_accessors(qw/parent_graph/);

=head1 NAME

ODO::Graph::Storage - Store statements in a particular manner (database, memory, file etc.)

=head1 DESCRIPTION

Graph storage abstraction layer.

=head1 METHODS

=over

=item add( $statement | \@statements | @statements )

Add statement(s).

=item remove( $statement | \@statements | @statements )

Remove statement(s).

=item issue_query( $query )

Issue a potentially complex query (SPARQL, RDQL, etc.).

=item issue_simple_query( $simple_query )

Issue a simple pattern match query, see L<ODO::Query::Simple> for information about how
to construct a pattern.

=cut

sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/parent_graph/);
	return $self;
}

=back

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
