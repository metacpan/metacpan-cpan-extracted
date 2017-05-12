#!/usr/bin/env perl
use warnings;
use strict;
use List3;

unshift @ARGV, '--noslurp';
List3->new->main("Try input 'ccdd': ");
