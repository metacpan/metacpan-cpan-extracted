#!/usr/bin/env perl
use warnings;
use strict;
use ListWithRefs2;

unshift @ARGV, '--noslurp';
ListWithRefs2->new->main("Try input 'ccdd': ");

