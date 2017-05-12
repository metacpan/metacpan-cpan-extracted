#!/usr/bin/env perl
use warnings;
use strict;
use CsBetweenCommansAndD;

unshift @ARGV, '--noslurp';
CsBetweenCommansAndD->new->main("Try input 'c,c,c d': ");
