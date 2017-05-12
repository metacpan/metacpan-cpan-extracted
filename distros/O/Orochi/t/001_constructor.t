use strict;
use lib "t/lib";
use Orochi::Test::Object1;
use Test::More;
use Test::MockObject;
use Orochi;

{
    my $c = Orochi->new();
    ok($c);

    $c->inject_constructor('/myapp/foo' => (class => 'Test::MockObject'));
    my $foo = $c->get('/myapp/foo');
    ok($foo);
    isa_ok($foo, 'Test::MockObject');
}

{
    my $c = Orochi->new();
    ok($c);

    $c->inject_constructor('/myapp/foo' => (
        class => 'Orochi::Test::Object1',
        args => { foo => 1, bar => 2 },
        deref_args => 1
    ));
    my $foo = $c->get('/myapp/foo');
    ok($foo);
    isa_ok($foo, 'Orochi::Test::Object1');
    is($foo->foo, 1);
    is($foo->bar, 2);
}

{
    my $c = Orochi->new();
    ok($c);

    $c->inject_literal('/myapp/foo/foo', 1);
    $c->inject_literal('/myapp/foo/bar', 2);

    $c->inject_constructor('/myapp/foo' => (
        class => 'Orochi::Test::Object1',
        args  => {
            foo => $c->bind_value( '/myapp/foo/foo' ),
            bar => $c->bind_value( '/myapp/foo/bar' ),
        },
        deref_args => 1,
    ));
    my $foo = $c->get('/myapp/foo');
    ok($foo);
    isa_ok($foo, 'Orochi::Test::Object1');
    is($foo->foo, 1);
    is($foo->bar, 2);
}

{
    my $c = Orochi->new();
    ok($c);

    $c->inject_literal('/myapp/bar/foo', 1);
    $c->inject_literal('/myapp/bar/bar', 2);
    $c->inject_literal('/myapp/foo/bar', 3);

    $c->inject_constructor('/myapp/bar' => (
        class => 'Orochi::Test::Object1',
        args  => {
            foo => $c->bind_value( '/myapp/bar/foo' ),
            bar => $c->bind_value( '/myapp/bar/bar' ),
        },
    ));

    $c->inject_constructor('/myapp/foo' => (
        class => 'Orochi::Test::Object1',
        args  => {
            foo => $c->bind_value( '/myapp/bar' ),
            bar => $c->bind_value( '/myapp/foo/bar' )
        },
        deref_args => 1,
    ));
    my $foo = $c->get('/myapp/foo');
    ok($foo);
    isa_ok($foo, 'Orochi::Test::Object1');
    isa_ok($foo->foo, 'Orochi::Test::Object1');
    is($foo->foo->foo, 1);
    is($foo->foo->bar, 2);
    is($foo->bar, 3);
}

{
    use Orochi::Declare;

    my $c = container {
        inject_literal '/myapp/bar/foo' => 1;
        inject_literal '/myapp/bar/bar' => 2;
        inject_literal '/myapp/foo/bar' => 3;

        inject_constructor '/myapp/bar' => (
            class => 'Orochi::Test::Object1',
            args  => {
                foo => bind_value '/myapp/bar/foo',
                bar => bind_value '/myapp/bar/bar',
            },
        );

        inject_constructor '/myapp/foo' => (
            class => 'Orochi::Test::Object1',
            args  => {
                foo => bind_value '/myapp/bar',
                bar => bind_value '/myapp/foo/bar',
            },
            deref_args => 1,
        );
    };
    ok($c);

    my $foo = $c->get('/myapp/foo');
    ok($foo);
    isa_ok($foo, 'Orochi::Test::Object1');
    isa_ok($foo->foo, 'Orochi::Test::Object1');
    is($foo->foo->foo, 1);
    is($foo->foo->bar, 2);
    is($foo->bar, 3);

    no Orochi::Declare;
}

done_testing;