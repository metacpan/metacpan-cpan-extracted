#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest class => sub{
    package ClassTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class => 'ClassTest::Foo' );
    sub test { 'ClassTest' }

    package ClassTest::Foo; use Moo;
    sub test { 'ClassTest::Foo' }

    package ClassTest::FooPlugin; use Moo::Role;
    use MooX::PluginKit::Plugin;
    plugin_applies_to 'ClassTest::Foo';
    around test => sub{ my($o,$s)=@_; return('ClassTest::FooPlugin', $s->$o()) };

    package main;

    my $consumer = ClassTest->new( plugins=>['::FooPlugin'], foo=>{} );
    my $foo = $consumer->foo();

    is(
        [ $consumer->test() ],
        [qw( ClassTest )],
    );
    is(
        [ $foo->test() ],
        [qw( ClassTest::FooPlugin ClassTest::Foo )],
    );
};

subtest default_class_arg => sub{
    package DefaultClassArgTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class_arg=>1 );

    package DefaultClassArgTest::Foo; use Moo;

    package main;
    my $consumer = DefaultClassArgTest->new( foo=>{ class=>'DefaultClassArgTest::Foo' } );
    isa_ok( $consumer->foo(), 'DefaultClassArgTest::Foo' );
};

subtest custom_class_arg => sub{
    package CustomClassArgTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class_arg=>'foo_class' );

    package CustomClassArgTest::Foo; use Moo;

    package main;
    my $consumer = CustomClassArgTest->new( foo=>{ foo_class=>'CustomClassArgTest::Foo' } );
    isa_ok( $consumer->foo(), 'CustomClassArgTest::Foo' );
};

subtest default_class_builder => sub{
    package DefaultClassBuilderTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class_builder=>1 );
    sub _foo_build_class { 'DefaultClassBuilderTest::Foo' }

    package DefaultClassBuilderTest::Foo; use Moo;

    package main;
    my $consumer = DefaultClassBuilderTest->new( foo=>{} );
    isa_ok( $consumer->foo(), 'DefaultClassBuilderTest::Foo' );
    can_ok( 'DefaultClassBuilderTest', '_foo_build_class' );
};

subtest custom_class_builder => sub{
    package CustomClassBuilderTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class_builder=>'_foo_custom' );
    sub _foo_custom { 'CustomClassBuilderTest::Foo' }

    package CustomClassBuilderTest::Foo; use Moo;

    package main;
    my $consumer = CustomClassBuilderTest->new( foo=>{} );
    isa_ok( $consumer->foo(), 'CustomClassBuilderTest::Foo' );
};

subtest code_class_builder => sub{
    package CodeClassBuilderTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class_builder=>sub{'CodeClassBuilderTest::Foo'} );
    sub _foo_custom { 'CodeClassBuilderTest::Foo' }

    package CodeClassBuilderTest::Foo; use Moo;

    package main;
    my $consumer = CodeClassBuilderTest->new( foo=>{} );
    isa_ok( $consumer->foo(), 'CodeClassBuilderTest::Foo' );
    can_ok( 'DefaultClassBuilderTest', '_foo_build_class' );
};

subtest default_args_builder => sub{
    package DefaultArgsBuilderTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class=>'DefaultArgsBuilderTest::Foo', args_builder=>1 );
    sub _foo_build_args { return { %{$_[1]}, bar=>2 } }

    package DefaultArgsBuilderTest::Foo; use Moo;
    has bar => (is=>'ro');

    package main;
    my $consumer = DefaultArgsBuilderTest->new( foo=>{} );
    isa_ok( $consumer->foo(), 'DefaultArgsBuilderTest::Foo' );
    is( $consumer->foo->bar(), 2 );
};

subtest custom_args_builder => sub{
    package CustomArgsBuilderTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class=>'CustomArgsBuilderTest::Foo', args_builder=>'_foo_custom' );
    sub _foo_custom { return { %{$_[1]}, bar=>3 } }

    package CustomArgsBuilderTest::Foo; use Moo;
    has bar => (is=>'ro');

    package main;
    my $consumer = CustomArgsBuilderTest->new( foo=>{} );
    isa_ok( $consumer->foo(), 'CustomArgsBuilderTest::Foo' );
    is( $consumer->foo->bar(), 3 );
};

subtest code_args_builder => sub{
    package CodeArgsBuilderTest; use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object foo => ( class=>'CodeArgsBuilderTest::Foo', args_builder=>sub{return { %{$_[1]}, bar=>4 }} );

    package CodeArgsBuilderTest::Foo; use Moo;
    has bar => (is=>'ro');

    package main;
    my $consumer = CodeArgsBuilderTest->new( foo=>{} );
    isa_ok( $consumer->foo(), 'CodeArgsBuilderTest::Foo' );
    is( $consumer->foo->bar(), 4 );
    can_ok( 'CodeArgsBuilderTest', '_foo_build_args' );
};

done_testing;
