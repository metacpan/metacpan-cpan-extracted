
use strict;
use warnings;

use Test::More;
use Test::Output qw(stderr_like);

BEGIN {
  $ENV{FOO_DEBUG} = 1;
}

BEGIN {

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
  qr/^\[Foo\]\s+ok\s*$/,
  'Expected debug output'
);
ok( Foo->other_code, 'DEBUG value returned' );

done_testing;

