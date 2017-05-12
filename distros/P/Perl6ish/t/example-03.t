#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Perl6ish;

my @foo = (1..20);
my $foo = @foo;

is $foo, \@foo;



