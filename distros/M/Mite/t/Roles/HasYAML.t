#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

before_all "Setup class for testing" => sub {
    package Foo;
    use Mouse;
    with 'Mite::Role::HasYAML';
};

tests "->yaml" => sub {
    my $obj = new_ok "Foo";

    # Round trip
    my $data = { foo => 23, bar => [1,2,3], baz => "0123" };
    my $yaml = $obj->yaml_dump($data);
    note $yaml;
    my $loaded_data = $obj->yaml_load($yaml);

    cmp_deeply( $loaded_data, $data );
    cmp_ok $loaded_data->{baz}, 'eq', "0123", "strings with leading zeros are preserved";
};

done_testing;
