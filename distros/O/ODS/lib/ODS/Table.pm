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

has columns => isa(ordered_hash), default(1);

has row_class => isa(string);

has rows => isa(array);

has options => isa(hash);

has keyfield => isa(string);

sub add_column {
	my ($self, @args) = @_;

	my $name = shift @args;

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

	my $column = $module->new(\%column);

	$self->columns->{$name} = $column;
	
	return $self;
}

sub connect {
	my ($self, $package, $storage, $connect) = (shift, shift, shift, shift);
	

	if (ref $storage) {
		$connect = $storage;
		$storage = undef;
	} 

	$self->table_class($package);

	(my $resultset = $package) =~ s/Table/ResultSet2/g;
	
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

	$self->storage_class($storage) if $storage;

	$storage = $self->storage_class;

	my $module = 'ODS::Storage::' . $storage;

	load $module;

	$self->storage($module->connect(%{$connect || {}}, table => $self));

	return $self->resultset($self->resultset_class->new(table => $self, @_));
}


1;

__END__
