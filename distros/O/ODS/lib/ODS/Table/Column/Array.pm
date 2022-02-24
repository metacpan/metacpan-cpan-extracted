package ODS::Table::Column::Array;

use YAOO;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/clone error/;

has reference => isa(boolean);

has min_length => isa(integer);

has max_length => isa(integer);

has serialize_class => isa(object);

sub validation {
	if (ref($_[1] || "") ne 'ARRAY') {
		croak sprintf "The value passed to the %s column does not match the array constraint.",
			$_[0]->name;
	}
	if ($_[0]->min_length && $_[0]->min_length > scalar @{$_[1]}) {
		croak sprintf "The % column array length is less than the minimum allowed length for the attribute.",
			$_[0]->name;
	}
	if ($_[0]->max_length && $_[0]->max_length < scalar @{$_[1]}) {
		croak sprintf "The % column array length is greater than the maximum allowed length for the attribute.",
			$_[0]->name;
	}
	return $_[1];
}

sub inflation {
	my ($self, $value) = @_;
	if (! ref $value) {
		$value = $self->serialize_class->parse($value);
		$self->reference(1);
	}
	return $value;
}

sub deflation {
	my ($self, $value) = @_;
	if ($self->reference && ref $value) {
		$value = $self->serialize_class->stringify($value);
	}
	return $value;
}

1;

__END__
