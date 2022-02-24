package ODS::Storage::Base;

use YAOO;

use ODS::Iterator;

auto_build;

has table => isa(object);

has serialize_class => isa(object);

sub connect {
	my ($self, %params) = @_;
	$self = $self->new(%params);
	return $self;
}

sub into_rows {
	my ($self, $data, $inflated) = @_;

	$data = $self->parse_data_format($data)
		if (not ref $data and $self->can('parse_data_format'));

	if (ref $data eq 'ARRAY') {
		my @rows;
		for my $row ( @{ $data } ) {
			push @rows, $self->table->row_class->new(
				table => $self->table,
				data => $row,
				inflated => $inflated || 0,
				serialize_class => $self->serialize_class
			);
		}
		$self->table->rows(\@rows);

		return ODS::Iterator->new(table => $self->table);
	} elsif (ref $data eq 'HASH') {
		return $self->table->row_class->new(
			table => $self->table,
			data => $data,
			inflated => $inflated || 0,
			serialize_class => $self->serialize_class
		);
	}

	return undef;
}

sub into_storage {
	my ($self, $all) = @_;

	my $data;
	if ($all && !ref $all) {
		for my $row (@{ $self->table->rows }) {
			my $val = $row->store_row();
			push @{$data}, $val;
		}
	} elsif ($all) {
		$data = $all->store_row();
	} else {
		$data = $self->table->rows->[-1]->store_row();
	}

	$data = $self->stringify_data_format($data)
		if (ref $data and $self->can('stringify_data_format'));

	return $data;
}

1;

