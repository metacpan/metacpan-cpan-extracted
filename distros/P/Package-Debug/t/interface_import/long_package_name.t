
use strict;
use warnings;

use Test::More;
use Test::Output qw(stderr_like);

BEGIN {
  $ENV{FOO_HAS_A_HUGE_NAME_DEBUG} = 1;
  undef $ENV{PACKAGE_DEBUG_PREFIX_FULL};
}

{

  package Foo::Has::A::Huge::Name;

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
    Foo::Has::A::Huge::Name->some_code();
  },
  qr/^\[F:H:A:H::Name\]\s+ok\s*$/,
  'Expected debug output'
);
ok( Foo::Has::A::Huge::Name->other_code, 'DEBUG value returned' );

done_testing;

