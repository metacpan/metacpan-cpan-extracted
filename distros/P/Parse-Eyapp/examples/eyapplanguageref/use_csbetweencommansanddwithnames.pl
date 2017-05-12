#!/usr/bin/env perl
use warnings;
use strict;
use CsBetweenCommansAndDWithNames;

unshift @ARGV, '--noslurp';
CsBetweenCommansAndDWithNames->new->main("Try input 'c,c,cd': ");
