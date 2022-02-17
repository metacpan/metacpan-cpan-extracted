package ODS::Table::Column::String;

use YAOO;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/error/;

sub validation { 
        if (ref($_[1])) {
                croak sprintf "The value passed to the %s column does not match the integer constraint.",
                        $_[0]->name;
        }
	return $_[1]; 
}

#sub inflation { return $_[1]; }

#sub deflation { return $_[1]; }

#sub coercion { return $_[1]; }

1;

__END__
