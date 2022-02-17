package ODS::Table::Column::Integer;

use YAOO;

extends 'ODS::Table::Column::Base';

use ODS::Utils qw/error/;

has auto_increment => rw, isa(boolean);

sub validation {
        if (ref($_[1]) || ${$_[1]} !~ m/\d+/) {
                croak sprintf "The value passed to the %s column does not match the integer constraint.",
                        $_[0]->name;
        }
	return $_[1]; 
}

sub inflation { return 0 + $_[1]; }

sub deflation { return 0 + $_[1]; }

#sub coercion { return $_[1]; }

1;

__END__
