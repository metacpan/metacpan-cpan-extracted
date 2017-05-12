#!/usr/bin/env perl
#
##########################################################################
#
# Name:         02-color-wrappers.t
# Version:      1.20
# Author:       Rene Uittenbogaard
# Date:         2010-10-04
# Requires:     Term::ScreenColor
# Description:  Tests for string wrapping methods in Term::ScreenColor
#

##########################################################################
# declarations

use strict;
use Test::More tests => 208;

require Term::ScreenColor;

my $scr;

my %NORMALS = (
	"\e[m"      => 1,
	"\e[0m"     => 1,
	"\e[m\cO"   => 1,
	"\e[0m\cO"  => 1,
	"\e(B\e[m"  => 1,
	"\e(B\e[0m" => 1,
);

my %FLASHES = (
	"\e[?5h\e[?5l" => 1,
	""             => 1,
);

my @tests = (
	# ansi colors: 'colorizable' turns them on/off
	{ chapter => 'simple ansi: ', color => 'clear                       ', 0 => "", 1 => "\e[0m"  },
	{ chapter => 'simple ansi: ', color => 'reset                       ', 0 => "", 1 => "\e[0m"  },
	{ chapter => 'simple ansi: ', color => 'ansibold                    ', 0 => "", 1 => "\e[1m"  },
	{ chapter => 'simple ansi: ', color => 'italic                      ', 0 => "", 1 => "\e[3m"  },
	{ chapter => 'simple ansi: ', color => 'underscore                  ', 0 => "", 1 => "\e[4m"  },
	{ chapter => 'simple ansi: ', color => 'blink                       ', 0 => "", 1 => "\e[5m"  },
	{ chapter => 'simple ansi: ', color => 'inverse                     ', 0 => "", 1 => "\e[7m"  },
	{ chapter => 'simple ansi: ', color => 'concealed                   ', 0 => "", 1 => "\e[8m"  },

	{ chapter => 'simple ansi: ', color => 'noansibold                  ', 0 => "", 1 => "\e[22m" },
	{ chapter => 'simple ansi: ', color => 'noitalic                    ', 0 => "", 1 => "\e[23m" },
	{ chapter => 'simple ansi: ', color => 'nounderscore                ', 0 => "", 1 => "\e[24m" },
	{ chapter => 'simple ansi: ', color => 'noblink                     ', 0 => "", 1 => "\e[25m" },
	{ chapter => 'simple ansi: ', color => 'noinverse                   ', 0 => "", 1 => "\e[27m" },
	{ chapter => 'simple ansi: ', color => 'noconcealed                 ', 0 => "", 1 => "\e[28m" },

	{ chapter => 'simple ansi color: ', color => 'black                 ', 0 => "", 1 => "\e[30m" },
	{ chapter => 'simple ansi color: ', color => 'red                   ', 0 => "", 1 => "\e[31m" },
	{ chapter => 'simple ansi color: ', color => 'green                 ', 0 => "", 1 => "\e[32m" },
	{ chapter => 'simple ansi color: ', color => 'yellow                ', 0 => "", 1 => "\e[33m" },
	{ chapter => 'simple ansi color: ', color => 'blue                  ', 0 => "", 1 => "\e[34m" },
	{ chapter => 'simple ansi color: ', color => 'magenta               ', 0 => "", 1 => "\e[35m" },
	{ chapter => 'simple ansi color: ', color => 'cyan                  ', 0 => "", 1 => "\e[36m" },
	{ chapter => 'simple ansi color: ', color => 'white                 ', 0 => "", 1 => "\e[37m" },

	{ chapter => 'simple ansi color: ', color => 'on_black              ', 0 => "", 1 => "\e[40m" },
	{ chapter => 'simple ansi color: ', color => 'on_red                ', 0 => "", 1 => "\e[41m" },
	{ chapter => 'simple ansi color: ', color => 'on_green              ', 0 => "", 1 => "\e[42m" },
	{ chapter => 'simple ansi color: ', color => 'on_yellow             ', 0 => "", 1 => "\e[43m" },
	{ chapter => 'simple ansi color: ', color => 'on_blue               ', 0 => "", 1 => "\e[44m" },
	{ chapter => 'simple ansi color: ', color => 'on_magenta            ', 0 => "", 1 => "\e[45m" },
	{ chapter => 'simple ansi color: ', color => 'on_cyan               ', 0 => "", 1 => "\e[46m" },
	{ chapter => 'simple ansi color: ', color => 'on_white              ', 0 => "", 1 => "\e[47m" },

	{ chapter => 'complex ansi: ', color => '33;41                      ', 0 => "", 1 => "\e[33;41m" },
	{ chapter => 'complex ansi: ', color => 'ansibold yellow            ', 0 => "", 1 => "\e[1;33m"  },
	{ chapter => 'complex ansi: ', color => 'ansibold on red            ', 0 => "", 1 => "\e[1;41m"  },
	{ chapter => 'complex ansi: ', color => 'cyan on black              ', 0 => "", 1 => "\e[36;40m" },
	{ chapter => 'complex ansi: ', color => 'white on cyan              ', 0 => "", 1 => "\e[37;46m" },
	{ chapter => 'complex ansi: ', color => 'green on yellow            ', 0 => "", 1 => "\e[32;43m" },
	{ chapter => 'complex ansi: ', color => 'magenta inverse            ', 0 => "", 1 => "\e[35;7m"  },
	{ chapter => 'complex ansi: ', color => 'on_red blink               ', 0 => "", 1 => "\e[41;5m"  },
	{ chapter => 'complex ansi: ', color => 'yellow on blue             ', 0 => "", 1 => "\e[33;44m" },
	{ chapter => 'complex ansi: ', color => 'red underscore             ', 0 => "", 1 => "\e[31;4m"  },

	# termcap codes (non-ansi), so 'colorizable' makes no difference
	{ chapter => 'simple termcap: ', color => 'bold                     ', 0 => "\e[1m", 1 => "\e[1m" },
	{ chapter => 'simple termcap: ', color => 'underline                ', 0 => "\e[4m", 1 => "\e[4m" },
	{ chapter => 'simple termcap: ', color => 'reverse                  ', 0 => "\e[7m", 1 => "\e[7m" },

	# if 'colorizable' is off, only the non-ansi component passes
	{ chapter => 'termcap/ansi combination: ', color => 'bold yellow    ', 0 => "\e[1m", 1 => "\e[1;33m" },
	{ chapter => 'termcap/ansi combination: ', color => 'bold on red    ', 0 => "\e[1m", 1 => "\e[1;41m" },
	{ chapter => 'termcap/ansi combination: ', color => 'magenta reverse', 0 => "\e[7m", 1 => "\e[35;7m" },
	{ chapter => 'termcap/ansi combination: ', color => 'red underline  ', 0 => "\e[4m", 1 => "\e[31;4m" },
);

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
	return $scr;
}

##########################################################################
# test Term::ScreenColor

sub main {
	my ($scr) = @_;
	my ($i, @descriptions, @results, $result, $able, $actual);

	my $teststring = 'blurk';

#	$i = 1; @descriptions = grep { $i++ % 2 } @tests;
#	$i = 0; @results      = grep { $i++ % 2 } @tests;
#
	# ---------- colorizable off ----------
	ok($scr->colorizable($able = 0), 'turn colorizable off');

	ok($scr->bold2esc()      eq "\e[1m",
			'direct fetch simple termcap: bold                (colorizable=no)');
	ok($scr->underline2esc() eq "\e[4m",
			'direct fetch simple termcap: underline           (colorizable=no)');
	ok($scr->reverse2esc()   eq "\e[7m",
			'direct fetch simple termcap: reverse             (colorizable=no)');
	ok($FLASHES{$scr->flash2esc()},
			'direct fetch simple termcap: flash               (colorizable=no)');
	ok($NORMALS{$scr->normal2esc()},
			'direct fetch simple termcap: normal              (colorizable=no)');
	ok($scr->color2esc('')               eq "",
			'fetch ansi color: empty string                   (colorizable=no)');
	ok($scr->colored('', $teststring)          eq $teststring,
			'apply ansi color: empty string                   (colorizable=no)');
	ok($NORMALS{$scr->color2esc('normal on green')},
			'fetch ansi/termcap combination: normal on green  (colorizable=no)');
	$result = $scr->colored('normal on green', $teststring);
	$result =~ /^(.*)$teststring/;
	ok($NORMALS{$1},'apply ansi/termcap combination: normal on green  (colorizable=no)');

	foreach $i (0 .. $#tests) {
		$result = $tests[$i]{$able};
		ok($scr->color2esc($tests[$i]{color}) eq $result,
			"fetch $tests[$i]{chapter}$tests[$i]{color}  (colorizable=no)");
		ok($scr->colored($tests[$i]{color}, $teststring) eq
			($result ? "$result$teststring\e[0m" : $teststring),
			"apply $tests[$i]{chapter}$tests[$i]{color}  (colorizable=no)");
	}

	# ---------- colorizable on ----------
	ok($scr->colorizable($able = 1), 'turn colorizable on');

	ok($scr->bold2esc()      eq "\e[1m",
			'direct fetch simple termcap: bold                (colorizable=yes)');
	ok($scr->underline2esc() eq "\e[4m",
			'direct fetch simple termcap: underline           (colorizable=yes)');
	ok($scr->reverse2esc()   eq "\e[7m",
			'direct fetch simple termcap: reverse             (colorizable=yes)');
	ok($FLASHES{$scr->flash2esc()},
			'direct fetch simple termcap: flash               (colorizable=yes)');
	ok($NORMALS{$scr->normal2esc()},
			'direct fetch simple termcap: normal              (colorizable=yes)');
	ok($scr->color2esc('')               eq "",
			'fetch ansi color: empty string                   (colorizable=yes)');
	ok($scr->colored('', $teststring)    eq $teststring, 
			'apply ansi color: empty string                   (colorizable=yes)');
	ok($scr->color2esc('normal on green') eq "\e[0;42m",
			'fetch ansi/termcap combination: normal on green  (colorizable=yes)');
	ok($scr->colored('normal on green', $teststring) eq "\e[0;42m$teststring\e[0m",
			'apply ansi/termcap combination: normal on green  (colorizable=yes)');

	foreach $i (0 .. $#tests) {
		$result = $tests[$i]{$able};
		ok($scr->color2esc($tests[$i]{color}) eq $result,
			"fetch $tests[$i]{chapter}$tests[$i]{color}  (colorizable=yes)");
		ok($scr->colored($tests[$i]{color}, $teststring) eq
			($result ? "$result$teststring\e[0m" : $teststring),
			"apply $tests[$i]{chapter}$tests[$i]{color}  (colorizable=yes)");
	}

}

##########################################################################
# main

$scr = init();
main($scr);

__END__

