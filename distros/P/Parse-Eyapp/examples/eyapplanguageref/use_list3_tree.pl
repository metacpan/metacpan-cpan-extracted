#!/usr/bin/env perl
use warnings;
use strict;
use List3_tree;

unshift @ARGV, '--noslurp';
List3_tree->new->main("Try input 'ccdd': ");
