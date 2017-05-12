#!perl

use Test::More tests => 1;

BEGIN {
	use_ok('Padre::Plugin::Catalyst');
}

diag("Testing Padre::Plugin::Catalyst $Padre::Plugin::Catalyst::VERSION, Perl $], $^X");
