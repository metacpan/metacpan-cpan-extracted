#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Simple/Result.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/30/2004
# Revision:	$Id: Result.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Simple::Result;

use strict;
use warnings;

use ODO::Exception;
use ODO::Graph::Simple;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use base qw/ODO::Query::Result/;

=head1 NAME

ODO::Query::Simple::Result - Result set object for queries based on ODO::Query::Simple

=head1 SYNOPSIS
	
=head1 DESCRIPTION

=head1 METHODS

=over

=cut


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	
	# TODO: Setup bound variables
	
	return $self;
}


=back

=head1 AUTHOR

IBM Corporation

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html
  
=cut

1;

__END__
