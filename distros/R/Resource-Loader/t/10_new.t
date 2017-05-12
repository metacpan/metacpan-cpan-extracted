# -*- perl -*-

#use Test::More qw/no_plan/;
use Test::More tests => 6;

use Resource::Loader;
use Data::Dumper;

ok $mgr = Resource::Loader->new,		"new()";
isa_ok $mgr, 'Resource::Loader';

ok $m2 = Resource::Loader->new( testing => 1,
				 verbose => 1,
				 resources => [ { name => 'never',
						  when => sub { 0 },
						  what => sub { &die },
						},
						{ name => 'always',
						  when => sub { 1 },
						  what => sub { print @_ },
						  args => [ 1, 2, 3 ],
						},
					      ],

			       ),		"new( args )";

is $m2->testing, 1, 				"testing()";
is $m2->verbose, 1,				"verbose()";
ok ! $m2->cont, 				"cont()";
