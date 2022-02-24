package ODS::Table::Column::ArrayObject;

use YAOO;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/clone error deep_unblessed reftype/;

has reference => isa(boolean);

has blessed => isa(boolean), default => 0;

has min_length => isa(integer);

has max_length => isa(integer);

has object_class => isa(string);

has serialize_class => isa(object);

sub validation {
	my ($self, $value) = @_;

	if (ref($value || "SCALAR") =~ m/ARRAY/) {
		$value = $self->inflation($value);
	}

	my $internal = $value->columns->{array_items}->value();

	if ((reftype($internal) || "") ne 'ARRAY') {
		croak sprintf "The value passed to the %s column does not match the array object constraint.",
			$self->name;
	}
	if ($self->min_length && $self->min_length > scalar @{$internal}) {
		croak sprintf "The % column array length is less than the minimum allowed length for the attribute.",
			$self->name;
	}
	if ($self->max_length && $self->max_length < scalar @{$internal}) {
		croak sprintf "The % column array length is greater than the maximum allowed length for the attribute.",
			$self->name;
	}

	return $value;
}

sub inflation {
	my ($self, $value) = @_;

	if (! ref $value) {
		$value = $self->serialize_class->parse($value);
		$self->reference(1);
	}

	return ref($value) =~ m/ARRAY/ ?  do {
		$self->blessed(1);
		$value = $self->object_class->instantiate($self, 0, $value);
		$value;
	} : $value;
}

sub deflation {
	my ($self, $value) = @_;

	if (reftype($value || "") eq 'HASH' && $self->blessed) {
		$value = $value->columns->{array_items}->value();
		$value = [ map { $_->store_row() } @{ $value } ];
	}

	if ($self->reference && ref $value) {
		$value = $self->serialize_class->stringify($value);
	}

	return $value;
}

1;

__END__
