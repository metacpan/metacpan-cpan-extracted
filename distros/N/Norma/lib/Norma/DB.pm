package Norma::DB;
our $VERSION = "0.02";

use Moose;
use DBI;

use Carp qw(confess);

has 'dbh' => (is => 'rw');

no Moose;

sub BUILD {
	my ($self) = shift;

	#die "please call initialize() instead of instantiating directly";
}

sub initialize {

	my ($class, %args) = @_;

	unless ($args{dbh} or $args{dsn}) {
		die "please provide a dbh or a dsn";
	}

	my $dbh = $args{dbh};

	unless ($dbh) {
		my $dsn = $args{dsn};
		my $username = $args{username} || '';
		my $password = $args{password} || '';
		my $attr = $args{attr};

		# default RaiseError to true
		$attr = { RaiseError => 1, %{ $attr || {} } };

		my $connect_method = $args{no_connection_caching} ? 'connect' : 'connect_cached';
		$dbh = DBI->$connect_method( $dsn, $username, $password, $attr );
	}

	my $driver_class_map = {
		'mysql'  => 'Norma::DB::MySQL',
		'SQLite' => 'Norma::DB::SQLite', 
	};

	my $dbi_driver = $dbh->{Driver}->{Name};
	my $driver_class = $driver_class_map->{ $dbi_driver };

	unless ($driver_class) {
		die "couldn't find class for driver: $dbi_driver";
	}

	eval "use $driver_class";
	die $@ if $@;

	return $driver_class->new(dbh => $dbh);
}

sub get_table_definition {

	my ($self, %args) = @_;

	my $table_name = $args{table_name};
	die "invalid table_name: $table_name" unless $table_name =~ /^\w+$/;

	my $columns_sth = $self->dbh->column_info(undef, undef, $args{table_name}, '%');
	my $columns = $columns_sth->fetchall_arrayref({});

	confess "couldn't get table definition: " . $args{name} unless $columns;

	return $columns;
}

sub get_table_primary_key_field_names {

	my ($self, %args) = @_;

	my $table_name = $args{table_name};
	die "invalid table_name: $table_name" unless $table_name =~ /^\w+$/;

	my $primary_keys = [ $self->dbh->primary_key(undef, undef, $table_name) ];

	return $primary_keys;
}

sub get_table_key_field_names {

	# db drivers should override 
	confess "get_table_key_field_names not implemented";
}

sub insert {
	
	my ($self, %args) = @_;

	my $table_name = $args{table_name};
	my $values = $args{values};

	my @values_pairs = $self->_compose_values_pairs(
		table_name => $table_name,
		values => $values
	);

	my $columns_clause = join ', ', map { $_->{column} } @values_pairs;
	my $values_clause = join ', ', map { $_->{value} } @values_pairs;

	my $rows_affected = $self->dbh->do("insert into $table_name ($columns_clause) values ($values_clause)");
	
	my $key_field_value = $self->dbh->last_insert_id(undef, undef, $table_name, "");

	return $key_field_value;
}

sub merge {
	
	# db drivers should override
	confess "merge not implemented";
}

sub delete {
	my ($self, %args) = @_;

	my $table_name = $args{table_name};
	my $where_clause = "where $args{where}" if $args{where};

	my $rows_affected = $self->dbh->do("delete from $table_name $where_clause");

	return $rows_affected;
}

sub update {
	
	my ($self, %args) = @_;

	my $table_name = $args{table_name};
	my $values = $args{values};
	my $where_clause = $args{where} ? "where $args{where}" : '';

	my @values_pairs = $self->_compose_values_pairs(
		table_name => $table_name,
		values => $values,
	);

	my $values_clause = join ', ', map { "$_->{column} = $_->{value}" } @values_pairs;
	my $rows_affected = $self->dbh->do("update $table_name set $values_clause $where_clause");

	return $rows_affected;
}

sub select {

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
		qq{select count(*) from},
		$args{join},
		$args{where};

	my $total_count = $self->dbh->selectrow_array($count_query);

	return {
		total_count => $total_count,
		rows => $rows,
		query => $query,
	};
}

sub _compose_values_pairs {

	my ($self, %args) = @_;

	my $values = $args{values};
	my @values_pairs;

	for my $field_name (keys %$values) {
		my $quoted_value;
		if (ref $values->{$field_name} && ref $values->{$field_name} eq 'CODE') {
			$quoted_value = $values->{$field_name}->();
		} else {
			$quoted_value = $self->dbh->quote($values->{$field_name});
		}
		push @values_pairs, {
			column => $field_name,
			value => $quoted_value
		};
	}
	
	return @values_pairs;
}

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

Norma::DB - Easy interface to fundamental data access and table definition operations in DBI

=head1 SYNOPSIS

  use Norma::DB;

  my $db = Norma::DB->initialize(
      dsn => 'dbi:mysql:database=testdb',
      username => 'dbuser',
      password => 'dbpassword',
  );

  my $id = $db->insert(
      table_name => 'recipes',
      values => {
          title => "Scrambled Eggs",
          instructions => 'Break two eggs into a bowl...',
          date_added => sub { 'NOW()' },
          ...
      }
  );

  $db->update(
      table_name => 'recipes',
      values => { title => "Delicious Scrambled Eggs" },
      where => "id = 1",
  );

  my $recipe = $db->select(
      table_name => 'recipes', 
      where => "id = 1",
  );

  $db->delete(
      table_name => 'recipes',
      where => "id = 1",
  );

=head1 METHODS

=head2 initialize( dsn => $dsn, username => $username, password => $password )

Set up an instance, given some connection criteria and authentication info.  Alternatively, pass in an existing database handle as "dbh" if you already have one.

=head2 insert( table_name => $table_name, values => {...} )

Insert a row, given a table name and values for the row.  Values will be escaped using DBI::quote except for subref values.  Values that are references to subs will be executed, and their return value subtituted in for that column, useful for calling database functions (e.g. date_created => sub { 'NOW()' }).  Returns the primary id for the inserted row.

=head2 merge( table_name => $table_name, values => {...} )

Similar to insert, but only insert the row if it's not already there (i.e., if it doesn't break a unique constraint).  Values are processed as they are in insert().  Return criteria to select the row, whether it was inserted or already there.  Implemented nicely in a single query for MySQL, less elegantly for SQLite.

=head2 update( table_name => $table_name, values => {...}, where => $where_condition )

Update rows in a table, given values to update, and matching criteria.  Values are processed as they are in insert() Returns the number of rows affected.

=head2 delete( table_name => $table_name, where => $where_condition )

Delete rows in a table, given criteria.  Returns number of rows affected.

=head2 select( table_name => $table_name, where => $where_condition )

Select rows from a table, given criteria.

=head2 get_table_definition( table_name => $table_name )

Get a table definition, given a table name

=head2 get_table_primary_key_field_names( table_name => $table_name )

Get primary key field names, given a table name.

=head2 get_table_key_field_names( table_name => $table_name ) 

Get names of columns that have single-column unique/primary indexes, given a table name

=head1 Database-Specific Drivers

DBI is great, but it doesn't cover everything.  Norma::DB is augmented by database-specific drivers in order to support some bits of functionality like merge() and get_table_key_field_names()

Norma::DB::MySQL provides support for MySQL
Norma::DB::SQLite provides support for SQLite3

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.


