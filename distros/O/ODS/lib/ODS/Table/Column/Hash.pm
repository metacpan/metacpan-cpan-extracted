package ODS::Table::Column::Hash;

use YAOO;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/clone error/;

has reference => isa(boolean);

has required_keys => isa(array);

has serialize_class => isa(object);

sub validation {
	if (ref($_[1] || "") ne 'HASH') {
		croak sprintf "The value passed to the %s column does not match the hash constraint.",
			$_[0]->name;
	}
	my @missing;
	if (
		$_[0]->required_keys && do {
			@missing = grep { ! defined $_[1]->{$_} } @{$_[0]->required_keys};
			@missing;
		}
	) {
		croak sprintf "The % column array length is missing the following required keys %s.",
			$_[0]->name, join ", ", @missing;
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
