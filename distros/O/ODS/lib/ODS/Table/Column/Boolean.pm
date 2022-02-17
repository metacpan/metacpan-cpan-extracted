package ODS::Table::Column::Boolean;

use YAOO;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/clone error/;

has reference => isa(boolean);

sub validation {
        if (ref($_[1] || "") ne 'SCALAR' && ${$_[1]} !~ m/1|0/) {
                croak sprintf "The value passed to the %s column does not match the boolean constraint.",
                        $_[0]->name;
        }
	return $_[1]; 
}

sub inflation { 
	my ($self, $value) = @_; 
        if (! ref $value) {
		$self->reference(\1);
                $value = \!!$value;
        }
}

sub deflation {
	my ($self, $value) = @_;
	if ($self->reference && ref $value) {
		$value = $$value;
	}
	return $value; 
}

1;

__END__
