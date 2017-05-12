#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 5;

use Syntax::Construct ();

is(Syntax::Construct::introduced('//'), '5.010', 'introduced-arg');

my @introduced = Syntax::Construct::introduced();
is(@introduced, 59, 'introduced all');

is(Syntax::Construct::removed('auto-deref'), '5.024', 'removed-arg');
is(Syntax::Construct::removed(), 3, 'removed all');

is( Syntax::Construct::introduced('s-utf8-delimiters-hack'),
    undef, 'old not introduced');
