use Test::More;

{

    package Foo;
    use MouseX::SingletonMethod;
    sub foo {'foo'}
}

my $foo1 = Foo->new;
my $foo2 = Foo->new;

$foo1->add_singleton_method( bar => sub {'bar'} );
$foo1->add_singleton_methods(
    baz => sub {'baz'},
    qux => sub {'qux'},
);

my $foo3 = Foo->new;

ok $foo1->can('foo');
is $foo1->foo, 'foo';
ok $foo1->can('bar');
is $foo1->bar, 'bar';
ok $foo1->can('baz');
is $foo1->baz, 'baz';
ok $foo1->can('qux');
is $foo1->qux, 'qux';

ok $foo2->can('foo');
is $foo2->foo, 'foo';
ok !$foo2->can('bar');
ok !$foo2->can('baz');
ok !$foo2->can('qux');

ok $foo3->can('foo');
is $foo3->foo, 'foo';
ok !$foo3->can('bar');
ok !$foo3->can('baz');
ok !$foo3->can('qux');

$foo3->become_singleton;
$foo3->meta->add_method( x => sub {'x'} );

ok $foo3->can('x');
is $foo3->x, 'x';
ok !$foo1->can('x');
ok !$foo2->can('x');

done_testing;
__END__
