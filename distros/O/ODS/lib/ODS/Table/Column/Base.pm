package ODS::Table::Column::Base;

use YAOO;

use ODS::Utils qw/clone error/;

auto_build;

has name => rw, isa(string);

has type => rw, isa(string);

has value => rw, isa(any);

has mandatory => rw, isa(boolean);

has no_render => rw, isa(boolean);

has sortable => rw, isa(any);

has filterable => rw, isa(any);

has field => rw, isa(hash);

has inflated => rw, isa(boolean);

sub build_column {
	my ($self, $data, $already_inflated) = @_;

	$self = clone($self);

	$self->inflated($already_inflated);

	$self->value($data);

	$self->inflate($data);

	return $self;
}

sub store_column {
	my ($self) = @_;

	return $self->validate()->deflate();
}

sub validate {
	my ($self) = @_;

	# has_validation_class
	return $self unless $self->can('validation');

	$self->value(
		$self->validation($self->value)
	);

	return $self;
}

sub inflate {
	my ($self) = @_;

	# has_validation_class
	return $self unless not $self->inflated and $self->can('inflation');
	
	$self->value(
		$self->inflation($self->value)
	);

	$self->inflated(1);
	
	return $self;
}

sub deflate {
	my ($self) = @_;

	# has_validation_class
	return $self unless $self->inflated && $self->can('deflation');

	$self->value(
		$self->deflation($self->value)
	);

	$self->inflated(0);

	return $self;
}

sub coerce {
	my ($self) = @_;
	
	return unless $self->can('coercion');

	$self->value(
		$self->coercion($self->value)
	);
}

1;

__END__
