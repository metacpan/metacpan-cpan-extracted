package Stencil::Source::Test;

use 5.014;

use strict;
use warnings;

use Data::Object::Class;

extends 'Stencil::Source';

# VERSION

1;

__DATA__

@=spec

name: MyApp

operations:
- from: class
  make: lib/MyApp.pm
- from: class-test
  make: t/MyApp.t

@=class

package [% data.name %];

use 5.014;

use strict;
use warnings;

1;

@=class-test

use 5.014;

use strict;
use warnings;

use Test::More;

use_ok '[% data.name %]';

ok 1 and done_testing;
