#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Example { }

is( Example->META->name, "Example", 'META->name' );

done_testing;
