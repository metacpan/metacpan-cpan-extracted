package ODS::Table;

use strict;
use warnings;

use YAOO;

use ODS::Utils qw/clone/;

use ODS::Utils qw/load build_temp_class/;

use Carp qw/croak/;

auto_build;

has storage_class => isa(string);

has storage => isa(object);

has table_class => isa(string);

has resultset_class => isa(string);

has resultset => isa(object);

has name => isa(string);

has columns => isa(ordered_hash()), default(1);

has row_class => isa(string);

has rows => isa(array);

has options => isa(hash);

has keyfield => isa(string);

sub add_column {
	my ($self, @args) = @_;

	my $name = shift @args;

	if (!$self->keyfield) {
		$self->keyfield($name);
	}

	if ($self->columns->{$name}) {
		croak sprintf "Column %s is already defined in the %s table",
			$name, $self->name;
	}

	if (scalar @args  % 2) {
		croak "The column definition for %s does not contain an even number of key/values in the %s table.",
			$name, $self->name;
	}

	my %column = @args;
	$column{name} = $name;
	if (! $column{type}) {
		$column{type} = 'string';
	}

	if ($column{keyfield}) {
		$self->keyfield($name);
	}

	my $module = 'ODS::Table::Column::' . ucfirst($column{type});

	load $module;

	for my $key ( keys %column ) {
		delete $column{$key} if not defined $column{$key};
	}

	my $column = $module->new(\%column);

	$self->columns->{$name} = $column;

	return $self;
}

sub add_item {
	my ($self, @args) = @_;

	my $name = 'array_items';

	if (!$self->keyfield) {
		$self->keyfield($name);
	}

	if ($self->columns->{$name}) {
		croak sprintf "Column %s is already defined in the %s table",
			$name, $self->name;
	}

	if (scalar @args  % 2) {
		croak "The column definition for %s does not contain an even number of key/values in the %s table.",
			$name, $self->name;
	}

	my %column = @args;
	$column{name} = $name;
	if (! $column{type}) {
		$column{type} = 'string';
	}

	my $module = 'ODS::Table::Column::' . ucfirst($column{type});

	load $module;

	my $column = $module->new(\%column);

	$self->columns->{$name} = $column;

	return $self;
}

sub connect {
	my ($self, $package, $storage, $connect) = (shift, shift, shift, shift);

	$self->set_table_resultset_row_class($package);

	my $serialize_class;
	if ( $connect->{serialize_class} ) {
		$serialize_class = 'ODS::Serialize::' . $connect->{serialize_class};
		load $serialize_class;
		$serialize_class = $serialize_class->new;
	}

	$self->storage_class($storage) if $storage;

	$storage = $self->storage_class;

	my $module = 'ODS::Storage::' . $storage;

	load $module;

	$self->storage(
		$module->connect(
			%{$connect || {}},
			table => $self,
			($serialize_class ? (serialize_class => $serialize_class) : ())
		)
	);

	return $self->resultset($self->resultset_class->new(table => $self, @_));
}

has parent_column => isa(object);

sub instantiate {
	my ($self, $package, $column, $inflated, $data) = @_;

	$self->parent_column($column);

	$self->set_table_resultset_row_class($package);

	my $row = $self->row_class->new(
		table => $self,
		data => $data,
		inflated => $inflated || 0,
		serialize_class => $column->serialize_class
	);

	return $row;
}

sub set_table_resultset_row_class {
	my ($self, $package) = @_;

	$self->table_class($package);

	(my $resultset = $package) =~ s/Table/ResultSet/g;

	eval {
		load $resultset
	};

	if ($@) {
		$resultset = 'ODS::Table::ResultSet';
		load $resultset;
	}

	$self->resultset_class($resultset);

	(my $row = $package) =~ s/Table/Row/g;

	eval {
		load $row
	};

	if ($@) {
		$row = build_temp_class('ODS::Table::Row');
	}

	$self->row_class($row);
}

1;

__END__
