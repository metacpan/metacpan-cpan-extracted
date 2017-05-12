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
  package Five; use Role::Tiny;
  requires 'bar';
  around bar => sub { my $orig = shift; $orig->(@_) };
}
{
  is eval {
    package WithFive;
    use Role::Tiny::With;
    use base 'BaseClass';
    with 'Five';
  }, undef,
    "composing an around modifier fails when method doesn't exist";
  like $@, qr/Can't apply Five to WithFive - missing bar/,
    ' ... with correct error message';
}
{
  is eval {
    Role::Tiny->create_class_with_roles('BaseClass', 'Five');
  }, undef,
    "composing an around modifier fails when method doesn't exist";
  like $@, qr/Can't apply Five to .* - missing bar/,
    ' ... with correct error message';
}

done_testing;
