use strict;
use warnings;
use Test::More 0.88;

{
  package Foo::Subsystem;
  use Moose;
  with 'Role::Subsystem' => {
    ident     => 'obj-subsystem',
    type      => 'Foo',
    what      => 'foo',
    id_method => 'id',
    getter    => sub { Foo->new({ id => $_[0] }) },
  };
}

{
  package Foo;
  use Moose;
  my $counter = 0;
  has id     => (is => 'ro',                    default => sub { ++$counter });
  has abs_id => (is => 'ro', init_arg => undef, default => sub { ++$counter });

  sub subsystem {
    my ($self) = @_;
    Foo::Subsystem->for_foo($self);
  }
}

my $id  = 123;
my $foo = Foo->new({ id => $id });
my $fid = $foo->abs_id;
my $sys = $foo->subsystem;

isa_ok($sys, 'Foo::Subsystem');
ok($sys->foo == $foo,      'subsystem->foo and foo are identical');
is($sys->foo_id, $foo->id, 'ids match');

undef $foo;
is($sys->_foo, undef, 'our weak ref expires'); # glass box testing
is($sys->foo->id, $id, '...regotten subsystem->foo has the right id');

my $new_fid = $sys->foo->abs_id;
isnt($new_fid, $fid, '...but it is a new object');
is($sys->foo->abs_id, $new_fid, '...and we are not just regetting every time');

done_testing;
