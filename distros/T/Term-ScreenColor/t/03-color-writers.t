#!/usr/bin/env perl
#
##########################################################################
#
# Name:         03-color-writers.t
# Version:      1.20
# Author:       Rene Uittenbogaard
# Date:         2010-10-04
# Requires:     Term::ScreenColor
# Description:  Tests for color printing methods in Term::ScreenColor
#

##########################################################################
# declarations

use strict;

my $teststring = 'zwerk';

my %NORMALS = (
	"\e[m\n"      => 1,
	"\e[0m\n"     => 1,
	"\e[m\cO\n"   => 1,
	"\e[0m\cO\n"  => 1,
	"\e(B\e[m\n"  => 1,
	"\e(B\e[0m\n" => 1,
);

my %FLASHES = (
	"\e[?5h\e[?5l\n" => 1,
	"\n"             => 1,
);

##########################################################################
# main: setup pipe

sub main {
	my $childpid = open(HANDLE, "-|");
	die "cannot fork(): $!" unless defined $childpid;
	if ($childpid) {
		# parent
		test_output();
	} else {
		# child
		produce_output();
	}
}

##########################################################################
# child process: perform tests

sub produce_output {
	require Term::ScreenColor;
	my ($scr, $colorizable);
	$ENV{TERM} = 'xterm';

	$scr = new Term::ScreenColor();
	$scr->cooked()->puts("\n"); # put newline after at(0,0)

	# add newlines after every escape because we will use the <FH>
	# operator to read lines from the pipe
	for $colorizable (0 .. 1) {
		$scr->colorizable($colorizable);

		# simple termcap, direct
		$scr->bold()		->puts("\n");
		$scr->underline()	->puts("\n");
		$scr->reverse()		->puts("\n");

		# simple ansi, direct
		$scr->clear()		->puts("\n");
		$scr->reset()		->puts("\n");
		$scr->ansibold()	->puts("\n");
		$scr->italic()		->puts("\n");
		$scr->underscore()	->puts("\n");
		$scr->blink()		->puts("\n");
		$scr->inverse()		->puts("\n");
		$scr->concealed()	->puts("\n");

		$scr->noansibold()	->puts("\n");
		$scr->noitalic()	->puts("\n");
		$scr->nounderscore()	->puts("\n");
		$scr->noblink()		->puts("\n");
		$scr->noinverse()	->puts("\n");
		$scr->noconcealed()	->puts("\n");

		# simple termcap, fetch
		$scr->putcolor('bold'		)->puts("\n");
		$scr->putcolor('underline'	)->puts("\n");
		$scr->putcolor('reverse'	)->puts("\n");

		# simple ansi, fetch
		$scr->putcolor('reset'		)->puts("\n");
		$scr->putcolor('ansibold'	)->puts("\n");
		$scr->putcolor('italic'		)->puts("\n");
		$scr->putcolor('underscore'	)->puts("\n");
		$scr->putcolor('blink'		)->puts("\n");
		$scr->putcolor('inverse'	)->puts("\n");
		$scr->putcolor('concealed'	)->puts("\n");

		$scr->putcolor('noansibold'	)->puts("\n");
		$scr->putcolor('noitalic'	)->puts("\n");
		$scr->putcolor('nounderscore'	)->puts("\n");
		$scr->putcolor('noblink'	)->puts("\n");
		$scr->putcolor('noinverse'	)->puts("\n");
		$scr->putcolor('noconcealed'	)->puts("\n");

		# simple termcap, apply
		$scr->putcolored('bold',	$teststring)->puts("\n");
		$scr->putcolored('underline',	$teststring)->puts("\n");
		$scr->putcolored('reverse',	$teststring)->puts("\n");

		# simple ansi, apply
		$scr->putcolored('reset',	$teststring)->puts("\n");
		$scr->putcolored('ansibold',	$teststring)->puts("\n");
		$scr->putcolored('italic',	$teststring)->puts("\n");
		$scr->putcolored('underscore',	$teststring)->puts("\n");
		$scr->putcolored('blink',	$teststring)->puts("\n");
		$scr->putcolored('inverse',	$teststring)->puts("\n");
		$scr->putcolored('concealed',	$teststring)->puts("\n");

		$scr->putcolored('noansibold',	$teststring)->puts("\n");
		$scr->putcolored('noitalic',	$teststring)->puts("\n");
		$scr->putcolored('nounderscore',$teststring)->puts("\n");
		$scr->putcolored('noblink',	$teststring)->puts("\n");
		$scr->putcolored('noinverse',	$teststring)->puts("\n");
		$scr->putcolored('noconcealed',	$teststring)->puts("\n");

		# simple ansi color, direct
		$scr->black()		->puts("\n");
		$scr->red()		->puts("\n");
		$scr->green()		->puts("\n");
		$scr->yellow()		->puts("\n");
		$scr->blue()		->puts("\n");
		$scr->magenta()		->puts("\n");
		$scr->cyan()		->puts("\n");
		$scr->white()		->puts("\n");

		$scr->on_black()	->puts("\n");
		$scr->on_red()		->puts("\n");
		$scr->on_green()	->puts("\n");
		$scr->on_yellow()	->puts("\n");
		$scr->on_blue()		->puts("\n");
		$scr->on_magenta()	->puts("\n");
		$scr->on_cyan()		->puts("\n");
		$scr->on_white()	->puts("\n");

		# simple ansi color, fetch
		$scr->putcolor('black'		)->puts("\n");
		$scr->putcolor('red'		)->puts("\n");
		$scr->putcolor('green'		)->puts("\n");
		$scr->putcolor('yellow'		)->puts("\n");
		$scr->putcolor('blue'		)->puts("\n");
		$scr->putcolor('magenta'	)->puts("\n");
		$scr->putcolor('cyan'		)->puts("\n");
		$scr->putcolor('white'		)->puts("\n");

		$scr->putcolor('on_black'	)->puts("\n");
		$scr->putcolor('on_red'		)->puts("\n");
		$scr->putcolor('on_green'	)->puts("\n");
		$scr->putcolor('on_yellow'	)->puts("\n");
		$scr->putcolor('on_blue'	)->puts("\n");
		$scr->putcolor('on_magenta'	)->puts("\n");
		$scr->putcolor('on_cyan'	)->puts("\n");
		$scr->putcolor('on_white'	)->puts("\n");

		# simple ansi color, apply
		$scr->putcolored('black',	$teststring)->puts("\n");
		$scr->putcolored('red',		$teststring)->puts("\n");
		$scr->putcolored('green',	$teststring)->puts("\n");
		$scr->putcolored('yellow',	$teststring)->puts("\n");
		$scr->putcolored('blue',	$teststring)->puts("\n");
		$scr->putcolored('magenta',	$teststring)->puts("\n");
		$scr->putcolored('cyan',	$teststring)->puts("\n");
		$scr->putcolored('white',	$teststring)->puts("\n");

		$scr->putcolored('on_black',	$teststring)->puts("\n");
		$scr->putcolored('on_red',	$teststring)->puts("\n");
		$scr->putcolored('on_green',	$teststring)->puts("\n");
		$scr->putcolored('on_yellow',	$teststring)->puts("\n");
		$scr->putcolored('on_blue',	$teststring)->puts("\n");
		$scr->putcolored('on_magenta',	$teststring)->puts("\n");
		$scr->putcolored('on_cyan',	$teststring)->puts("\n");
		$scr->putcolored('on_white',	$teststring)->puts("\n");

		# complex ansi color, fetch
		$scr->putcolor('33;41'		)->puts("\n");
		$scr->putcolor('ansibold yellow')->puts("\n");
		$scr->putcolor('ansibold on red')->puts("\n");
		$scr->putcolor('cyan on black'	)->puts("\n");
		$scr->putcolor('white on cyan'	)->puts("\n");
		$scr->putcolor('green on yellow')->puts("\n");
		$scr->putcolor('magenta inverse')->puts("\n");
		$scr->putcolor('on_red blink'	)->puts("\n");
		$scr->putcolor('yellow on blue'	)->puts("\n");
		$scr->putcolor('red underscore'	)->puts("\n");

		# complex ansi color, apply
		$scr->putcolored('33;41',           $teststring)->puts("\n");
		$scr->putcolored('ansibold yellow', $teststring)->puts("\n");
		$scr->putcolored('ansibold on red', $teststring)->puts("\n");
		$scr->putcolored('cyan on black',   $teststring)->puts("\n");
		$scr->putcolored('white on cyan',   $teststring)->puts("\n");
		$scr->putcolored('green on yellow', $teststring)->puts("\n");
		$scr->putcolored('magenta inverse', $teststring)->puts("\n");
		$scr->putcolored('on_red blink',    $teststring)->puts("\n");
		$scr->putcolored('yellow on blue',  $teststring)->puts("\n");
		$scr->putcolored('red underscore',  $teststring)->puts("\n");

		# termcap/ansi combination, fetch
		$scr->putcolor('bold yellow    ')->puts("\n");
		$scr->putcolor('bold on red    ')->puts("\n");
		$scr->putcolor('magenta reverse')->puts("\n");
		$scr->putcolor('red underline  ')->puts("\n");

		# termcap/ansi combination, apply
		$scr->putcolored('bold yellow    ', $teststring)->puts("\n");
		$scr->putcolored('bold on red    ', $teststring)->puts("\n");
		$scr->putcolored('magenta reverse', $teststring)->puts("\n");
		$scr->putcolored('red underline  ', $teststring)->puts("\n");
	}
	# require special treatment
	for $colorizable (0 .. 1) {
		$scr->colorizable($colorizable);
		$scr->normal()->puts("\n");
		$scr->flash()->puts("\n");
		$scr->putcolor('normal on green')->puts("\n");
		$scr->putcolored('normal on green', $teststring)->puts("\n");
	}

	$scr->cooked()->normal();
}

##########################################################################
# parent process: verify result

sub test_output {
	use Test::More tests => 259;
	my ($i, @tests, @descriptions, @results, $seq);
 
	@tests = (
		"direct simple termcap control: at(0,0)",                           "\e[1;1H",

		"direct simple termcap: bold()                   (colorizable=no)", "\e[1m",
		"direct simple termcap: underline()              (colorizable=no)", "\e[4m",
		"direct simple termcap: reverse()                (colorizable=no)", "\e[7m",

		"direct simple ansi: clear()                     (colorizable=no)", "",
		"direct simple ansi: reset()                     (colorizable=no)", "",
		"direct simple ansi: ansibold()                  (colorizable=no)", "",
		"direct simple ansi: italic()                    (colorizable=no)", "",
		"direct simple ansi: underscore()                (colorizable=no)", "",
		"direct simple ansi: blink()                     (colorizable=no)", "",
		"direct simple ansi: inverse()                   (colorizable=no)", "",
		"direct simple ansi: concealed()                 (colorizable=no)", "",

		"direct simple ansi: noansibold()                (colorizable=no)", "",
		"direct simple ansi: noitalic()                  (colorizable=no)", "",
		"direct simple ansi: nounderscore()              (colorizable=no)", "",
		"direct simple ansi: noblink()                   (colorizable=no)", "",
		"direct simple ansi: noinverse()                 (colorizable=no)", "",
		"direct simple ansi: noconcealed()               (colorizable=no)", "",

		"fetch simple termcap: bold                      (colorizable=no)", "\e[1m",
		"fetch simple termcap: underline                 (colorizable=no)", "\e[4m",
		"fetch simple termcap: reverse                   (colorizable=no)", "\e[7m",

		"fetch simple ansi: reset                        (colorizable=no)", "",
		"fetch simple ansi: ansibold                     (colorizable=no)", "",
		"fetch simple ansi: italic                       (colorizable=no)", "",
		"fetch simple ansi: underscore                   (colorizable=no)", "",
		"fetch simple ansi: blink                        (colorizable=no)", "",
		"fetch simple ansi: inverse                      (colorizable=no)", "",
		"fetch simple ansi: concealed                    (colorizable=no)", "",

		"fetch simple ansi: noansibold                   (colorizable=no)", "",
		"fetch simple ansi: noitalic                     (colorizable=no)", "",
		"fetch simple ansi: nounderscore                 (colorizable=no)", "",
		"fetch simple ansi: noblink                      (colorizable=no)", "",
		"fetch simple ansi: noinverse                    (colorizable=no)", "",
		"fetch simple ansi: noconcealed                  (colorizable=no)", "",

		"apply simple termcap: bold                      (colorizable=no)", "\e[1m$teststring\e[0m",
		"apply simple termcap: underline                 (colorizable=no)", "\e[4m$teststring\e[0m",
		"apply simple termcap: reverse                   (colorizable=no)", "\e[7m$teststring\e[0m",

		"apply simple ansi: reset                        (colorizable=no)", $teststring,
		"apply simple ansi: ansibold                     (colorizable=no)", $teststring,
		"apply simple ansi: italic                       (colorizable=no)", $teststring,
		"apply simple ansi: underscore                   (colorizable=no)", $teststring,
		"apply simple ansi: blink                        (colorizable=no)", $teststring,
		"apply simple ansi: inverse                      (colorizable=no)", $teststring,
		"apply simple ansi: concealed                    (colorizable=no)", $teststring,

		"apply simple ansi: noansibold                   (colorizable=no)", $teststring,
		"apply simple ansi: noitalic                     (colorizable=no)", $teststring,
		"apply simple ansi: nounderscore                 (colorizable=no)", $teststring,
		"apply simple ansi: noblink                      (colorizable=no)", $teststring,
		"apply simple ansi: noinverse                    (colorizable=no)", $teststring,
		"apply simple ansi: noconcealed                  (colorizable=no)", $teststring,

		"direct simple color: black()                    (colorizable=no)", "",
		"direct simple color: red()                      (colorizable=no)", "",
		"direct simple color: green()                    (colorizable=no)", "",
		"direct simple color: yellow()                   (colorizable=no)", "",
		"direct simple color: blue()                     (colorizable=no)", "",
		"direct simple color: magenta()                  (colorizable=no)", "",
		"direct simple color: cyan()                     (colorizable=no)", "",
		"direct simple color: white()                    (colorizable=no)", "",

		"direct simple color: on_black()                 (colorizable=no)", "",
		"direct simple color: on_red()                   (colorizable=no)", "",
		"direct simple color: on_green()                 (colorizable=no)", "",
		"direct simple color: on_yellow()                (colorizable=no)", "",
		"direct simple color: on_blue()                  (colorizable=no)", "",
		"direct simple color: on_magenta()               (colorizable=no)", "",
		"direct simple color: on_cyan()                  (colorizable=no)", "",
		"direct simple color: on_white()                 (colorizable=no)", "",

		"fetch simple color: black                       (colorizable=no)", "",
		"fetch simple color: red                         (colorizable=no)", "",
		"fetch simple color: green                       (colorizable=no)", "",
		"fetch simple color: yellow                      (colorizable=no)", "",
		"fetch simple color: blue                        (colorizable=no)", "",
		"fetch simple color: magenta                     (colorizable=no)", "",
		"fetch simple color: cyan                        (colorizable=no)", "",
		"fetch simple color: white                       (colorizable=no)", "",

		"fetch simple color: on_black                    (colorizable=no)", "",
		"fetch simple color: on_red                      (colorizable=no)", "",
		"fetch simple color: on_green                    (colorizable=no)", "",
		"fetch simple color: on_yellow                   (colorizable=no)", "",
		"fetch simple color: on_blue                     (colorizable=no)", "",
		"fetch simple color: on_magenta                  (colorizable=no)", "",
		"fetch simple color: on_cyan                     (colorizable=no)", "",
		"fetch simple color: on_white                    (colorizable=no)", "",

		"apply simple color: black                       (colorizable=no)", $teststring,
		"apply simple color: red                         (colorizable=no)", $teststring,
		"apply simple color: green                       (colorizable=no)", $teststring,
		"apply simple color: yellow                      (colorizable=no)", $teststring,
		"apply simple color: blue                        (colorizable=no)", $teststring,
		"apply simple color: magenta                     (colorizable=no)", $teststring,
		"apply simple color: cyan                        (colorizable=no)", $teststring,
		"apply simple color: white                       (colorizable=no)", $teststring,

		"apply simple color: on_black                    (colorizable=no)", $teststring,
		"apply simple color: on_red                      (colorizable=no)", $teststring,
		"apply simple color: on_green                    (colorizable=no)", $teststring,
		"apply simple color: on_yellow                   (colorizable=no)", $teststring,
		"apply simple color: on_blue                     (colorizable=no)", $teststring,
		"apply simple color: on_magenta                  (colorizable=no)", $teststring,
		"apply simple color: on_cyan                     (colorizable=no)", $teststring,
		"apply simple color: on_white                    (colorizable=no)", $teststring,

		"fetch complex ansi: 33;41                       (colorizable=no)", "",
		"fetch complex ansi: ansibold yellow             (colorizable=no)", "",
		"fetch complex ansi: ansibold on red             (colorizable=no)", "",
		"fetch complex ansi: cyan on black               (colorizable=no)", "",
		"fetch complex ansi: white on cyan               (colorizable=no)", "",
		"fetch complex ansi: green on yellow             (colorizable=no)", "",
		"fetch complex ansi: magenta inverse             (colorizable=no)", "",
		"fetch complex ansi: on_red blink                (colorizable=no)", "",
		"fetch complex ansi: yellow on blue              (colorizable=no)", "",
		"fetch complex ansi: red underscore              (colorizable=no)", "",

		"apply complex ansi: 33;41                       (colorizable=no)", $teststring,
		"apply complex ansi: ansibold yellow             (colorizable=no)", $teststring,
		"apply complex ansi: ansibold on red             (colorizable=no)", $teststring,
		"apply complex ansi: cyan on black               (colorizable=no)", $teststring,
		"apply complex ansi: white on cyan               (colorizable=no)", $teststring,
		"apply complex ansi: green on yellow             (colorizable=no)", $teststring,
		"apply complex ansi: magenta inverse             (colorizable=no)", $teststring,
		"apply complex ansi: on_red blink                (colorizable=no)", $teststring,
		"apply complex ansi: yellow on blue              (colorizable=no)", $teststring,
		"apply complex ansi: red underscore              (colorizable=no)", $teststring,

		"fetch termcap/ansi combination: bold yellow     (colorizable=no)", "\e[1m",
		"fetch termcap/ansi combination: bold on red     (colorizable=no)", "\e[1m",
		"fetch termcap/ansi combination: magenta reverse (colorizable=no)", "\e[7m",
		"fetch termcap/ansi combination: red underline   (colorizable=no)", "\e[4m",

		"apply termcap/ansi combination: bold yellow     (colorizable=no)", "\e[1m$teststring\e[0m",
		"apply termcap/ansi combination: bold on red     (colorizable=no)", "\e[1m$teststring\e[0m",
		"apply termcap/ansi combination: magenta reverse (colorizable=no)", "\e[7m$teststring\e[0m",
		"apply termcap/ansi combination: red underline   (colorizable=no)", "\e[4m$teststring\e[0m",

		"direct simple termcap: bold()                   (colorizable=yes)", "\e[1m",
		"direct simple termcap: underline()              (colorizable=yes)", "\e[4m",
		"direct simple termcap: reverse()                (colorizable=yes)", "\e[7m",

		"direct simple ansi: clear()                     (colorizable=yes)", "\e[0m",
		"direct simple ansi: reset()                     (colorizable=yes)", "\e[0m",
		"direct simple ansi: ansibold()                  (colorizable=yes)", "\e[1m",
		"direct simple ansi: italic()                    (colorizable=yes)", "\e[3m",
		"direct simple ansi: underscore()                (colorizable=yes)", "\e[4m",
		"direct simple ansi: blink()                     (colorizable=yes)", "\e[5m",
		"direct simple ansi: inverse()                   (colorizable=yes)", "\e[7m",
		"direct simple ansi: concealed()                 (colorizable=yes)", "\e[8m",

		"direct simple ansi: noansibold()                (colorizable=yes)", "\e[22m",
		"direct simple ansi: noitalic()                  (colorizable=yes)", "\e[23m",
		"direct simple ansi: nounderscore()              (colorizable=yes)", "\e[24m",
		"direct simple ansi: noblink()                   (colorizable=yes)", "\e[25m",
		"direct simple ansi: noinverse()                 (colorizable=yes)", "\e[27m",
		"direct simple ansi: noconcealed()               (colorizable=yes)", "\e[28m",

		"fetch simple termcap: bold                      (colorizable=yes)", "\e[1m",
		"fetch simple termcap: underline                 (colorizable=yes)", "\e[4m",
		"fetch simple termcap: reverse                   (colorizable=yes)", "\e[7m",

		"fetch simple ansi: reset                        (colorizable=yes)", "\e[0m",
		"fetch simple ansi: ansibold                     (colorizable=yes)", "\e[1m",
		"fetch simple ansi: italic                       (colorizable=yes)", "\e[3m",
		"fetch simple ansi: underscore                   (colorizable=yes)", "\e[4m",
		"fetch simple ansi: blink                        (colorizable=yes)", "\e[5m",
		"fetch simple ansi: inverse                      (colorizable=yes)", "\e[7m",
		"fetch simple ansi: concealed                    (colorizable=yes)", "\e[8m",

		"fetch simple ansi: noansibold                   (colorizable=yes)", "\e[22m",
		"fetch simple ansi: noitalic                     (colorizable=yes)", "\e[23m",
		"fetch simple ansi: nounderscore                 (colorizable=yes)", "\e[24m",
		"fetch simple ansi: noblink                      (colorizable=yes)", "\e[25m",
		"fetch simple ansi: noinverse                    (colorizable=yes)", "\e[27m",
		"fetch simple ansi: noconcealed                  (colorizable=yes)", "\e[28m",

		"apply simple termcap: bold                      (colorizable=yes)", "\e[1m$teststring\e[0m",
		"apply simple termcap: underline                 (colorizable=yes)", "\e[4m$teststring\e[0m",
		"apply simple termcap: reverse                   (colorizable=yes)", "\e[7m$teststring\e[0m",

		"apply simple ansi: reset                        (colorizable=yes)", "\e[0m$teststring\e[0m",
		"apply simple ansi: ansibold                     (colorizable=yes)", "\e[1m$teststring\e[0m",
		"apply simple ansi: italic                       (colorizable=yes)", "\e[3m$teststring\e[0m",
		"apply simple ansi: underscore                   (colorizable=yes)", "\e[4m$teststring\e[0m",
		"apply simple ansi: blink                        (colorizable=yes)", "\e[5m$teststring\e[0m",
		"apply simple ansi: inverse                      (colorizable=yes)", "\e[7m$teststring\e[0m",
		"apply simple ansi: concealed                    (colorizable=yes)", "\e[8m$teststring\e[0m",

		"apply simple ansi: noansibold                   (colorizable=yes)", "\e[22m$teststring\e[0m",
		"apply simple ansi: noitalic                     (colorizable=yes)", "\e[23m$teststring\e[0m",
		"apply simple ansi: nounderscore                 (colorizable=yes)", "\e[24m$teststring\e[0m",
		"apply simple ansi: noblink                      (colorizable=yes)", "\e[25m$teststring\e[0m",
		"apply simple ansi: noinverse                    (colorizable=yes)", "\e[27m$teststring\e[0m",
		"apply simple ansi: noconcealed                  (colorizable=yes)", "\e[28m$teststring\e[0m",

		"direct simple color: black()                    (colorizable=yes)", "\e[30m",
		"direct simple color: red()                      (colorizable=yes)", "\e[31m",
		"direct simple color: green()                    (colorizable=yes)", "\e[32m",
		"direct simple color: yellow()                   (colorizable=yes)", "\e[33m",
		"direct simple color: blue()                     (colorizable=yes)", "\e[34m",
		"direct simple color: magenta()                  (colorizable=yes)", "\e[35m",
		"direct simple color: cyan()                     (colorizable=yes)", "\e[36m",
		"direct simple color: white()                    (colorizable=yes)", "\e[37m",

		"direct simple color: on_black()                 (colorizable=yes)", "\e[40m",
		"direct simple color: on_red()                   (colorizable=yes)", "\e[41m",
		"direct simple color: on_green()                 (colorizable=yes)", "\e[42m",
		"direct simple color: on_yellow()                (colorizable=yes)", "\e[43m",
		"direct simple color: on_blue()                  (colorizable=yes)", "\e[44m",
		"direct simple color: on_magenta()               (colorizable=yes)", "\e[45m",
		"direct simple color: on_cyan()                  (colorizable=yes)", "\e[46m",
		"direct simple color: on_white()                 (colorizable=yes)", "\e[47m",

		"fetch simple color: black                       (colorizable=yes)", "\e[30m",
		"fetch simple color: red                         (colorizable=yes)", "\e[31m",
		"fetch simple color: green                       (colorizable=yes)", "\e[32m",
		"fetch simple color: yellow                      (colorizable=yes)", "\e[33m",
		"fetch simple color: blue                        (colorizable=yes)", "\e[34m",
		"fetch simple color: magenta                     (colorizable=yes)", "\e[35m",
		"fetch simple color: cyan                        (colorizable=yes)", "\e[36m",
		"fetch simple color: white                       (colorizable=yes)", "\e[37m",

		"fetch simple color: on_black                    (colorizable=yes)", "\e[40m",
		"fetch simple color: on_red                      (colorizable=yes)", "\e[41m",
		"fetch simple color: on_green                    (colorizable=yes)", "\e[42m",
		"fetch simple color: on_yellow                   (colorizable=yes)", "\e[43m",
		"fetch simple color: on_blue                     (colorizable=yes)", "\e[44m",
		"fetch simple color: on_magenta                  (colorizable=yes)", "\e[45m",
		"fetch simple color: on_cyan                     (colorizable=yes)", "\e[46m",
		"fetch simple color: on_white                    (colorizable=yes)", "\e[47m",

		"apply simple color: black                       (colorizable=yes)", "\e[30m$teststring\e[0m",
		"apply simple color: red                         (colorizable=yes)", "\e[31m$teststring\e[0m",
		"apply simple color: green                       (colorizable=yes)", "\e[32m$teststring\e[0m",
		"apply simple color: yellow                      (colorizable=yes)", "\e[33m$teststring\e[0m",
		"apply simple color: blue                        (colorizable=yes)", "\e[34m$teststring\e[0m",
		"apply simple color: magenta                     (colorizable=yes)", "\e[35m$teststring\e[0m",
		"apply simple color: cyan                        (colorizable=yes)", "\e[36m$teststring\e[0m",
		"apply simple color: white                       (colorizable=yes)", "\e[37m$teststring\e[0m",

		"apply simple color: on_black                    (colorizable=yes)", "\e[40m$teststring\e[0m",
		"apply simple color: on_red                      (colorizable=yes)", "\e[41m$teststring\e[0m",
		"apply simple color: on_green                    (colorizable=yes)", "\e[42m$teststring\e[0m",
		"apply simple color: on_yellow                   (colorizable=yes)", "\e[43m$teststring\e[0m",
		"apply simple color: on_blue                     (colorizable=yes)", "\e[44m$teststring\e[0m",
		"apply simple color: on_magenta                  (colorizable=yes)", "\e[45m$teststring\e[0m",
		"apply simple color: on_cyan                     (colorizable=yes)", "\e[46m$teststring\e[0m",
		"apply simple color: on_white                    (colorizable=yes)", "\e[47m$teststring\e[0m",

		"fetch complex ansi: 33;41                       (colorizable=yes)", "\e[33;41m",
		"fetch complex ansi: ansibold yellow             (colorizable=yes)", "\e[1;33m",
		"fetch complex ansi: ansibold on red             (colorizable=yes)", "\e[1;41m",
		"fetch complex ansi: cyan on black               (colorizable=yes)", "\e[36;40m",
		"fetch complex ansi: white on cyan               (colorizable=yes)", "\e[37;46m",
		"fetch complex ansi: green on yellow             (colorizable=yes)", "\e[32;43m",
		"fetch complex ansi: magenta inverse             (colorizable=yes)", "\e[35;7m",
		"fetch complex ansi: on_red blink                (colorizable=yes)", "\e[41;5m",
		"fetch complex ansi: yellow on blue              (colorizable=yes)", "\e[33;44m",
		"fetch complex ansi: red underscore              (colorizable=yes)", "\e[31;4m",

		"apply complex ansi: 33;41                       (colorizable=yes)", "\e[33;41m$teststring\e[0m",
		"apply complex ansi: ansibold yellow             (colorizable=yes)", "\e[1;33m$teststring\e[0m",
		"apply complex ansi: ansibold on red             (colorizable=yes)", "\e[1;41m$teststring\e[0m",
		"apply complex ansi: cyan on black               (colorizable=yes)", "\e[36;40m$teststring\e[0m",
		"apply complex ansi: white on cyan               (colorizable=yes)", "\e[37;46m$teststring\e[0m",
		"apply complex ansi: green on yellow             (colorizable=yes)", "\e[32;43m$teststring\e[0m",
		"apply complex ansi: magenta inverse             (colorizable=yes)", "\e[35;7m$teststring\e[0m",
		"apply complex ansi: on_red blink                (colorizable=yes)", "\e[41;5m$teststring\e[0m",
		"apply complex ansi: yellow on blue              (colorizable=yes)", "\e[33;44m$teststring\e[0m",
		"apply complex ansi: red underscore              (colorizable=yes)", "\e[31;4m$teststring\e[0m",

		"fetch termcap/ansi combination: bold yellow     (colorizable=yes)", "\e[1;33m",
		"fetch termcap/ansi combination: bold on red     (colorizable=yes)", "\e[1;41m",
		"fetch termcap/ansi combination: magenta reverse (colorizable=yes)", "\e[35;7m",
		"fetch termcap/ansi combination: red underline   (colorizable=yes)", "\e[31;4m",

		"apply termcap/ansi combination: bold yellow     (colorizable=yes)", "\e[1;33m$teststring\e[0m",
		"apply termcap/ansi combination: bold on red     (colorizable=yes)", "\e[1;41m$teststring\e[0m",
		"apply termcap/ansi combination: magenta reverse (colorizable=yes)", "\e[35;7m$teststring\e[0m",
		"apply termcap/ansi combination: red underline   (colorizable=yes)", "\e[31;4m$teststring\e[0m",
	);

	$i = 1; @descriptions = grep { $i++ % 2 } @tests;
	$i = 0; @results      = grep { $i++ % 2 } @tests;

	foreach my $i (0 .. $#descriptions) {
		ok(<HANDLE> eq "$results[$i]\n", $descriptions[$i]);
	}
	$seq = <HANDLE>;
	ok($NORMALS{$seq}, "direct simple termcap: normal()                 (colorizable=no)");
	$seq = <HANDLE>;
	ok($FLASHES{$seq}, "direct simple termcap: flash()                  (colorizable=no)");
	$seq = <HANDLE>;
	ok($NORMALS{$seq}, "fetch termcap/ansi combination: normal on green (colorizable=no)");
	$seq = <HANDLE>;
	$seq =~ /^(.*)$teststring/;
	ok($NORMALS{"$1\n"},
			   "apply termcap/ansi combination: normal on green (colorizable=no)");
	$seq = <HANDLE>;
	ok($NORMALS{$seq}, "direct simple termcap: normal()                 (colorizable=yes)");
	$seq = <HANDLE>;
	ok($FLASHES{$seq}, "direct simple termcap: flash()                  (colorizable=yes)");
	$seq = <HANDLE>;
	ok($seq eq "\e[0;42m\n",
			   "fetch termcap/ansi combination: normal on green (colorizable=yes)");
	$seq = <HANDLE>;
	ok($seq eq "\e[0;42m$teststring\e[0m\n",
			   "apply termcap/ansi combination: normal on green (colorizable=yes)");
}

##########################################################################
# main

main();

__END__

