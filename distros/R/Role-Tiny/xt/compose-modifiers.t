use strict;
use warnings;
use Test::More;

use Class::Method::Modifiers 1.05 ();

{
  package One; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Two; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Three; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Four; use Role::Tiny;
  requires 'foo';
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package BaseClass; sub foo { __PACKAGE__ }
}

foreach my $combo (
  [ qw(One Two Three Four) ],
  [ qw(Two Four Three) ],
  [ qw(One Two) ]
) {
  my $combined = Role::Tiny->create_class_with_roles('BaseClass', @$combo);
  is_deeply(
    [ $combined->foo ], [ reverse(@$combo), 'BaseClass' ],
    "${combined} ok"
  );
  my $object = bless({}, 'BaseClass');
  Role::Tiny->apply_roles_to_object($object, @$combo);
  is(ref($object), $combined, 'Object reblessed into correct class');
}

{
  package BaseClassNoFoo;
  sub bar { __PACKAGE__ }
}

{
  is eval {
    package WithFour;
    use Role::Tiny::With;
    use base 'BaseClassNoFoo';
    with 'Four';
  }, undef,
    "composing an around modifier fails when method doesn't exist";
  like $@, qr/Can't apply Four to WithFour - missing foo/,
    ' ... with correct error message';
}
{
  is eval {
    Role::Tiny->create_class_with_roles('BaseClassNoFoo', 'Four');
  }, undef,
    "composing an around modifier fails when method doesn't exist";
  like $@, qr/Can't apply Four to .* - missing foo/,
    ' ... with correct error message';
}

{
  package WrapsMultiple;
  use Role::Tiny;
  around 'method1', 'method2', sub {
    my $orig = shift;
    return (__PACKAGE__, $orig->(@_));
  };
  around [ 'method3', 'method4' ], sub {
    my $orig = shift;
    return (__PACKAGE__, $orig->(@_));
  };
}

{
  package ClassToWrapMultiple;
  use Role::Tiny::With;
  sub method1 { __PACKAGE__ }
  sub method2 { __PACKAGE__ }
  sub method3 { __PACKAGE__ }
  sub method4 { __PACKAGE__ }
  with 'WrapsMultiple';
}

for my $method (qw(method1 method2)) {
  is_deeply(
    [ ClassToWrapMultiple->$method ], [ 'WrapsMultiple', 'ClassToWrapMultiple' ],
    'wrapping multiple methods using list works',
  );
}

for my $method (qw(method3 method4)) {
  is_deeply(
    [ ClassToWrapMultiple->$method ], [ 'WrapsMultiple', 'ClassToWrapMultiple' ],
    'wrapping multiple methods using arrayref works',
  );
}

done_testing;
