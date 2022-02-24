package ODS::Table::Row;

use YAOO;

use overload
	'%{}' => sub {  caller() =~ m/YAOO$/ ? $_[0] : $_[0]->as_hash; },
	fallback => 1;

has table => isa(object);

has columns => isa(ordered_hash), default(1);

has __file => isa(string);

has __custom_file_name => isa(string);

sub build {
	my ($self, %args) = @_;

	$self->table($args{table});

	if (ref $args{data} eq 'ARRAY') {
		my $column = 'array_items';
		my $value = [ map { $self->table->parent_column->object_class->instantiate($self->table->parent_column, 0, $_) } @{ $args{data} } ];

		my $col = $self->table->columns->{$column}->build_column(
			$value, $args{inflated}, $args{serialize_class}
		);
		$self->columns->{$column} = $col;
		return $self;
	}

	$self->__custom_file_name(delete $args{data}{__custom_file_name});
	$self->__file(delete $args{data}{__file});

	for my $column ( keys %{ $self->table->columns } ) {
		my $col = $self->table->columns->{$column}->build_column(
			$args{data}{$column}, $args{inflated}, $args{serialize_class}
		);
		$self->columns->{$column} = $col;
		YAOO::make_keyword($self->table->row_class, $column, sub {
			my $self = shift;
			$self->columns->{$column}->value(@_);
		}) unless $self->can($column);
	}
	return $self;
}

sub as_hash {
	my %hash;
	$hash{$_} = $_[0]->columns->{$_}->value
		for keys %{$_[0]->columns};
	return \%hash;
}

sub set_row {
	my ($self, $data) = @_;
	for my $key ( keys %{ $data } ) {
		$self->$key($data->{$key});
	}
}

sub store_row {
	my ($self, $data) = @_;
	$self->set_row($data) if defined $data && ref($data || "") eq "HASH";
	my %hash = map +(
		$_ => $self->columns->{$_}->store_column()->value
	), keys %{ $self->columns };
	return \%hash;
}

sub validate {
	my ($self, $data) = @_;
	$self->set_row($data) if defined $data && ref($data || "") eq "HASH";
	my %hash = map +(
		$_ => $self->columns->{$_}->validate()->value
	), keys %{ $self->columns };
	return \%hash;
}

sub update {
	my ($self, $update) = (shift, @_ > 1 ? { @_ } : $_[0]);
	$self->set_row($update);
	$self->table->storage->update_row($self);
}

sub delete {
	my ($self) = @_;
	$self->table->storage->delete_row($self);
}

1;
