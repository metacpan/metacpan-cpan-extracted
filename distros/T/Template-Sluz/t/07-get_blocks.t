#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Get blocks tests
# -------------------------------------------------------------------

{
	my @x = $sluz->_get_blocks('{$a}{$b}{$c}');
	is(scalar @x, 3, 'Get blocks #1 - Basic variables');
}

{
	my @x = $sluz->_get_blocks('{if $a}{$a}{/if}');
	is(scalar @x, 1, 'Get blocks #2 - Basic variables');
}

{
	my @x = $sluz->_get_blocks('Jason{$a}Baker{$b}');
	is(scalar @x, 4, 'Get blocks #3 - Basic variables');
}

{
	my @x = $sluz->_get_blocks('function(foo) { $i = 10; }');
	is(scalar @x, 1, 'Get blocks #4 - javascript function');
}

{
	my @x = $sluz->_get_blocks('{* Comment *}ABC{* Comment *}');
	is(scalar @x, 1, 'Get blocks #5 - Comments');
}

{
	my @x = $sluz->_get_blocks('   {$x}   ');
	is(scalar @x, 3, 'Get blocks #6 - Whitespace around variable');
}

{
	my @x = $sluz->_get_blocks('{foreach $arr as $i => $x}{if $x.1}{$x.1}{/if}{/foreach}');
	is(scalar @x, 1, 'Get blocks #7 - Lots of brackets');
}

{
	my @x = $sluz->_get_blocks('{*{$first}*}');
	is(scalar @x, 0, 'Get blocks #8 - Comment with variable');
}

{
	my @x = $sluz->_get_blocks('{*{$first} {$last}*}');
	is(scalar @x, 0, 'Get blocks #9 - Comments with variables');
}

{
	my @x = $sluz->_get_blocks(' {* {$foo} *} ');
	is(scalar @x, 2, 'Get blocks #10 - Comments with variables and whitespace');
}

{
	my @x = $sluz->_get_blocks('{foreach $array as $i}{foreach $array as $i}x{/foreach}{/foreach}');
	is(scalar @x, 1, 'Get blocks #11 - Nested foreach');
}

{
	my @x = $sluz->_get_blocks("{\$foo}\n{\$bar}");
	is(scalar @x, 3, 'Get blocks #12 - Only whitespace block');
}

{
	my @x = $sluz->_get_blocks("{\$foo}\n\n{\$bar}");
	is(scalar @x, 3, 'Get blocks #13 - Double whitespace block');
}

{
	my @x = $sluz->_get_blocks('');
	is(scalar @x, 0, 'Get blocks #14 - Empty string');
}

{
	my @x = $sluz->_get_blocks('plain text only');
	is(scalar @x, 1, 'Get blocks #15 - No template tags');
}

{
	my @x = $sluz->_get_blocks('{* {* {* {* deep *} *} *} *}');
	is(scalar @x, 0, 'Get blocks #16 - Deeply nested comment (4 levels)');
}

done_testing();
