package Role::Age;

use strict;
use warnings;

use Simple::Accessor qw{age};

sub _build_age { 42 }

1;