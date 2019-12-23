package App::Foo;

use strict;
use warnings;

use Role::Tiny::With;

use App::Foo::types;

with 'App::Foo::interface';# unless $ENV{APP_INTERFACE_NO_CHECKS};

sub test_me { shift; $_[0] / $_[1] }

1;
