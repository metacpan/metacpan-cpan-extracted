use v5.12;
use warnings;

package Neo4j::Driver::SummaryCounters 1.02;
# ABSTRACT: Query statistics


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

Neo4j::Driver::SummaryCounters - Query statistics

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  # $session = Neo4j::Driver->new({ ... })->session;
  
  $counters = $session->execute_write( sub ($transaction) {
    my $query = <<~'END';
      MATCH (m:Movie) WHERE m.released > 2000
      SET m.new = true
      END
    return $transaction->run($query)->consume->counters;
  });
  
  say sprintf '%i nodes updated.', $counters->properties_set;

=head1 DESCRIPTION

Contains counters for various operations that a query triggered.

To obtain summary counters, call
L<Neo4j::Driver::ResultSummary/"counters">.

Note that these statistics can be misleading in certain error
conditions. In particular, using them to verify whether database
modifications were successful is not advisable.

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

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<ResultSummary>>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
