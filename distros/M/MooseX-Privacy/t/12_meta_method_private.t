use strict;
use warnings;
use Test::More;

use Moose::Meta::Class;
use MooseX::Privacy::Meta::Method::Private;

my $metaclass = Moose::Meta::Class->create('Foo');

ok my $private_method = MooseX::Privacy::Meta::Method::Private->wrap(
    name         => 'foo',
    package_name => 'Foo',
    body         => sub { return 23 }
    ),
    'create Method::Private method';

isa_ok $private_method, 'MooseX::Privacy::Meta::Method::Private';
eval { $private_method->execute };
like $@, qr/The Foo::foo method is private/,
    "can't execute private method in main package";

{

    package Foo;
    use Moose;
    use MooseX::Privacy;
    sub baz { return $_[0]->foo + $_[0]->bar }
}

my $object = Foo->new();
ok $object->meta->add_private_method( 'foo', $private_method ),
    'add_private_method accept a Method::Private instance';
ok $object->meta->add_private_method( 'bar', sub { return 42 } ),
    'add_private_method create a new Method::Private instance';
is scalar @{ $object->meta->local_private_methods }, 2,
    'got two private methods';

is $object->baz, 65, 'everything works fine';

done_testing;



