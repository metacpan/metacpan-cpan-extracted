package ODS::Table::Column::Object;

use YAOO;

use Scalar::Util;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/clone error deep_unblessed/;

has reference => isa(boolean), default => 0;

has blessed => isa(boolean), default => 0;

has object_class => isa(string);

has serialize_class => isa(object);

sub validation {
	my ($self, $value) = @_;
	if (ref($value || "SCALAR") =~ m/ARRAY|HASH|SCALAR/) {
		$value = $self->inflation($value);
	}
	return $value;
}

sub inflation {
	my ($self, $value) = @_;

	if (! ref $value) {
		$value = $self->serialize_class->parse($value);
		$self->reference(1);
	}

	return ref($value) =~ m/HASH|ARRAY|SCALAR/  ?  do {
		$self->blessed(1);
		if (ref $value eq 'ARRAY') {
			$value = [ map { $self->object_class->instantiate($self, 0, $_) } @{ $value } ];
		} else {
			$value = $self->object_class->instantiate($self, 0, $value);
		}
		$value;
	} : $value;
}

sub deflation {
	my ($self, $value) = @_;
	if ($self->blessed) {
		$value = deep_unblessed $value;
		$value = { map {
			my $val = ref $value->{$_} ? $value->{$_}->store_row() : $value->{$_};
			$_ => $val
		}  keys %{ $value } };
	}
	if ($self->reference && ref $value) {
		$value = $self->serialize_class->stringify($value);
	}
	return $value;
}

1;

__END__
