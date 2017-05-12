#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

use Sub::AliasedUnderscore qw/transform transformed/;

my $increment = sub { $_++ };
$increment = transform $increment;

$_ = 1; 

my $a = 41;
is $increment->($a), 41, '41++ == 41';
is $a, 42, 'a incremented';
is $_, 1, '$_ untouched';

my $decrement = transformed { $_-- };
is $decrement->($a), 42, '42-- == 42';
is $a, 41, 'a decremented';
is $_, 1, '$_ untouched';
