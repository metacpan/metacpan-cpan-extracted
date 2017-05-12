#!/usr/bin/env perl
use warnings;
use strict;
use ListWithRefs1;

unshift @ARGV, '--noslurp';
ListWithRefs1->new->main("Try input 'ccdd': ");
