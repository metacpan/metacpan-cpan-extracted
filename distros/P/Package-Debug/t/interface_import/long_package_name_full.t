
use strict;
use warnings;

use Test::More;
use Test::Output qw(stderr_like);

BEGIN {
  #    $ENV{FOO_HAS_A_HUGE_NAME_DEBUG} = 1;
  $Foo::Has::A::Huge::Name::DEBUG = 1;
  $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE} = 'long';
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

  sub modify_val {
    $DEBUG = 2;
  }
}

stderr_like(
  sub {
    Foo::Has::A::Huge::Name->some_code();
  },
  qr/^\[Foo::Has::A::Huge::Name\]\s+ok\s*$/,
  'Expected debug output'
);
ok( Foo::Has::A::Huge::Name->other_code, 'DEBUG value returned' );
done_testing;

