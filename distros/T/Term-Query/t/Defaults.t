#!/usr/local/bin/perl

unshift(@INC, '.', '..');
require 'Query_Test.pl';

$Class = 'Defaults';

print "1..2\n";

$aVar = 'wrong';
&query_test( $Class, 1, '', 
	['Setup aVar','rdIV', 'right', "\n", 'aVar'],
	'$\'aVar eq "right"');

$aVar = 'bad stuff';
&query_test( $Class, 2, '',
	['Setup aVar','rdIV', 'right', "\n", \$aVar],
	'$aVar eq "right"');

1;
