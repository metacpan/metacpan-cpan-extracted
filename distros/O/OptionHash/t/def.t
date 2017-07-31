#!/usr/bin/perl

use strict;
use warnings;
use OptionHash;
use Test::Simple tests => 1;

my $def = ohash_define( keys => [ qw< fish cats monkeys > ]);
ok( ref($def) eq 'OptionHash', 'Get an option hash definition');
