package Norma::ORM::Mappable;
our $VERSION = "0.02";

use MooseX::Role::Parameterized;
use Lingua::EN::Inflect::Number qw(to_S to_PL);

#use Norma::ORM::Meta::Display::Defaults;
use Norma::ORM::Collection;

use Norma::DB;
use Norma::ORM::Table;

use Carp qw(confess);

parameter dbh              => ( required => 1 );
parameter table_name       => ( required => 1 );
parameter key_field_names  => ( isa => 'ArrayRef' );
parameter defaults         => ( isa => 'HashRef' );
parameter logger           => ( isa => 'CodeRef' );
parameter relationships    => ( isa => 'ArrayRef' );

my %relationship_builder = map { $_ => \&{ $_ } } qw( has_one belongs_to has_many );

role {
	my $p = shift;

	confess "invalid table_name: " . $p->table_name unless $p->table_name =~ /^\w+$/;

	my $db = Norma::DB->initialize( dbh => $p->dbh );
	my $dbh = $db->dbh;

	my $columns_sth = $dbh->column_info(undef, undef, $p->table_name, '%');
	my $columns = $columns_sth->fetchall_arrayref({});

	my $table = Norma::ORM::Table->new(
		db   => $db,
		name => $p->table_name,
	);

	# add attributes for each column

	for my $column (@{ $table->columns }) {

		has $column->{COLUMN_NAME} => (
			is => 'rw',
			required => $column->{_NORMA_REQUIRED},
			#traits => [qw(AttributeDisplayDefaults)],
		);
	}

	# set up lazy loaded relationships

	for my $relationship (@{ $p->relationships || [] }) {
			
		my $builder = $relationship_builder{ $relationship->{nature} };
		die "unknown relationship type: $relationship->{nature}" unless $builder;

		$builder->($table, $relationship);

		has $relationship->{name} => ( is => 'rw', lazy_build => 1 ); 
	}

	sub BUILDARGS {
		my $class = shift;

		my %args = @_ > 1 ? @_ : @_ == 1 ? %{ shift @_ } : ();

		my $errors = $class->validate(%args);
		die $errors if $errors;

		return \%args;
	}

	method validate => sub {
		my ($class, %args) = @_;
		
		my $errors;

		for my $attribute ($class->meta->get_all_attributes) {
			
			if ($attribute->has_type_constraint) {
				
				my $constraint = $attribute->type_constraint;
				my $value = $args{$attribute->name};

				unless ($constraint->check($args{$attribute->name})) {
					$errors->{$attribute->name} = $constraint->get_message($value);
				}
			}
			
			if ($attribute->is_required) {
				unless ($args{$attribute->name}) {
					$errors->{$attribute->name} = "Missing required value for " . $attribute->name;
				}
			}
		}
		return $errors;
	};

	method reload => sub {
		my ($self, %args) = @_;
		
		if (my $_source = $self->{_source}) {

			# sneak in original criteria if we have it
			$args{ $_source->{key_field_name} } = $_source->{key_field_value};	
		}
	
		my $source = (ref $self)->_load_source(%args);
		
		for my $column_name (keys %{ $source->{row} }) {
			$self->$column_name( $source->{row}->{$column_name} );
		}
		$self->{_source} = $source;
	};
		
	method load => sub {
		my ($class, %args) = @_;

		my $table = $class->_table;
		my $dbh = $class->_dbh;
				
		my $source = $class->_load_source(%args);
		confess "no source: %args" unless $source;

		my $object = $class->new(%{ $source->{row} });
		$object->{_source} = $source;

		return $object;
	};

	method set => sub {
		my ($self, %args) =  @_;
		
		for my $field_name (map { $_->{COLUMN_NAME} } @{ $self->_table->{columns} }) {
			next if grep { $_ eq $field_name } @{ $self->_table->{key_field_names} };
			next unless $args{$field_name};

			$self->$field_name($args{$field_name});
		} 
	};

	method merge => sub {

		my ($self, %args) = @_;

		my $table = $self->_table;
		my $dbh = $self->_dbh;
		my $source = $self->{_source};

		my @mutable_field_names = map { $_->{COLUMN_NAME} } grep { ! $_->{_NORMA_PRIMARY_KEY} } @{ $table->{columns} };
		my %values = map { $_ => $self->$_ } @mutable_field_names;

		my $criteria = $db->merge(
			table_name => $table->name,
			values => \%values,
		);

		if ($criteria->{constraint}) {
			$self->reload(%{ $criteria->{constraint} });

		} elsif ($criteria->{primary_id}) {
			$self->reload( $table->primary_key => $criteria->{primary_id} );
		}

		return $self->{$table->primary_key};
	};
	
	method save => sub {

		my ($self, %args) = @_;

		my $table = $self->_table;
		my $dbh = $self->_dbh;
		my $source = $self->{_source};

		my @mutable_field_names = map { $_->{COLUMN_NAME} } grep { ! $_->{_NORMA_PRIMARY_KEY} } @{ $table->{columns} };
		my %values = map { $_ => $self->$_ } @mutable_field_names;

		my ($key_field_name, $key_field_value);
		
		if ($self->{_source}->{row}) {

			$key_field_name = $source->{key_field_name};
			$key_field_value = $source->{key_field_value};

			my $where_clause = "$source->{key_field_name} = " . $dbh->quote($source->{key_field_value});

			$db->update(
				table_name => $table->name,
				values => \%values,
				where => $where_clause,
				limit => 1,
			);

		} else {

			$db->insert(
				table_name => $table->name,
				values => \%values
			);

			$key_field_name = $table->primary_key;
			$key_field_value = $db->dbh->last_insert_id(undef, undef, $table->{name}, $key_field_name);

			$self->{_source} = { 
				key_field_name  => $key_field_name,
				key_field_value => $key_field_value,
				row => \%values 
			};
		}

		$self->reload($key_field_name => $key_field_value);

		return $key_field_value;
	};
	
	method collect => sub {
		my ($class, %args) = @_;

		my $collection = Norma::ORM::Collection->new(
			%args,
			class => $class
		);
		return $collection;
	};

	method delete => sub {
		my ($self) = @_;

		my $table = $self->_table;
		my $dbh = $self->_dbh;

		my $where_condition = join '=', 
			$self->{_source}->{key_field_name},
			$self->{_source}->{key_field_value};
	
		$db->delete(
			table_name => $table->name,
			where => $where_condition,
			limit => 1,
		);

	};

	method _table => sub {
		return $table;
	};

	method _defaults => sub { $p->defaults || {} };

	method _dbh => sub { $db->dbh };

	sub _load_source {
		my ($class, %args) = @_;

		my $dbh = $class->_dbh;
		my $table = $class->_table;

		my $row;

		for my $field_name (@{ $table->key_field_names }, @{ $table->{primary_key_field_names} }) {

			if (defined $args{$field_name}) {
				my $query = "select * from $table->{name} where $field_name = ? limit 1";
				$row = $dbh->selectrow_hashref($query, undef, $args{$field_name}); 
				confess "no row by that criteria: $class | $field_name => $args{$field_name}" unless $row;
				return {
					row => $row,
					key_field_name => $field_name,
					key_field_value => $args{$field_name}
				};	
			}
		}

		confess "no unique criteria: $class | " . join ', ', %args;
	}
};

sub belongs_to {
	my ($table, $relationship) = @_;
	
	my $foreign_key = $relationship->{foreign_key} || "$relationship->{name}_id";
	my $foreign_primary_key = $relationship->{foreign_primary_key} || 'id';

	method "_build_$relationship->{name}" => sub { 
		my ($self) = @_;
		$relationship->{class}->load( 
			$foreign_primary_key => $self->$foreign_key,
		);
	};
}

sub has_one {
	my ($table, $relationship) = @_;
	
	my $foreign_key = $relationship->{foreign_key} || "$relationship->{name}_id";
	my ($primary_key) = @{ $table->key_field_names };

	method "_build_$relationship->{name}" => sub { 
		my ($self) = @_;
		$relationship->{class}->load( 
			$foreign_key => $self->$primary_key
		);
	};
}

sub has_many {
	my ($table, $relationship) = @_;

	my $foreign_key = $relationship->{foreign_key} || to_S($table->name) . "_id";
	my $foreign_primary_key = $relationship->{foreign_primary_key} || 'id';

	my ($primary_key_name) = @{ $table->key_field_names };

	if ($relationship->{map_table}) {

		unless ( $relationship->{foreign_key} 
			 && $relationship->{foreign_primary_key} ) {

			confess "please specify foreign_key and foreign_primary_key names for map_table has_many relationship: $relationship->{name}";
		}

		method "_build_$relationship->{name}" => sub { 
			my ($self) = @_;
			$relationship->{class}->collect( 
				join => [ $relationship->{map_table} => join '=', 
						"$relationship->{map_table}.$relationship->{foreign_key}",
						$relationship->{class}->_table->{name} . ".$primary_key_name" ],
				where => [
					"$relationship->{map_table}.$relationship->{foreign_primary_key} = " . $self->$primary_key_name,
					$relationship->{where}
				]
			);
		};

	} else {

		method "_build_$relationship->{name}" => sub { 
			my ($self) = @_;
			$relationship->{class}->collect( 
				where => [ 
					"$foreign_key = " . $self->$primary_key_name,
					$relationship->{where}
				]
			);
		};
	}
}

1;

__END__

=head1 NAME

Norma::ORM::Mappable - A Moose role to map database tables to objects

=head1 SYNOPSIS

  package MyApp::Recipe;
  use Moose;

  with 'Norma::ORM::Mappable' => {
	dbh => $dbh,
	table_name => 'recipes',
  };

  1;

  package main;

  my $recipe = MyApp::Recipe->new(
  	title => 'Scrambled Eggs',
  	instructions => 'Break two eggs into a bowl...',
  );
  $recipe->save;

=head1 ROLE PARAMETERS

=head2 dbh => $dbh

A database handle from DBI->connect

=head2 table_name => $table_name

The name of the table which should map to this object

=head2 key_field_names => [$primary_key_name, ...] (optional)

A list of column names that should be seen as valid for unique lookups

=head2 relationships => [ { name => $name, class => $class, nature => $nature } ] (optional)

An arrayref of hashrefs, each hashref specifying a name, class, and nature.  The name will be used to create an accessor method on this object.  The class should be the class name of another object with Norma::ORM::Mappable role.  The nature is one of belongs_to, has_many, or has_one.  You may also specify foreign_key and foreign_primary_key as your naming scheme requires.  For example, our recipe might have tags and comments:
  
  with 'Neocracy::ORM::Table' => {
  	...
	table_name => 'recipes',
  	relationships => [ 
  		{
			name   => 'comments',
  			class  => 'MyApp::Recipe::Comment',
			nature => 'has_many',
		}, {
			name   => 'contributors',
  			class  => 'MyApp::Recipe::Contributor',
			nature => 'belongs_to',
		}, {
			name      => 'ingredients',
			class     => 'MyApp::Recipe::Ingredient',
			nature    => 'has_many',
			map_table => 'recipe_ingredients_map',
			foreign_key         => 'ingredient_id',
			foreign_primary_key => 'recipe_id',
		}
	];

Objects and collections loaded through these relationships will be loaded lazily.

=head1 METHODS PROVIDED BY THIS ROLE

=head2 new(...)

Instantiate an object in preparation for inserting a new row with save() or merge().  Use load() to instatiate an object from an existing row in the database.

=head2 load(id => $primary_key_id)

Class method to instantiate an object from an existing row in the database.  

=head2 save

Write the object to the database, either through an insert or an updated, depending on whether the object was instantiated via new() or load().

=head2 merge

Write to the database if the row passes any unique constraints, otherwise instantiate from the already-existing row.

=head2 validate

Perform subtype type checking to see that values pass attribute-level constraints.

=head2 delete

Delete from the database the row that corresponds to this object.

=head2 collect(where => { $column => $value }, ...)

Class method to return a collection of objects.  See L<Norma::ORM::Collection> for details.

=head1 SEE ALSO

L<Norma>, L<Norma::ORM::Collection>

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
