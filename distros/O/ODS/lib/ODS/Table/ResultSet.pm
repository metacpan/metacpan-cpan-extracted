package ODS::Table::ResultSet;

use YAOO;

auto_build;

has table => isa(object);

sub all {
	my ($self, @params) = @_;
	return $self->table->storage->all(@params);
}

sub search {
	my ($self, @params) = @_;
	$self->table->storage->search(@params);
}

sub find {
	my ($self, @params) = @_;
	$self->table->storage->find(@params);
}

sub create {
	my ($self, @params) = @_;
	$self->table->storage->create(@params);
}

sub update {
	my ($self, @params) = @_;
	$self->table->storage->update(@params);
}

sub delete {
	my ($self, @params) = @_;
	$self->table->storage->delete(@params);
}

1;
