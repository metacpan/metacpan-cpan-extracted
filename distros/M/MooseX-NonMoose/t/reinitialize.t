#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    sub new { bless {}, shift }
}

{
    package Foo::Meta::Role;
    use Moose::Role;
}

{
    package Foo::Sub;
    use Moose;
    use MooseX::NonMoose;
    extends 'Foo';
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            class => ['Foo::Meta::Role'],
        },
    );
    ::is(::exception { __PACKAGE__->meta->make_immutable }, undef,
         "can make_immutable after reinitialization");
}

done_testing;
