#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/RDQL.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/01/2004
# Revision:	$Id: RDQL.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::RDQL;

use strict;
use warnings;

use ODO::Exception;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO/;

__PACKAGE__->mk_accessors(qw/constraints/);
__PACKAGE__->mk_ro_accessors(qw/result_vars prefixes statement_patterns/);


=head1 NAME

ODO::Query::RDQL - RDQL Query object

=head1 SYNOPSIS

Synopsis.

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item add_result_var( $variable )

=cut

sub add_result_var {
	my ($self, $var) = @_;

	throw ODO::Exception::Parameter::Invalid(error=> 'Parameter must be an ODO::Node::Variable')
		unless(UNIVERSAL::isa($var, 'ODO::Node::Variable'));
	
	$self->{'result_vars'}->{ $var->hash() } = $var;
	push @{ $self->{'result_vars'}->{'#variables'} }, $var;
	
	return $self;
}


sub init {
	my ($self, $config) = @_;
	
	$self->{'statement_patterns'} = {'#patterns'=> []};
	
	$self->{'constraints'} = [];
	$self->{'result_vars'} = {'#variables'=> []};
	
	$self->{'prefixes'} = {};
	
	# Default prefixes
	$self->{'prefixes'}->{'rdf'} = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
	$self->{'prefixes'}->{'rdfs'} = 'http://www.w3.org/2000/01/rdf-schema#';
	$self->{'prefixes'}->{'xsd'} = 'http://www.w3.org/2001/XMLSchema#';
	$self->{'prefixes'}->{'owl'} = 'http://www.w3.org/2002/07/owl#';
	
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
