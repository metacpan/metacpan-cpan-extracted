
use Test::More tests => 11;

require_ok('MooseX::Alien');

{ package Foo;

  sub abc { 'abc' }
}
{ package Foo::Moose;
  use Moose;
  extends 'Foo';
  with 'MooseX::Alien';

  has 'xyz' => (
    is => 'ro', isa => 'Str', default => 'xyz' );
}

my $foo = Foo::Moose->new;
isa_ok($foo, 'Foo');
isa_ok($foo, 'Foo::Moose');
is($foo->abc, 'abc');
is($foo->xyz, 'xyz');

{ package Bar;

  sub new { my $class = shift; bless { @_ }, $class }
  sub def { shift->{def} }
}
{ package Bar::Moose;
  use Moose;
  extends 'Bar';
  with 'MooseX::Alien';

  has 'xyz' => (
    is => 'ro', isa => 'Str', default => 'xyz' );
}

my $bar= Bar::Moose->new(def => 'def' );
isa_ok($bar, 'Bar');
isa_ok($bar, 'Bar::Moose');
is($bar->def, 'def');
is($bar->xyz, 'xyz');

{ package FooBar;
  use Moose;
  my $fail = eval { with 'MooseX::Alien'; 1 };
  ::is($fail, undef);
  ::like($@, qr/Must call extends with alien class before applying MooseX::Alien role/);
}
