#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Result.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/30/2004
# Revision:	$Id: Result.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Result;

use strict;
use warnings;

use ODO::Exception;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use base qw/ODO/;

__PACKAGE__->mk_ro_accessors(qw/query source_graph bound_vars results/);

=head1 NAME

ODO::Query::Result - Result set object

=head1 SYNOPSIS

Synopsis.

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item add_bound_var( $variable )

=cut

sub add_bound_var {
	my ($self, $var) = @_;
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Parameter must be an ODO::Node::Variable')
		unless(UNIVERSAL::isa($var, 'ODO::Node::Variable'));
	
	$self->{'bound_vars'}->{ $var->hash() } = $var;
	push @{ $self->{'bound_vars'}->{'#variables'} }, $var;
	
	return $self;
}


sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/source_graph query results/);
	$self->{'bound_vars'} = { '#variables'=> []};
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
