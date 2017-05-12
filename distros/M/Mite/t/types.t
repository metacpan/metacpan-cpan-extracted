#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Path::Tiny;

tests "Path" => sub {
    {
        package Foo;
        use Mouse;
        use Mite::Types;

        has file =>
          is    => 'rw',
          isa   => 'Path',
          coerce => 1;
    }

    my $obj = new_ok 'Foo';
    $obj->file("/foo/bar");
    isa_ok $obj->file, "Path::Tiny";
    is $obj->file, "/foo/bar";

    $obj->file( path("woof") );
    isa_ok $obj->file, "Path::Tiny";
    is $obj->file, "woof";
};


tests "AbsPath" => sub {
    {
        package Foo;
        use Mouse;
        use Mite::Types;

        has file =>
          is    => 'rw',
          isa   => 'AbsPath',
          coerce => 1;
    }

    my $obj = new_ok 'Foo';
    $obj->file("/foo/bar");
    isa_ok $obj->file, "Path::Tiny";
    is $obj->file, "/foo/bar";

    $obj->file( path("woof") );
    isa_ok $obj->file, "Path::Tiny";
    is $obj->file, path("woof")->absolute;

    $obj->file( path("woof")->absolute );
    isa_ok $obj->file, "Path::Tiny";
    is $obj->file, path("woof")->absolute;
};


done_testing;
