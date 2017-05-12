package Norma::ORM::Collection;
our $VERSION = "0.02";
use Moose;

has items       => (is => 'ro', isa => 'ArrayRef', auto_deref => 1);
has total_count => (is => 'ro');
has query       => (is => 'ro');
has class       => (is => 'ro', required => 1);

has limit_offset => (is => 'ro');
has limit_count  => (is => 'ro');

sub BUILD {
	my ($self, $args) = @_;

	my $class = $args->{class};

	unless ($class->does('Norma::ORM::Mappable')) {
		die "class $class should consume Norma::ORM::Mappable but it doesn't look like it does";
	}

	my $table = $class->_table;
	my $dbh = $self->{_dbh} = $class->_dbh;

	my @join_clauses;
	my %joins = @{ $args->{join} || [] };

	while (my ($table, $association) = each %joins) {
		push @join_clauses, "$table on $association";
	}

	my $query_clauses = {};
	$query_clauses->{join} = join ' join ', $table->{name}, @join_clauses;

	$self->{_where_clauses} = [];

	my $where_clause = join ' and ', sort @{ $self->_parse_criteria($args->{where}) };
	$query_clauses->{where} = "where $where_clause" if $where_clause;

	my $order_clause = $args->{order_clause} || $class->_defaults->{order_clause} || '';
	$query_clauses->{order} = "order by $order_clause" if $order_clause;

	my $limit_offset = $args->{limit_offset} || 0;
	my $limit_count = $args->{limit_count} || $class->_defaults->{limit_count} || 50;
	$query_clauses->{limit} = "limit $limit_offset, $limit_count";

	my $selection = $class->_table->select(
		table_name => $table->{name},
		%$query_clauses
	);

	$self->{total_count} = $selection->{total_count};
	$self->{query} = $selection->{query};

	for my $row (@{ $selection->{rows} }) {
		my $item = $class->new(%$row);
		push @{ $self->{items} }, $item;
	}
};

no Moose;

sub _parse_criteria {
	my ($self, $criteria) = @_;

	if (! ref $criteria && $criteria) {
		push @{ $self->{_where_clauses} }, $criteria;
 
	} elsif (ref $criteria && ref $criteria eq 'ARRAY') {

		for my $criterion (@$criteria) {
			$self->_parse_criteria($criterion);
		}

	} elsif (ref $criteria && ref $criteria eq 'HASH') {

		while (my ($left_operand, $right_operand) = each %$criteria) {

			my $operator = $left_operand =~ / / ? '' : '=';
			push @{ $self->{_where_clauses} }, join ' ', grep { $_ } 
				$left_operand, 
				$operator, 
				$self->{_dbh}->quote($right_operand);
		}
	}

	return $self->{_where_clauses};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Norma::ORM::Collection - Queries and results with metadata from classes consuming the L<Norma::ORM::Mappable> role

=head1 SYNOPSIS

  my $uk_customers = Norma::ORM::Collection->new(
	class => 'MyApp::Customer',
	where => { country => 'UK' },
  );

  for my $customer ($uk_customers->items) {
  	...
  }

=head1 METHODS

=head2 new(where => {...} order => $column_name, ...)

Queries the database and returns a collection which contains an array of instantiated objects, along with other metadata.  We'll take the following parameters:

=over

=item join

Specify join clauses as hashrefs, table names (or derived tables / sub queries if you like) pointing to column associations.  

  join => [ 
  	customer_notes 
		=> 'customer_notes.customer_id = customers.id',

	'(select customer_id, min(order_date) first_order_date from orders group by customer_id) first_order_dates' 
		=> 'first_order_dates.customer_id = customers.id'
  ]

=item where

Criteria for the "where" clause may be specified in a number of ways.  For simple lookups, key / value pairs will suffice.  To find customers in London, you might try:

  where => { 
  	city => 'London', 
  	country => 'UK',
  }

For comparisons other than equality, sepcify the sql comparison in the key itself.  To find customers in Eastern Central London by postcode, you might try:

  where => { 
  	'postal_code like' => 'EC%', 
  	country => 'UK' 
  }

If you need more flexibility, you can pass in your own where clauses along-with:

  where => [
	q{ postal_code between 'EC2' and 'EC4' },
	{ country => 'UK' },
  ]

Outside of custom where clauses, values will be quoted by DBI::quote.  

=item order => $order_clause

Order the query according to this clause, if specified

=item limit_count

Return this many items

=item limit_offset

Return items starting at this offset

=back

=head1 METHODS

=head2 items

Array of objects where each one is an instance of the given $class

=head2 total_count

The number of rows that matched this query

=head2 query

The actual SQL query that was run

=head2 class

The name of the class of the objects returned via items

=head1 SEE ALSO

L<Norma>, L<Norma::ORM::Mappable>

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
