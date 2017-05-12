#!/usr/bin/perl
use warnings;
use strict;
use Test::More  tests=>3;
use Sort::Merge;

Sort::Merge::sort_coderefs([], sub{fail('No inputs')});
pass('No inputs');

my $foo1='output coderef not called';
Sort::Merge::sort_coderefs([sub{return}], 
						   sub{$foo1='output coderef was called'});
is($foo1, 'output coderef not called', '1 input, which dries up immediately');

Sort::Merge::sort_coderefs([(sub{return})x2], 
						   sub{fail('2 inputs, which dries up immediately')});
pass('2 inputs, which dry up immediately');
