#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Handler.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/05/2006
# Revision:	$Id: Handler.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Handler;

use strict;
use warnings;

use base qw/ODO/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use Class::Interfaces('ODO::Query::Handler'=> 
	{
		'isa'=> 'ODO',
		'methods'=> [ 'evaluate_query' ],
	}
  );

our @ACCESSORS = qw/data query_object/;

__PACKAGE__->mk_ro_accessors(@ACCESSORS);

=head1 NAME

ODO::Query::Handler - Query handler interface

=head1 SYNOPSIS

Synopsis.

=head1 DESCRIPTION

Description.

=head1 CONSTRUCTOR

Constructor.

=head1 METHODS

=over

=item evaluate_query( $query_object )

=cut

sub init {
	my ($self, $config) = @_;
	$self->params($config, @ACCESSORS);	
	return $self;
}

=back

=head1 AUTHOR

IBM Corporation

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
