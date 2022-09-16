package My::Class::T12;

use Moo::Role;

use namespace::clean;

use My::Class::T1;
use My::Class::T2;

has t12_1 => ( is => 'ro', default => 't12_1.v' );

1;


