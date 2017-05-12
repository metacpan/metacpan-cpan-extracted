use strict;
use warnings;

use Test::More;

{
  package Foo;
  use Moose::Role;
  use t::TagProvider;

  add_tags { qw(foo bar) };
}

{
  package Bar;
  use Moose::Role;
  use t::TagProvider;

  add_tags { qw(bar quux) };
}

{
  package Thing;
  use Moose;
  use t::TagProvider;

  with qw(Foo Bar t::OneOffTags);

  add_tags { qw(bingo) };
}

{
  package OtherThing;
  use Moose;
  use t::TagProvider;

  with qw(Bar t::OneOffTags);
}

my $obj = Thing->new({ tags => [ qw(xyzzy) ] });

ok(
  $obj->does('t::TagProvider'),
  "the object does t::TagProvider",
);

is_deeply(
  [ sort $obj->tags ],
  [ sort qw(foo bar bar quux bingo xyzzy) ],
  "composed tags from classes, roles, and instance",
);

is_deeply(
  [ sort OtherThing->new->tags ],
  [ sort qw(bar quux) ],
  "more composed tags from classes",
);

done_testing;
