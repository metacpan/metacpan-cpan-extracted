#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/VariablePatternMap.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/13/2005
# Revision:	$Id: VariablePatternMap.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::VariablePatternMap;

use strict;
use warnings;

use ODO::Query::Simple;
use ODO::Query::Simple::Mapper;

use ODO::Graph::Simple;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use base qw/ODO/;

__PACKAGE__->mk_accessors(qw/patterns known_var_map/);

=head1 NAME

ODO::Graph::Query::VariablePatternMap

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item add( $stmt, $item )

=cut

sub add {
	my $self = shift;
	
	my $stmt = shift;
	unless(   UNIVERSAL::isa($stmt, 'ODO::Statement')
		   || $self->__is_pattern_key($stmt)) {
		return undef;
	}
	
	my $item = shift;
	
	my $key = $stmt;

	# The ternary operator wasn't working here.....
	$key = $self->__make_pattern_key($stmt)
		unless($self->__is_pattern_key($stmt) == 1);
	
	my $patternList = $self->patterns()->{ $key };
	
	$self->patterns()->{ $key } = $patternList = []
		unless(UNIVERSAL::isa($patternList, 'ARRAY'));
	
	push @{ $patternList }, $item;
	
	# Record the fact that we have results for any variables 
	# in the triple match
	my @comps = split('-', $key);
	
	foreach my $c (@comps) {
		
		next
			if($c eq '*');
		
		$self->known_var_map()->{ $c } = 
			(exists($self->known_var_map()->{ $c })) ? $self->known_var_map()->{ $c } + 1 : 1; 
	}
}


=item add_list( $stmt, $list )

=cut

sub add_list {
	my ($self, $stmt, $list) = @_; 
	
	my $count = 0;
	foreach my $item (@{ $list }) {
		$self->add($stmt, $item);
		$count++;
	}	
}


=item get_result_graph( [ $graph ])
 
 Gathers all of the triples for the patterns in the query
 and results the concrete results in the form of an L<ODO::Graph>.
 
 If an L<ODO::Graph> is specified as a parameter, the method will
 fill it with the results instead of creating a new graph object.

=cut

sub get_result_graph {
	my ($self, $graph) = @_;
	
	$graph = ODO::Graph::Simple->Memory()
		unless($graph);
	
	foreach my $p (keys(%{ $self->patterns() })) {
		$graph->add($self->get_results_for_pattern($p));
	}
	
	return $graph;
}


=item get_results_for_pattern( $stmt )

 Returns the array reference that potentially contains results
 that can fill this triple pattern.
 
=cut

sub get_results_for_pattern {
	my ($self, $stmt) = @_;
	
	unless(UNIVERSAL::isa($stmt, 'ODO::Statement') ||
		$self->__is_pattern_key($stmt)) {	
		return undef;
	}
	
	my $key = $stmt;

	# The ternary operator wasn't working here.....
	$key = $self->__make_pattern_key($stmt)
		unless($self->__is_pattern_key($stmt) == 1);

	return []
		unless(UNIVERSAL::isa($self->patterns()->{ $key }, 'ARRAY'));
	
	return $self->patterns()->{ $key };
}


=item make_query_list( $stmt_match )

=cut

sub make_query_list {
	my ($self, $stmt) = @_;
	
	my @queryList;
		
	foreach my $p (keys(%{ $self->patterns() })) {

		next # Only continue if some component matches
			unless($self->__compare_pattern($p, $stmt));

		my $mapper = ODO::Query::Simple::Mapper->new($stmt, $self->__key_to_triple_match($p));
		
		# Each result for a particular pattern has its own query that will
		# be used to get that segment of results
		foreach my $r (@{ $self->get_results_for_pattern($p) }) {
			
			my $newTM = ODO::Query::Simple->new($stmt->subject(), $stmt->predicate(), $stmt->object());
			
			foreach my $component ('subject', 'predicate', 'object') {
			
				my $destComponent = $mapper->$component();
				
				# When a variable is present in both triples, place the value result's 
				# Triple::Match in to the variable's position of the new Triple::Match
				$newTM->$component($r->$destComponent()), next
					if($destComponent);
		
				# Convert variables to Any nodes in the Triple::Match			
				$newTM->$component($ODO::Node::ANY)
					if(UNIVERSAL::isa($stmt->$component(), 'ODO::Node::Variable'));
			}
			
			push @queryList, $newTM;
		}
		
		return \@queryList;
	}

	# Simple case: Convert any variables to Any nodes and return the single
	# query triple when there results are not available.
	my $newTM = ODO::Query::Simple->new($stmt->subject(), $stmt->predicate(), $stmt->object());
	
	foreach my $comp ('subject', 'predicate', 'object') {
		next
			unless(UNIVERSAL::isa($stmt->$comp(), 'ODO::Node::Variable'));
			
		$newTM->$comp($ODO::Node::ANY);
	}
	
	return [ $newTM ];
}


=item count_pattern_results( $stmt )

=cut

sub count_pattern_results {
	my $self = shift;
	
	my $stmt = shift;
	unless(UNIVERSAL::isa($stmt, 'ODO::Statement') ||
		$self->__is_pattern_key($stmt)) {
		return undef;
	}

	my $key = $stmt;

	# The ternary operator wasn't working here.....
	$key = $self->__make_pattern_key($stmt)
		unless($self->__is_pattern_key($stmt) == 1);
	
	return 0
		unless(UNIVERSAL::isa($self->patterns()->{ $key }, 'ARRAY'));

	my $num = scalar(@{ $self->patterns()->{ $key } });
	
	return $num;
}


=item clear_pattern_results( $stmt )

=cut

sub clear_pattern_results {
	my $self = shift;
	
	my $stmt = shift;
	unless(UNIVERSAL::isa($stmt, 'ODO::Statement') ||
		$self->__is_pattern_key($stmt)) {
		return undef;
	}
	
	my $key = $stmt;

	# The ternary operator wasn't working here.....
	$key = $self->__make_pattern_key($stmt)
		unless($self->__is_pattern_key($stmt) == 1);

	my $numResults = $self->count_pattern_results( $key );
	
	delete $self->patterns()->{ $key };
	
	my @comps = split('-', $key);
	
	foreach my $c (@comps) {
		
		next
			if($c eq '*');
		
		$self->known_var_map()->{ $c } -= $numResults
			if(exists($self->known_var_map()->{ $c }));
	}
}


=item invalidate_results( $stmt, $resultsGraph )

=cut

sub invalidate_results {
	my ($self, $stmt, $results_graph) = @_;
	
	#
	# Example: if this triple pattern uses the variable B, then
	# if other triple patterns use the variable B and have results, then
	# we must remove from those results anything that is not in the 
	# intersection of the graph.
	#
	$self->__prune_patterns($stmt, $results_graph);
	
	# Finally, record the results
	$self->clear_pattern_results( $stmt );

	my $result_set = $results_graph->query($ODO::Query::Simple::ALL_STATEMENTS);
	my $new_results = $result_set->results();
	$self->add_list($stmt, $new_results);
	
	return $results_graph;	
}


=item known_variable_count( $stmt )
 
=cut

sub known_variable_count {
	my ($self, $stmt) = @_;
	
	my $v = 0;
	foreach my $comp ('subject', 'predicate', 'object') {
	
		next
			unless(UNIVERSAL::isa($stmt->$comp(), 'ODO::Node::Variable'));
			
		$v++
			if(   exists($self->known_var_map()->{ $stmt->$comp()->value() })
			   && $self->known_var_map()->{ $stmt->$comp()->value() } > 0);
	}
	
	# my $stmt_string = join(' - ', ($stmt->subject()->value(), $stmt->predicate()->value(), $stmt->object()->value()));
	
	return $v;
}


=head1 Internal methods

=over

=item __is_pattern_key( $pk )

=cut

sub __is_pattern_key {
	my ($self, $pk) = @_;
	return (($pk =~ /^.+?-.+?-.+?$/) ? 1 : 0);
}


=item __make_pattern_key( $stmt )

 Makes a key such that variable names are included while all other
 nodes are replaced by a star.

=cut
sub __make_pattern_key {
	my ($self, $stmt) = @_;
	
	my $key;
	
	foreach my $component ('subject', 'predicate', 'object') {

		$key .= $stmt->$component()->value() . '-', next
			if(UNIVERSAL::isa($stmt->$component(), 'ODO::Node::Variable'));
		
		$key .= '*-';
	}

	chop($key)
		if($key =~ /-$/);
	
	return $key;
}


=item __key_to_triple_match( $key )

 Create a TripleMatch based on the key with the non-variable
 components as Any nodes.

=cut

sub __key_to_triple_match {
	my ($self, $key) = @_;
	
	my ($s, $p, $o ) = split('-', $key);

	# XXX: Don't use $ODO::Query::Simple::ALL_STATEMENTS here because modify the object
	my $stmt = ODO::Query::Simple->new(undef, undef, undef);
	
	$stmt->subject( ODO::Node::Variable->new($s) )
		if($s ne '*');
		
	$stmt->predicate( ODO::Node::Variable->new($p) )
		if($s ne '*');
		
	$stmt->object( ODO::Node::Variable->new($o) )
		if($o ne '*');
	
	return $stmt;
}


=item __compare_pattern( $pattern, $stmt )

=cut

sub __compare_pattern {
	my ($self, $pattern, $stmt) = @_;

	my $key = $stmt;

	# The ternary operator wasn't working here.....
	$key = $self->__make_pattern_key($stmt)
		unless($self->__is_pattern_key($stmt) == 1);

	my ($s, $p, $o ) = split('-', $key);

	$s = ($s ne '*') ?  "(^$s-|-$s-|-$s\$)" : '';
	
	$p = ($p ne '*') ? "(^$p-|-$p-|-$p\$)" : '';
	
	$o = ($o ne '*') ? "(^$o-|-$o-|-$o\$)" : '';

	my $compare = join('|', ( $s, $p, $o) );
	
	return ($pattern =~ /$compare/) ? 1 : 0;
}


=item __prune_patterns( $stmt, $inter_results )

=cut

sub __prune_patterns {
	my ($self, $stmt, $inter_results) = @_;
	
	my @patternKeys;

	foreach my $p (keys(%{ $self->patterns() })) {

		next # Skip this pattern if it doesn't match
			unless($self->__compare_pattern($p, $stmt));

		
		# Create a mapped triple match that will be used
		# in the pruning process.
		my $dest_stmt = $self->__key_to_triple_match($p);
		my $mapper = ODO::Query::Simple::Mapper->new($stmt, $dest_stmt);
		
		
		# It may be that there are no results for this triple pattern (yet)
		# so we should just keep everything
		next 
		    unless($self->count_pattern_results($dest_stmt) > 0);
		
		my $sourceMatch;
		my $destMatchMap = {};

		my $destPatternResults = $self->get_results_for_pattern($dest_stmt);
		
		
		# See if the variables in the results just found match to
		# the same variables in other triple pattern results
		my $result_set = $inter_results->query($ODO::Query::Simple::ALL_STATEMENTS);
		my $results = $result_set->results();

		foreach my $s (@{ $results }) {

			$sourceMatch = 0;
						
			foreach my $d (@{ $destPatternResults }) {
				# If they match, then leave them alone
				if($mapper->compare($s, $d)) {
				
					$sourceMatch = 1;
					$destMatchMap->{$d} = 1;
					
					last;
				}
			}
			
			$inter_results->remove($s)
				unless($sourceMatch)
							
		} # end result processing
		
		my @newDestPatternResults;
		
		# Remove the destination patterns that never matched
		foreach my $d (@{ $destPatternResults }) {
			if(exists($destMatchMap->{$d})) {
				push @newDestPatternResults, $d;
			}
		}
		
		$self->clear_pattern_results($p);
		$self->add_list($p, \@newDestPatternResults);
	
	} # end pattern processing
}


sub init {
	my ($self, $config) = @_;
	$self->patterns( {} );
	$self->known_var_map( {} );
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
