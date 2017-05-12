#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use syntax gather => {
   -all => { -prefix => 'syntax_' }
};

use Syntax::Keyword::Gather -all => { -prefix => 'orig_' };

my @x = syntax_gather { syntax_take (1..4) };
my @y = orig_gather { orig_take (1..4) };

ok(eq_array(\@x, [1..4]), 'importing using sytax.pm works');
ok(eq_array(\@y, [1..4]), 'importing from the normal package works too!');

done_testing;

