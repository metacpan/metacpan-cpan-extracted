#!/usr/bin/perl -w

use lib 't/lib';
use Test::Mite;

after_case "Setup classes" => sub {
    package Foo;
    use Mouse;
    with 'Mite::Role::HasDefault';

    package Bar;
    use Mouse;
    with 'Mite::Role::HasDefault';
};

tests "Get/set the default" => sub {
    my $default = Foo->default;
    isa_ok $default, "Foo";

    is( Foo->default, $default );
    isnt( Foo->new, $default );

    my $new_default = new_ok "Foo";
    Foo->set_default($new_default);
    is( Foo->default, $new_default, "changed default" );
};

tests "Multiple classes with defaults" => sub {
    my $foo = Foo->default;
    my $bar = Bar->default;

    isa_ok $foo, "Foo";
    isa_ok $bar, "Bar";

    my $new_bar = new_ok 'Bar';
    Bar->set_default( $new_bar );

    is( Bar->default, $new_bar );
    is( Foo->default, $foo );
};

done_testing;
