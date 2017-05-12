#!/usr/bin/perl
use Test::More;
use Test::Moose;

use aliased 'MooseX::Meta::Method::Transactional';

{   package My::SchemaTest;
    use Moose;
    has name => (is => 'ro');
    sub txn_do {
        my $self = shift;
        my $code = shift;
        return 'txn_do'.$self->name.' '.$code->(@_);
    }
};

{   package Foo;
    use Moose;
    has schema => (is => 'ro');
    sub foo {
        my ($self, $data) = @_;
        return 'return1 '.$data;
    }
    sub bar {
        my ($self, $data) = @_;
        return 'return2 '.$data;
    }
};

my $schema1 = My::SchemaTest->new({ name => '1' });
my $schema2 = My::SchemaTest->new({ name => '2' });
my $foo = Foo->new({ schema => $schema1 });

my $meth_foo = Foo->meta->get_method('foo');
Transactional->meta->apply($meth_foo, rebless_params => {});

my $meth_bar = Foo->meta->get_method('bar');
Transactional->meta->apply($meth_bar, rebless_params => { schema => $schema2 });

is($meth_foo->schema->($foo), $schema1, 'schema object found...');
is($meth_bar->schema->($foo), $schema2, 'schema object got from trait even if object has a schema');

does_ok($meth_foo, Transactional, 'Reblessed instance...');
does_ok($meth_bar, Transactional, 'Reblessed instance...');

is($foo->foo('test'), 'txn_do1 return1 test', 'method invoked');
is($foo->bar('test'), 'txn_do2 return2 test', 'method invoked');

done_testing();
