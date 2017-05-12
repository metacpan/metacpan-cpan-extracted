#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

before_all "setup testing class" => sub {
    package Foo;
    use Mouse;
    with "Mite::Role::HasConfig";
};

tests "default config" => sub {
    my $obj1 = new_ok "Foo";
    my $obj2 = new_ok "Foo";

    isa_ok $obj1->config, "Mite::Config";

    is $obj1->config, $obj2->config, "config() is a singleton";    
};

done_testing;
