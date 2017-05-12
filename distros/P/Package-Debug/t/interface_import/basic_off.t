
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
    DEBUG('ok');
  }

  sub other_code {
    return $DEBUG;
  }
}

stderr_like(
  sub {
    Foo->some_code();
  },
  qr/^$/,
  'Expected debug output is empty'
);
ok( !Foo->other_code, 'DEBUG value retuned false' );

done_testing;

