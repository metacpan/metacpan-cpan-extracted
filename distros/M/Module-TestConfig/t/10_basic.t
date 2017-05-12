# -*- perl -*-

use Test::More tests => 13;
#use Test::More 'no_plan';

use Module::TestConfig;

ok $t = Module::TestConfig->new,		 "new()";
is $t->verbose, 1,				 "verbose()";
is $t->defaults, 'defaults.config',		 "defaults()";
is $t->file, 'MyConfig.pm',			 "file()";
is_deeply [$t->order], [ qw/defaults/ ], 	 "order()";
is_deeply [$t->questions], [ ],			 "questions()";

ok ! eval { Module::TestConfig->new( foo => 'bar' ) }, "new() with bad args";

is $t->verbose(0), 0,				 "verbose(0)";
is $t->defaults('foo'), 'foo',			 "defaults('foo')";
is $t->file('bar'), 'bar',			 "file('bar')";
is_deeply [$t->order('defaults')], [ qw/defaults/ ], "order('defaults')";
is_deeply [$t->order(['defaults'])], [ qw/defaults/ ], "order(['defaults'])";
is_deeply [$t->questions], [ ],			 "questions()";
