#!/usr/bin/env perl
use strict;

use Rubyish::Syntax::class;

class Cat {
    def sound { "meow" };
};

use Test::More;

plan tests => 3;

ok( Cat->can("new") );
is( Cat->sound, "meow" );

my $pet = Cat->new;
is( $pet->sound, "meow" );

