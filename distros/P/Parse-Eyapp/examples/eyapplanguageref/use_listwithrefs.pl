#!/usr/bin/env perl
use warnings;
use strict;
use ListWithRefs;

unshift @ARGV, '--noslurp';
ListWithRefs->new->main("Try input 'ccdd': ");
