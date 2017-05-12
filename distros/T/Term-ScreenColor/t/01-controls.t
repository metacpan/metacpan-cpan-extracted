#!/usr/bin/env perl
#
##########################################################################
#
# Name:         01-controls.t
# Version:      1.17
# Author:       Rene Uittenbogaard
# Date:         2010-09-20
# Requires:     Term::ScreenColor
# Description:  Tests for control methods in Term::ScreenColor
#

##########################################################################
# declarations

use strict;
use Test::More tests => 19;

my ($scr);

require_ok('Term::ScreenColor');

##########################################################################
# test instantiation

sub init {
	$ENV{TERM} = 'xterm';
	open NULL, ">/dev/null";
	# intercept STDOUT as this interferes with test output
	{
		local *STDOUT = *NULL;
		$scr = new Term::ScreenColor();
		system "stty cooked echo"; # nicer output on terminal
	}
	isa_ok($scr, "Term::ScreenColor"  );
	isa_ok($scr, "Term::Screen::Fixes");
	isa_ok($scr, "Term::Screen"       );
	return $scr;
}

##########################################################################
# test Term::Screen::Fixes

sub main {
	ok($scr->raw()              , 'call raw()');
	ok($scr->cooked()           , 'call cooked()');
	ok($scr->rows()        > 0  , 'call rows()');
	ok($scr->cols()        > 0  , 'call cols()');
	ok($scr->timeout()    == 0.4, 'get timeout');
	ok($scr->timeout(0.5) == 0.5, 'set timeout');
	ok($scr->get_more_fn_keys() , 'parse termcap-specific function keys');

	$scr->noecho();
	$scr->stuff_input('a');
	ok($scr->flush_input()      , 'call flush_input()');
	$scr->stuff_input('b');
	ok($scr->getch() eq 'b'     , 'get simple character with getch()');
	$scr->stuff_input("\e[15~");
	ok($scr->getch() eq 'k5'    , 'get function key with getch()');

	$scr->flush_input();
	$scr->stuff_input("f\e\eg");
	$scr->getch(); # discard 'f'
	ok($scr->getch() eq "\e"    , 'get double escape with getch()');
	ok($scr->getch() eq "\e"    , 'get double escape with getch()');

	$scr->flush_input();
	$scr->stuff_input("a\e[15b");
	$scr->getch(); # discard 'a'
	ok($scr->getch() eq "\e"    , 'get partial function escape with getch()');
	ok($scr->getch() eq "["     , 'get partial function escape with getch()');
	ok($scr->getch() eq "1"     , 'get partial function escape with getch()');
	$scr->flush_input();

	$scr->echo();
}

##########################################################################
# main

$scr = init();
main($scr);

__END__

