#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/SPARQL/Parser.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/29/2006
# Revision:	$Id: Parser.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::SPARQL::Parser;

use strict;
use warnings;

use base qw/ODO/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use ODO::Exception;

use Parse::RecDescent;

our $PARSER = undef;

=head1 NAME

ODO::Query::SPARQL::Parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERNALS

=over 

=item $GRAMMAR

=cut

our $GRAMMAR=q(

);

=head1 METHODS

=over

=item parse( $query_string )

=cut

sub parse {
	my ($self, $query_string) = @_;
	
	chomp($query_string);

	$PARSER = new Parse::RecDescent($GRAMMAR)
		unless(UNIVERSAL::isa($PARSER, 'Parse::RecDescent'));

	return $PARSER->StatementPatternClause($query_string);
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
