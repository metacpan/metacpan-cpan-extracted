#!perl

use Test::More tests => 4;

BEGIN {
	use_ok( 'Module::Pragma' );
}

ok $Module::Pragma::VERSION, "Module::Pragma version: $Module::Pragma::VERSION";

ok !Module::Pragma->import(),   "import():   do nothing";
ok !Module::Pragma->unimport(), "unimport(): do nothing";

#EOF
