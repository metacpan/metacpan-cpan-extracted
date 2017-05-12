
use strict;
use warnings;

use Test::More;
use Test::Output qw(stderr_like);

BEGIN {
  delete $ENV{FOO_DEBUG};
  delete $ENV{PACKAGE_DEBUG_ALL};
}
{

  package Foo;

  use Package::Debug;

  sub some_code {
    for ( 1 .. 1_000_000 ) {
      DEBUG('ok');
    }
  }
}

stderr_like(
  sub {
    Foo->some_code();
  },
  qr/^$/,
  'Expected debug output is empty'
);
done_testing;

