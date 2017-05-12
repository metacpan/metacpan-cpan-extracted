#!/usr/bin/env perl 
use warnings;
use strict;
use intermediateaction2;

unshift @ARGV, '--noslurp';
my $parser = intermediateaction2->new;
$parser->main("try input 'aa': ");
