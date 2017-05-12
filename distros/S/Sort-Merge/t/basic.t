#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 2;

BEGIN {use_ok 'Sort::Merge';}
ok('Sort::Merge'->can('sort_coderefs'), 'Sort::Merge can sort_coderefs');

