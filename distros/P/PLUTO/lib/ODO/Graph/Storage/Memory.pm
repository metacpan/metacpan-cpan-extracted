#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Graph/Storage/Memory.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/22/2004
# Revision:	$Id: Memory.pm,v 1.4 2010-02-17 17:17:09 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Graph::Storage::Memory;

use strict;
use warnings;

use ODO::Exception;
use ODO::Statement;
use ODO::Query::Simple;
use ODO::Query::Simple::Result;

use ODO::Query::RDQL::Parser;
use ODO::Query::RDQL::DefaultHandler;

use base qw/ODO::Graph::Storage/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_ro_accessors(qw/subjects predicates objects statements/);

=head1 NAME

ODO::Graph::Storage::Memory - Memory backed storage for graphs.

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item add( )

=cut

sub add {
	my ($self, $statements) = @_;
	foreach my $stmt (@{ $statements }) {		
		$self->{'statement_count'}++
			if(!exists($self->{'statements'}->{ $stmt->hash() }));
		
		$self->{'statements'}->{ $stmt->hash() } = $stmt;
	}
	
	return $self;
}


=item remove( )

=cut

sub remove {
	my ($self, $statements) = @_;
	foreach my $stmt (@{ $statements }) {
		delete($self->{'statements'}->{ $stmt->hash() });
		$self->{'statement_count'}--;
	}
	
	return $self;
}


=item size( )

=cut

sub size {
	my $self = shift;
	return $self->{'statement_count'};
}


=item clear( )

=cut

sub clear {
	my $self = shift;

	$self->{'subjects'} = {};
	$self->{'predicates'} = {};
	$self->{'objects'} = {};

	$self->{'statements'} = {};
	
	$self->{'statement_count'} = 0;
	
	return $self;
}


=item issue_query( $query, \%query_options )

=cut

sub issue_query {
	my ($self, $query, $query_options) = @_;

	return $self->issue_simple_query($query)
		if($query->isa('ODO::Query::Simple'));

	my $query_lang = 'RDQL';	
	if(UNIVERSAL::isa($query_options, 'HASH')) {
	}
	
	my $rdql_query = ODO::Query::RDQL::Parser->parse($query);
    return 
        ODO::Query::Simple::Result->new(source_graph=> $self->parent_graph(), query=> ODO::Query::RDQL->new(), results=> [])
      unless defined $rdql_query;
	my $result_graph = ODO::Query::RDQL::DefaultHandler->new(data => $self->parent_graph(), query_object => $rdql_query)->evaluate_query();
	
	my $statements = $result_graph->query($ODO::Query::Simple::ALL_STATEMENTS)->results();
	return ODO::Query::Simple::Result->new(source_graph=> $self->parent_graph(), query=> $rdql_query, results=> $statements);	
}


=item issue_simple_query( $query )

=cut

sub issue_simple_query {
	my ($self, $query) = @_;
	
	my $statements = [];
	
	foreach my $stmt (values(%{ $self->{'statements'} })) {
		
		next
			unless($query->equal($stmt));
		
		push @{ $statements }, $stmt
	}
	
	return ODO::Query::Simple::Result->new(source_graph=> $self->parent_graph(), query=> $query, results=> $statements);
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	
	$self->{'statement_count'} = 0;
	
	$self->{'subjects'} = {};
	$self->{'predicates'} = {};
	$self->{'objects'} = {};
	
	$self->{'statements'} = {};

	return $self;
}


=back

=head1 COPYRIGHT

Copyright (c) 2005-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
