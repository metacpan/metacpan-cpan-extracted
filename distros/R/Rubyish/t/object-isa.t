#!/usr/bin/env perl
use strict;
use lib 't/lib';

use Test::More;
use Empty;

plan tests => 3;

{
    my $c = Empty->new;

    ok $c->is_a('Rubyish::Object'), "An object is a Rubyish::Object";

    ok !$c->is_a('Rubyish::Module'), "An object is not a Rubyish::Module";
    ok !$c->is_a('Rubyish::Class'), "An object is not a Rubyish::Class";
}

