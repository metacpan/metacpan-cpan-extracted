#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use ok "MooseX::Role::TraitConstructor";

{
    package Foo;
    use Moose;

    with qw(MooseX::Role::TraitConstructor);


    package Foo::Bar;
    use Moose::Role;

    sub bar { }


    package Foo::Gorch;
    use Moose::Role;

    sub gorch { } 


    package Some::Role;
    use Moose::Role;

    sub laa { }


    package Some::Class;
    use Moose;

    sub oink { }
}

is( Foo->guess_original_class_name, "Foo", "guess_original_class_name" );

is( Moose::Meta::Class->create_anon_class( superclasses => [ "Foo" ] )->name->guess_original_class_name, "Foo", "guess_original_class_name" );

is( Foo->resolve_constructor_trait( { }, "Foo", "Bar" ), "Foo::Bar", "resolve_constructor_trait" );

is_deeply( [ Foo->resolve_constructor_traits( {}, qw(Bar Gorch) ) ], [ qw(Foo::Bar Foo::Gorch) ], "resolve_constructor_traits" );;

is_deeply( [ Foo->filter_constructor_traits( {}, qw(Foo::Bar Foo::Gorch) ) ], [ qw(Foo::Bar Foo::Gorch) ], "filter_constructor_traits" );
is_deeply( [ Moose::Meta::Class->create_anon_class( superclasses => [ "Foo" ], roles => [ "Foo::Bar" ] )->name->filter_constructor_traits( {}, qw(Foo::Bar Foo::Gorch) ) ], [ qw(Foo::Gorch) ], "filter_constructor_traits" );

{
    my $foo = Foo->new_with_traits( traits => [qw(Bar) ]);

    isa_ok( $foo, "Foo" );
    ok( $foo->does("Foo::Bar"), "does Foo::Bar" );;
    ok( !$foo->does("Foo::Gorch"), "not Foo::Gorch" );
}

{
    my $foo = Foo->new_with_traits( traits => [qw(Some::Role) ]);

    isa_ok( $foo, "Foo" );
    ok( $foo->does("Some::Role"), "does Some::Role" );
}

throws_ok { Foo->new_with_traits( traits => [qw(Does::Not::Exist)] ) } qr/load.*Does::Not::Exist/i, "nonexistent trait";

throws_ok { Foo->new_with_traits( traits => [qw(Some::Class)] ) } qr/not a moose role/i, "not a trait";

