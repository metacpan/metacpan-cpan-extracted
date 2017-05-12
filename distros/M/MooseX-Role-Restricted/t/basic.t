
use Test::More tests => 6;

require_ok('MooseX::Role::Restricted');
{ package Foo;
  use MooseX::Role::Restricted;

  sub _abc {}
  sub _def :Public {}
  sub abc {}
  sub def :Private {}
}
{ package Bar;
  use Moose;
  with 'Foo';
}

my $obj = Bar->new;
ok($obj);
can_ok($obj, 'abc');
can_ok($obj, '_def');
ok(!$obj->can('_abc'));
ok(!$obj->can('def'));

