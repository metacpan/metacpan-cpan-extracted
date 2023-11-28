use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::SummaryCounters;
# ABSTRACT: Statement statistics
$Neo4j::Driver::SummaryCounters::VERSION = '0.41';

sub new {
	my ($class, $stats) = @_;
	
	return bless $stats, $class;
}


my @counters = qw(
	constraints_added
	constraints_removed
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
sub relationships_deleted {
	my $self = shift;
	return $self->{relationships_deleted} if defined $self->{relationships_deleted};
	return $self->{relationship_deleted};
}

# contains_updates is only present in the HTTP response;
# we need to synthesize it from Bolt responses
sub contains_updates {
	my $self = shift;
	unless (defined $self->{contains_updates}) {
		$self->{contains_updates} = $self->{relationships_deleted} // 0;
		$self->{contains_updates} += grep {$self->{$_}} @counters;
	}
	return !! $self->{contains_updates};
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::SummaryCounters - Statement statistics

=head1 VERSION

version 0.41

=head1 SYNOPSIS

 use Neo4j::Driver;
 $driver = Neo4j::Driver->new->basic_auth(...);
 
 $transaction = $driver->session->begin_transaction;
 $transaction->{return_stats} = 1;
 $query = 'MATCH (n:Novel {name:"1984"}) SET n.writer = "Orwell"';
 $result = $transaction->run($query);
 
 $counters = $result->summary->counters;
 $database_modified = $counters->contains_updates;
 die "That didn't work out." unless $database_modified;

=head1 DESCRIPTION

Contains counters for various operations that a statement triggered.

To obtain summary counters, call
L<Neo4j::Driver::ResultSummary/"counters">.

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
reports that the node was deleted, but that the relationship wasn't, which
is obviously inconsistent. Not quite sure what is going on there. To
verify that modifying the database was successful, it would therefore
probably make more sense to run a MATCH query, tedious or not.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * Equivalent documentation for the official Neo4j drivers:
L<SummaryCounters (Java)|https://neo4j.com/docs/api/java-driver/5.2/org.neo4j.driver/org/neo4j/driver/summary/SummaryCounters.html>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
