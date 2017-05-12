#!/usr/bin/env perl

use strict;
use lib 't/lib';

use Cat;
use Test::More;

plan tests => 5;

my $pet = Cat->new;
$pet->name("oreo");

like $pet->sound, qr/meow/;
is $pet->name, "oreo";
is $pet->class, 'Cat', "->class";
is $pet->superclass, 'Animal', "->superclass";

like $pet->play('ball'), qr/ball is funny/, "play() defined with proto.";
