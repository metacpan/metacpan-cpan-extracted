#!/usr/bin/perl

# Test the protect method

BEGIN 
{
    @crap = 
	(
	 "\x1bAll",
	 "yo\x1bur",
	 "bas\x1be",
	 "are\x1b",
	 "belong",
	 "to\x1b",
	 "\x1bus",
	 );
};

use Test::More tests => scalar @crap;
use Safe::Logs qw(protect);

my @safe = protect @crap;

is($safe[0], '[esc]All');
is($safe[1], 'yo[esc]ur');
is($safe[2], 'bas[esc]e');
is($safe[3], 'are[esc]');
is($safe[4], 'belong');
is($safe[5], 'to[esc]');
is($safe[6], '[esc]us');


