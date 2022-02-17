package ODS::Table::Column::Float;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/error/;

has precision => isa(integer);

has number => isa(boolean);

sub validation { 
        if (ref($_[1]) || ${$_[1]} !~ m/\d+(\.\d+)?/) {
                croak sprintf "The value passed to the %s column does not match the float constraint.",
                        $_[0]->name;
        }
	return $_[1]; 
}

sub inflation {
	my ($self, $value) = @_;
	if ($self->precision) {
		my $precision = '%.' . $self->precision . 'f';
		$value = sprintf($precision, $value);
	}
	return $value;
}

sub deflation {
	my ($self, $value) = @_;
	if ($_[0]->number && $_[0]->precision) {
		$value = 0 + $value;
	}
	return $value;
}

1;

__END__
