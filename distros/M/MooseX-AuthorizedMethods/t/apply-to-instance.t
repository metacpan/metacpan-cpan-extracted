#!/usr/bin/perl
use Test::More;
use Test::Moose;

use aliased 'MooseX::Meta::Method::Authorized';
use aliased 'MooseX::Meta::Method::Authorized::CheckRoles';

{ package My::UserTest;
  use Moose;
  sub roles {
      return qw(foo bar baz);
  }
  sub id {
      return 'johndoe';
  }
};

{   package Foo;
    use Moose;
    has user => (is => 'ro');
    sub foo {
        my ($self, $data) = @_;
        return 'return '.$data;
    }
    sub bar {
        my ($self, $data) = @_;
        return 'return '.$data;
    }
};

my $user = My::UserTest->new;
my $foo = Foo->new({ user => $user });

my $meth = Foo->meta->get_method('foo');
Authorized->meta->apply($meth, rebless_params => { requires => ['foo'] });
my $meth_bar = Foo->meta->get_method('bar');
Authorized->meta->apply($meth_bar, rebless_params => { requires => ['gah'] });

isa_ok($meth->verifier, CheckRoles, 'verifier');
is_deeply($meth->requires, ['foo'], 'Contains the requires value...');

does_ok($meth, Authorized, 'Reblessed instance...');
is($foo->foo('test'), 'return test', 'method invoked');
eval {
    $foo->bar('test');
};
like($@.'', qr(Access Denied)i, 'died when not authorized');

done_testing();
