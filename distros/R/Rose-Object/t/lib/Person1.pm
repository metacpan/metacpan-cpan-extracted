package Person;

use strict;

use Rose::Object;
our @ISA = qw(Rose::Object);

use Rose::Object::MakeMethods::Generic
(
  scalar => 'name',
);

1;
