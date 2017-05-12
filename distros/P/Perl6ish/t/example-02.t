#!/usr/bin/env perl -w
use strict;
use Test::More tests => 2;

use Perl6ish;
use Perl6ish::Autobox;

my %hash = ( foo => 1);

is perl(\%hash), '{"foo" => 1}';

my $things = [1, 2, 'q'];

is $things->perl, '[1,2,"q"]';
