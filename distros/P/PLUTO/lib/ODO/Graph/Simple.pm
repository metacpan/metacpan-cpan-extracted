#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Graph/Simple.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/21/2006
# Revision:	$Id: Simple.pm,v 1.2 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Graph::Simple;

use strict;
use warnings;

use base qw/ODO::Graph/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use ODO::Exception;

=head1 NAME

ODO::Graph::Simple - Simple graph implementation

=head1 SYNOPSIS

 use ODO::Graph::Simple;

 # Create an ODO::Graph::Simple object backed by memory
 my $graph = ODO::Graph::Simple->Memory();

=head1 DESCRIPTION

This a very simple implementation of ODO's graph inteface (see L<ODO::Graph>) that defers to
the underlying storage mechanism to execute the caller's request.

=head1 METHODS

=over

=item add( )

=cut

sub add {
	my $self = shift;
	
	my $statements = $_[0];
	$statements = $self->params_to_array(\@_, 1)
		unless(scalar(@_) == 1 && UNIVERSAL::isa($_[0], 'ARRAY'));
	
	return $self->{'storage'}->add($statements);
}


=item remove( )

=cut

sub remove {
	my $self = shift;
	
	my $statements = $_[0];
	$statements = $self->params_to_array(\@_, 1)
		unless(scalar(@_) == 1 && UNIVERSAL::isa($_[0], 'ARRAY'));
	
	return $self->{'storage'}->remove($statements);
}


=item clear( )

=cut

sub clear {
	my $self = shift;
	return $self->{'storage'}->clear();
}


=item size( )

=cut

sub size {
	my $self = shift;
	return $self->{'storage'}->size();
}


=item query( )

=cut

sub query {
	my $self = shift;
	return $self->{'storage'}->issue_query(@_);
}


=item contains( )

=cut

sub contains {
	my $self = shift;
	my $results = $self->{'storage'}->issue_query(@_);
	return (scalar(@{ $results }) > 0) ? 1 : 0;
}

=item intersection( )

=cut

sub intersection {
	my $self = shift;
}

=item union( )

=cut

sub union {
	my $self = shift;
}

=back

=head1 SEE ALSO

L<ODO::Graph::Storage>, L<ODO::Statement>, L<ODO::Query>, L<ODO::Query::Simple>, L<ODO::Query::RDQL>

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut


1;

__END__
