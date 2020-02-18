# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 16;

BEGIN { use_ok( 'Package::New' ); }

{
  my $object = My::Package->new(x=>1, y=>"a");
  isa_ok($object, 'Package::New');
  isa_ok($object, 'My::Package');

  can_ok($object, qw{new initialize x y});
  is($object->x, "1", "args work");
  is($object->y, "a", "args work");
}

{
  my $object = My::Package->new(x=>undef)->new(x=>1, y=>"a");
  isa_ok($object, 'Package::New');
  isa_ok($object, 'My::Package');

  can_ok($object, qw{new initialize x y});
  is($object->x, "1", "args work");
  is($object->y, "a", "args work");
}

{
  my $object = new My::Package x=>1, y=>"a";
  isa_ok($object, 'Package::New');
  isa_ok($object, 'My::Package');

  can_ok($object, qw{new initialize x y});
  is($object->x, "1", "args work");
  is($object->y, "a", "args work");
}

{
  package #Hide from CPAN
  My::Package;
  use base qw{Package::New};
  sub x {shift->{"x"}};
  sub y {shift->{"y"}};
  1;
}
