package ODS::Table::Column::Phone;

use ODS::Utils qw/error valid_phone/;

extends 'ODS::Table::Column::Base';

sub validation { 
	if (ref($_[1]) || ! valid_phone($_[1])) {
		croak sprintf "The value passed to the %s column does not match the phone constraint.",
			$_[0]->name;
	}
	return $_[1];
}

#sub inflation { return $_[1]; }

#sub deflation { return $_[1]; }

#sub coercion { return $_[1]; }

1;

__END__
