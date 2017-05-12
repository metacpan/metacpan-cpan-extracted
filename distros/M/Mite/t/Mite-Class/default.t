#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Path::Tiny;
use Mite::Attribute;

after_case "Create a class to test with"=> sub {
    my $class = sim_class(
        name            => 'Foo',
    );

    $class->add_attributes(
        Mite::Attribute->new(
            name    => 'name',
            is      => 'ro',
            default => "Yarrow Hock",
        ),
        Mite::Attribute->new(
            name    => 'howmany',
            is      => 'rw',
            default => 0,
        ),
    );

    eval $class->compile or die $@;
};

tests "Defaults" => sub {
    my $obj = new_ok "Foo";
    is $obj->name, "Yarrow Hock";
    is $obj->howmany, 0;
};

done_testing;
