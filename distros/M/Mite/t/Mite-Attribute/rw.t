#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Attribute;

after_case "Create a class to test with" => sub {
    package Foo;

    sub new {
        my $class = shift;
        bless { @_ }, $class
    }

    eval Mite::Attribute->new(
        name    => 'name',
        is      => 'rw',
    )->compile; die $@ if $@;

    eval Mite::Attribute->new(
        name    => 'job',
        is      => 'rw',
    )->compile; die $@ if $@;
};

tests "try various tricky values" => sub {
    my $obj = Foo->new(
        name    => "Yarrow Hock"
    );

    is $obj->name, "Yarrow Hock", "attribute from new";
    is $obj->job,  undef,         "attribute not defined in new";

    $obj->job("Flower child");
    is $obj->job, "Flower child", "set attribute";

    $obj->name("Foo Bar");
    is $obj->name, "Foo Bar",     "change attribute";

    $obj->name(undef);
    is $obj->name, undef,         "set to undef";

    $obj->name(0);
    is $obj->name, 0,             "set to 0";

    $obj->name("");
    is $obj->name, "",            "set to empty string";
};

done_testing;
