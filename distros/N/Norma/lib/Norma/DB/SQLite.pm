package Norma::DB::SQLite;
our $VERSION = "0.02";

use Moose;
use Carp qw(confess);

extends 'Norma::DB';

around 'get_table_primary_key_field_names' => sub {
	my ($orig, $self) = @_;

	my $columns = $self->$orig(@_);

	for my $column (@$columns) {
		# DBI will give back backticked values from sqlite sometimes
		($column) = $column =~ /^`?(.*?)`?$/; 
	}
	
	return $columns;
};

override 'get_table_key_field_names' => sub {
	my ($self, %args) = @_;

	my %key_field_names;

	my $table_name = $args{table_name};
	die "invalid table name: $table_name" unless $table_name =~ /^\w+$/;

	# get indexes for this table
	my $indexes = $self->dbh->selectall_arrayref( "pragma index_list($table_name)", { Slice => {} } );

	for my $index (@$indexes) {

		# get columns for each index
		my $index_columns = $self->dbh->selectall_arrayref( "pragma index_info($index->{name})", { Slice => {} } );

		# check for uniqueness on a single column
		if (@$index_columns == 1) {
			my $index_column = shift @$index_columns;

			if ($index->{unique}) {
				$key_field_names{ $index_column->{name} } = 1;
			}
		}
	}

	for my $name (@{ $self->get_table_primary_key_field_names(table_name => $table_name) }) {
		$key_field_names{ $name } = 1 if $name;
	}
	
	return [ keys %key_field_names ];
};

override 'merge' => sub {

	my ($self, %args) = @_;

	my $table_name = $args{table_name};
	my $values = $args{values};

	my @values_pairs = $self->_compose_values_pairs(
		table_name => $table_name,
		values => $values
	);

	my $columns_clause = join ', ', map { $_->{column} } @values_pairs;
	my $values_clause = join ', ', map { $_->{value} } @values_pairs;

	eval {
		# don't worry too much about warnings here and hope for the best
		$SIG{__WARN__} = sub { };

		my $rows_affected = $self->dbh->do("insert into $args{table_name} ($columns_clause) values ($values_clause)");
	};

	if ($@) {
		if ($@ =~ /column (\w+) is not unique/s) {

			my $constraint_field_name = $1;
			return {
				constraint => 
				{ $constraint_field_name => $values->{$constraint_field_name} } 
			};

		} else {
			confess $@;
		}
	}

	my $key_field_value = $self->dbh->last_insert_id(undef, undef, $table_name, "");
	return { primary_id => $key_field_value };
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

Norma::DB::SQLite - SQLite driver for L<Norma::DB>

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.


