#!perl

use Test::More tests => 2;

BEGIN {
	use_ok('Padre::Plugin::REPL');
	use_ok('Padre::Plugin::REPL::Panel');
}

diag("Testing Padre::Plugin::REPL $Padre::Plugin::REPL::VERSION, Perl $], $^X");
