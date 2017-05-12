#!/usr/bin/perl

use strict;
use warnings;

my $Have_Threads;
BEGIN {
    $Have_Threads = eval { require threads };
    require Test::More;
    Test::More->import;
}

plan skip_all => "Needs threads" unless $Have_Threads;

{
    package Foo;
    use Object::ID;
    sub new {
        my $class = shift;
        bless {}, $class;
    }
}

TODO: for my $method (qw(object_id object_uuid)) {
    note "*** Trying $method ***";
    todo_skip "uuid known to be thread hostile", 5 if $method eq 'object_uuid';

    my $obj = new_ok "Foo";
    my $id = $obj->$method;

    for(1..5) {
        threads->create(sub {
            is $obj->$method, $id, "$method in a thread";
        });
    }

    note "threads started";

    $_->join for threads->list;

    note "threads joined";
}

done_testing();
