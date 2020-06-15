#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class One {
   has $value;

   method BUILD { $value = 1 }

   method value { $value }
}

is( One->new->value, 1, 'method BUILD worked' );

done_testing;
