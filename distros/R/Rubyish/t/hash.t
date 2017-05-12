#!/usr/bin/env perl

use strict;

use lib 't/lib';

use Rubyish;

use Test::More;
plan tests => 1;

my $hash = Hash({ hello => "world" });

is $hash->fetch("hello"), "world";
