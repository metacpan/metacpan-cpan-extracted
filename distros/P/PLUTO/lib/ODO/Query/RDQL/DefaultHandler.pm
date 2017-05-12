#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/RDQL/DefaultHandler.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/01/2004
# Revision:	$Id: DefaultHandler.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::RDQL::DefaultHandler;

use strict;
use warnings;

use ODO::Exception;
use ODO::Query::Simple;
use ODO::Query::VariablePatternMap;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use base qw/ODO::Query::Handler/;


=head1 NAME

ODO::Query::RDQL::DefaultHandler - Implementation of the generic query processing engine for RDQL

=head1 SYNOPSIS
	
=head1 DESCRIPTION

=head1 METHODS

=over

=item evalutate_query( )

 0. Get all statements in graph pattern and mark them as not done
 1. Sort query statements by priority
 2. Remove query statements already executed
 3. Generate list of queries based on current query triple
 	i. Find variable with smallest result list
	ii. Create query triple with variable values substituted
 4. Execute queries in list
	i. Union results
	ii. Update each variable's result list
 5. Mark query statement as done

=cut

sub evaluate_query {
	my $self = shift;
	
	$self->__initialize();
	
	my $completed_statements = {};
	
	# Mark all statemetns as 'not searched'
	my $result_set = $self->{'graph_pattern'}->query($ODO::Query::Simple::ALL_STATEMENTS);
	my $statements = $result_set->results();
	foreach my $stmt (@{ $statements }) {
		$completed_statements->{ $stmt->hash() } = 0;
	}
	
	my $completed = 0;
	my $size = scalar( @{ $statements } );
		
	while($completed < $size) {
	
		my @prioritized_statements = @{ $self->__prioritize_statements( $statements ) };
		
		# Remove triples from the results array that have been completed
		while($completed_statements->{ $prioritized_statements[0]->hash() } == 1) {	
			shift @prioritized_statements;
		}

		my $query_list = $self->{'variable_map'}->make_query_list($prioritized_statements[0]);
		$self->__do_query_list($prioritized_statements[0], $query_list);

		$completed_statements->{ $prioritized_statements[0]->hash() } = 1;
		$completed++;
	}
	
	return $self->{'variable_map'}->get_result_graph();
}


=back

=head1 INTERNALS

=over

=item __do_query_list( $stmt_query, $query_list )

=cut

sub __do_query_list {
	my ($self, $stmt_query, $query_list) = @_;
	
	my $inter_results = ODO::Graph::Simple->Memory();
	
	foreach my $q (@{ $query_list }) {
		my $result_set = $self->data()->query($q);
		$inter_results->add($result_set->results());
	}
	
	return $self->{'variable_map'}->invalidate_results($stmt_query, $inter_results);
}


=item __get_neighbors( $stmt_match )

=cut

sub __get_neighbors {
	my ($self, $stmt_match) = @_;
	my $neighbor_match = ODO::Query::Simple->new($stmt_match->object(), undef, undef);
	my $result_set = $self->{'graph_pattern'}->query($neighbor_match);
	return $result_set->results();
}


=item __make_key( $node1, [ $node2, [ $node3 ] ] )

=cut

sub __make_key {
	my $self = shift;
	my ($n1, $n2, $n3) = @_;
	return join("", (($n1) ? $n1->hash() : '', ($n2) ? $n2->hash() : '', ($n3) ? $n3->hash() : '')); 
}


=item __statement_weight( $stmt_query ) 

 Weight = number of variables + 1 if triple match has neighbors otherwise
 Weight = number of variables

=cut

sub __statement_weight {
	my ($self, $statement) = @_;
	my $w = $self->__num_variables($statement);
	
	return $w + 1
		if(scalar(@{ $self->__get_neighbors( $statement )}) > 0);
	
	return $w;
}


=item __num_variables( $stmt_query )
 
 Counts the number of variables present in a triple match.
 
=cut

sub __num_variables {
	my ($self, $stmt_query) = @_;

	my $vars = 0;
	
	foreach my $component ('s', 'p', 'o') {
		$vars++
			if(UNIVERSAL::isa($stmt_query->$component(), 'ODO::Node::Variable'));
	}

	return $vars;
}


=item __prioritize_statements( \@statements )

 Sort the graph of L<ODO::Query::Simple> statements by the L<ODO::Query::Simple> object's
 'weight' . L<ODO::Query::Simple> object 'A' weighs more than L<ODO::Query::Simple> object 'B'
 iff the following is true:

=cut

sub __prioritize_statements {
	my ($self, $statements) = @_;

	my @results = sort {
				   ($self->__num_variables($a) >= $self->__num_variables($b))
				&& ($self->__statement_weight($a) >= $self->__statement_weight($b)) 
				&& ($self->{'variable_map'}->known_variable_count($a) >= $self->{'variable_map'}->known_variable_count($b))
			   } @{ $statements };

	return \@results;
}


=item __initialize

=cut

sub __initialize {
	my $self = shift;
	$self->{'variable_map'} = ODO::Query::VariablePatternMap->new();
	$self->{'graph_pattern'} = ODO::Graph::Simple->Memory();
	
	my $statement_patterns = $self->query_object()->statement_patterns()->{'#patterns'};
	$self->{'graph_pattern'}->add($statement_patterns);
	
	return $self;
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	$self->__initialize();
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
