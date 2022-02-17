package ODS::Table::Column::Epoch;

use YAOO;

extends 'ODS::Table::Column::Base';

has format => rw, isa(string);

#sub validation { return $_[1]; }

#sub inflation { return $_[1]; }

#sub deflation { return $_[1]; }

#sub coercion { return $_[1]; }

1;

__END__
