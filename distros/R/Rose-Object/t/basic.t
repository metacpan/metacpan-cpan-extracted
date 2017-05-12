#!/usr/bin/perl

use strict;

use Test::More tests => 22;

BEGIN
{
  use_ok('Rose::Object');
  use_ok('Rose::Class');
}

my($p, $name, $age, $ok);


$p = Person->new();
ok($p && $p->isa('Person'), 'new() 1');

is($p->name('John'), 'John', 'set 1');
is($p->age(26), 26, 'set 2');

is($p->name(), 'John', 'get 1');
is($p->age(), 26, 'get 2');

$p = Person->new(name => 'John2', age => 26);
ok($p && $p->isa('Person'), 'new() 2');

is($p->name(), 'John2', 'get 3');
is($p->age(), 26, 'get 4');

is($p->name('Craig'), 'Craig', 'set 3');
is($p->age(50), 50, 'set 4');

is($p->name(), 'Craig', 'get 5');
is($p->age(), 50, 'get 6');

is(Person->error, undef, 'class get 1');
is(Person->error('foo'), 'foo', 'class set 1');
is(Person->error, 'foo', 'class get 2');

is($p->yippee, 'yip', 'mixin yip');
is($p->bark, 'bark', 'mixin bark');
is($p->roar, 'rawr', 'mixin rawr');
is($p->hiss, 'hiss', 'mixin hiss');

DogLike->import(qw(-target_class Nonesuch yip));

ok(Nonesuch->can('yip'), 'mixin -target_class yip');

BEGIN
{
  use strict;

  package DogLike;
  use Rose::Object::MixIn();
  our @ISA = qw(Rose::Object::MixIn);
  __PACKAGE__->export_tags(all => [ qw(bark yip) ]);
  sub bark { 'bark' }
  sub yip { 'yip' }

  package CatLike;
  use Rose::Object::MixIn();
  our @ISA = qw(Rose::Object::MixIn);
  __PACKAGE__->export_tags(all => [ qw(rawr hiss) ], mean => [ 'hiss' ]);
  sub rawr { 'rawr' }
  sub hiss { 'hiss' }

  package Person;

  DogLike->import('bark', { yip => 'yippee' });
  CatLike->import({ rawr => 'roar' }, ':mean');

  @Person::ISA = qw(Rose::Class Rose::Object);

  use Rose::Object::MakeMethods::Generic
  (
    scalar => [ qw(name age) ],
  );
}
