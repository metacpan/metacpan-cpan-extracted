use strict;
use warnings;
use Test::More tests => 5;

{ package Bar; use Moose; }

{
  package Foo;
  use Moose;
  has bar_class => (is => 'rw', isa => 'ClassName', default => 'Bar');

  with 'MooseX::RelatedClassRoles' => { name => 'bar' };
}

{
  package MyRole;
  use Moose::Role;
}

can_ok('Foo', 'apply_bar_class_roles');
my $foo = Foo->new;
$foo->apply_bar_class_roles('MyRole');
ok(
  Class::MOP::class_of($foo->bar_class)->does_role('MyRole'),
  "\$foo's bar_class now does MyRole",
);

eval {
  package Foo2;
  use Moose;
  with 'MooseX::RelatedClassRoles' => { name => 'bar' };
};
like $@, qr/requires the method 'bar_class'/,
  "class_accessor_name is required";

eval {
  package Foo2b;
  use Moose;
  with 'MooseX::RelatedClassRoles' => {
    name => 'bar',
    require_class_accessor => 0,
  };
};
is $@, "", "no error with override";

{
  package Foo3;
  use Moose;
  has bar_thing => (is => 'rw', default => 'Bar');
  with 'MooseX::RelatedClassRoles' => {
    name => 'bar',
    class_accessor_name => 'bar_thing',
    apply_method_name   => 'make_bar_thing_do',
  };
}
$foo = Foo3->new;
$foo->make_bar_thing_do('MyRole');
ok(
  Class::MOP::class_of($foo->bar_thing)->does_role('MyRole'),
  "no defaults",
);
