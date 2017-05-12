package Role;

use MooseX::Role::WithOverloading;
use namespace::autoclean 0.16;

use overload
    q{""}    => 'as_string',
    fallback => 1;

has message => (
    is       => 'rw',
    isa      => 'Str',
);

sub as_string { shift->message }

1;
