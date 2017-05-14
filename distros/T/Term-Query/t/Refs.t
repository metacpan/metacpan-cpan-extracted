#!/usr/local/bin/perl

unshift(@INC, '.', '..');
require 'Query_Test.pl';

$Class = 'Refs';

@keywords = qw(SGI HP Sun DEC IBM);
@fields = qw(Index Title Vendor);

print "1..4\n";

$foo = $fields[0];		# this should fail
&query_test(  $Class, 1, '', 
	['Ignored prompt', 'rKIV', \@fields, \$foo, 'bar'] );

$foo = 'Good stuff';
$bar = 'Bad stuff';
&query_test(  $Class, 2, '', 
	['Ignored prompt', 'rKIV', \@fields, \$foo, 'bar'],
	'$bar eq "Good stuff"' );

$foo = 'Good stuff';
$bar = 'Bad Stuff';
&query_test(  $Class, 3, '', 
	['Ignored prompt', 'rKIV', \@fields, \$foo, \$bar],
	'$bar eq "Good stuff"' );

$ans = 'Bad news';
&query_test(  $Class, 4, "", 
	["Do you wish to quit?", 'NV', \$ans],
	'$ans =~ /no/' );

1;
