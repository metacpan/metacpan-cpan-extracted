use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::SummaryCounters;
# ABSTRACT: Statement statistics
$Neo4j::Driver::SummaryCounters::VERSION = '0.09';

sub new {
	my ($class, $stats) = @_;
	
	return bless $stats, $class;
}


my @counters = qw(
	constraints_added
	constraints_removed
	contains_updates
	indexes_added
	indexes_removed
	labels_added
	labels_removed
	nodes_created
	nodes_deleted
	properties_set
	relationships_created
);
no strict 'refs';  ##no critic (ProhibitNoStrict)
for my $c (@counters) { *$c = sub { shift->{$c} } }

# This name is a typo that drivers are supposed to fix;
# see <https://github.com/neo4j/neo4j/issues/3421>
sub relationships_deleted { shift->{relationship_deleted}; }




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::SummaryCounters - Statement statistics

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Neo4j::Driver;
 my $driver = Neo4j::Driver->new->basic_auth(...);
 
 my $transaction = $driver->session->begin_transaction;
 $transaction->{return_stats} = 1;
 my $query = 'MATCH (n:Novel {name:"1984"}) SET n.writer = "Orwell"';
 my $result = $transaction->run($query);
 
 my $counters = $result->summary->counters;
 my $database_modified = $counters->contains_updates;
 die "That didn't work out." unless $database_modified;

=head1 DESCRIPTION

Contains counters for various operations that a statement triggered.

=head1 ATTRIBUTES

L<Neo4j::Driver::SummaryCounters> implements the following read-only
attributes.

 my $constraints_added     = $counters->constraints_added;
 my $constraints_removed   = $counters->constraints_removed;
 my $contains_updates      = $counters->contains_updates;
 my $indexes_added         = $counters->indexes_added;
 my $indexes_removed       = $counters->indexes_removed;
 my $labels_added          = $counters->labels_added;
 my $labels_removed        = $counters->labels_removed;
 my $nodes_created         = $counters->nodes_created;
 my $nodes_deleted         = $counters->nodes_deleted;
 my $properties_set        = $counters->properties_set;
 my $relationships_created = $counters->relationships_created;
 my $relationships_deleted = $counters->relationships_deleted;

=head1 BUGS

These counters may not be useful for verifying that writing to the
database was successful. For one thing, explicit transactions may
later be rolled back, rendering these statistics outdated. For
another, certain error conditions produce misleading statistics: It
was observed that deleting a node that has relationships fails in a
Cypher shell with an obscure error message, while it succeeds when
executed over HTTP with this driver. However, the HTTP response then
reports that the node was deleted, but the relationship wasn't, which
is obviously inconsistent. Not quite sure what is going on there. To
verify that modifying the database was successful, it would therefore
probably make more sense to run a MATCH query, tedious or not.

=head1 SEE ALSO

L<Neo4j::Driver>,
L<Neo4j Java Driver|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/v1/summary/SummaryCounters.html>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2018 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
