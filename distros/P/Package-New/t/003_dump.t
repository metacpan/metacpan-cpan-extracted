# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 12;

BEGIN { use_ok( 'Package::New::Dump' ); }

my $object = Bar->new(one=>{two=>{three=>{four=>{}}}});
isa_ok($object, 'Bar');
isa_ok($object, 'Foo');
isa_ok($object, 'Package::New::Dump');
isa_ok($object, 'Package::New');

can_ok($object, qw{new initialize dump});
can_ok($object, qw{bar});
can_ok($object, qw{baz});
is($object->bar, "baz", "object method");
is(Bar->bar,     "baz", "class method");
is($object->baz, "buz", "object method");
is(Bar->baz,     "buz", "class method");

if ($ENV{"DEVELOPER"}) {
  diag("Dump Level 1");
  diag($object->dump(1));
  diag("Dump Level default");
  diag($object->dump);
  diag("Dump Level 2");
  diag($object->dump(2));
  diag("Dump Level 3");
  diag($object->dump(3));
  diag("Dump Level 4");
  diag($object->dump(4));
  diag("Dump Level 0");
  diag($object->dump(0));
}

package #hide
Foo;
use base qw{Package::New::Dump};
sub bar {"baz"};
1;

package #hide
Bar;
use base qw{Foo};
sub baz {"buz"};
1;

