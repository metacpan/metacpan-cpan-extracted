#!/usr/bin/env perl
use warnings;
use strict;
use List2;

unshift @ARGV, '--noslurp';
List2->new->main("Try input 'aacbb': ");
