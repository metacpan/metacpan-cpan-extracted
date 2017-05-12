package Norma::DB::MySQL;
our $VERSION = "0.02";

use Moose;

extends 'Norma::DB';

override 'get_table_key_field_names' => sub {
	
	my ($self, %args) = @_;
	my @key_field_names;

	my $table_name = $args{table_name};
	die "invalid table name: $table_name" unless $table_name =~ /^\w+$/;

	# get indexes for this table
	my $indexes = $self->dbh->selectall_arrayref( "show indexes from $table_name", { Slice => {} } );

	my $index_column_counts;
	for my $index (@$indexes) {
		$index_column_counts->{ $index->{Key_name} }++;
	}

	for my $index (@$indexes) {

		next if $index_column_counts->{ $index->{Key_name} } > 1;

		if (!$index->{Non_unique}) {
			push @key_field_names, $index->{Column_name};
		}
	}
	
	return \@key_field_names;
};

override 'select' => sub {

	my ($self, %args) = @_;

	my $table_name = $args{table_name};

	my $query = join ' ', grep { $_ }
		qq{select},
		qq{$table_name.* from},
		$args{join},
		$args{where},
		$args{order},
		$args{limit};

	my $rows = $self->dbh->selectall_arrayref($query, { Slice => {} });

	my $count_query = join ' ', grep { $_ }
		qq{select SQL_CALC_FOUND_ROWS count(*) from},
		$args{join},
		$args{where};

	my $total_count = $self->dbh->selectrow_array($count_query);

	return {
		total_count => $total_count,
		rows => $rows,
		query => $query,
	};
	

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


	my $rows_affected = $self->dbh->do("insert into $args{table_name} ($columns_clause) values ($values_clause) on duplicate key update id=last_insert_id(id)");

	my $key_field_value = $self->dbh->last_insert_id(undef, undef, $table_name, "");
	return { primary_id => $key_field_value };
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Norma::DB::MySQL - MySQL driver for L<Norma::DB>

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

