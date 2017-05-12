use strict;
use warnings;
use Test::More;

use Moose::Meta::Class;
use MooseX::Privacy::Meta::Method::Protected;

my $metaclass = Moose::Meta::Class->create('Foo');

ok my $protected_method = MooseX::Privacy::Meta::Method::Protected->wrap(
    name         => 'foo',
    package_name => 'Foo',
    body         => sub { return 23 }
    ),
    'create Method::Protected method';

isa_ok $protected_method, 'MooseX::Privacy::Meta::Method::Protected';
eval { $protected_method->execute };
like $@, qr/The Foo::foo method is protected/,
    "can't execute a protected method in main package";

{

    package Foo;
    use Moose;
    use MooseX::Privacy;

    package Bar;
    use Moose;
    extends qw/Foo/;
    sub baz { return $_[0]->foo + $_[0]->bar }
}

my $foo_object = Foo->new;
ok $foo_object->meta->add_protected_method( 'foo', $protected_method ),
    'add_protected_method accept a Method::Protected instance';
ok $foo_object->meta->add_protected_method( 'bar', sub { return 42 } ),
    'add_protected_method create a new Method::Protected instance';
is scalar @{ $foo_object->meta->local_protected_methods }, 2,
    'got two protected methods';

my $bar_object = Bar->new;
is $bar_object->baz, 65, 'everything works fine';

done_testing;
