#!/usr/bin/env perl

use strict;

use lib 't/lib';

use Rubyish;

use Test::More;
plan tests => 5;

{
    my $array = Array[0..3];
    ok $array->any(sub { my ($i) = @_; $i > 2; });
    ok !$array->all(sub { my ($i) = @_; $i > 2; });

    ok !$array->any(sub { my ($i) = @_; $i > 500; });
}

{
    my $a = Array['q', 0, 'fz0', 3];

    ok !$a->all;
    ok $a->any;
}
