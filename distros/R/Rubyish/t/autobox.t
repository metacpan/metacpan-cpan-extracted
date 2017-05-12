#!/usr/bin/env perl

use strict;
use Rubyish;

use Test::More;

plan tests => 5;

{
    my $a = [qw(a b c)];

    is $a->size, 3;
    is $a->join, "abc";
    is $a->inspect, '["a", "b", "c"]';

    is_deeply $a->clear, [];
    is_deeply $a, [];

    # local $TODO = "is_a isn't working good with autobox. \$a is still unblessed.";
    # ok $a->is_a("Rubyish::Array");

    # This one gives you ARRAY because of the same reason.
    # is $a->class, "Rubyish::Array";
}
