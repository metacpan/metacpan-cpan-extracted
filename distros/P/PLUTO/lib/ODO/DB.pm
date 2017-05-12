#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/DB.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/05/2004
# Revision:	$Id: DB.pm,v 1.2 2009-11-25 17:46:51 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::DB;


package ODO::DBI::Connector;

use strict;
use warnings;

use ODO::Exception;
use Exception::Class::DBI;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use base qw/DBI/;


=head1 NAME

 ODO::DBI::Connector

=head1 SYNOPSIS

=head1 DESCRIPTION
 
=head1 METHODS

=over

=back

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html
  
=cut

package ODO::DBI::Connector::dr;

use base qw/DBI::dr/;

sub connect {
	my ($drh, $dsn, $user, $pass, $attr) = @_;
	
	# Setup the DBI to use Exception::Class::DBI
	$attr->{PrintError} = 0;
	$attr->{RaiseError} = 0;
	$attr->{HandleError} = Exception::Class::DBI->handler();
	
	return $drh->SUPER::connect($dsn, $user, $pass, $attr);
}

package ODO::DBI::Connector::db;

use base qw/DBI::db/;


package ODO::DBI::Connector::st;

use base qw/DBI::st/;


1;

__END__
