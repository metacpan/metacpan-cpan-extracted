# -*- perl -*-

#use Test::More qw/no_plan/;
use Test::More tests => 8;

use Resource::Loader;

ok $m = Resource::Loader->new(
				resources => [ { name => 'never',
						 when => sub { 0 },
						 what => sub { &die },
					       },
					       { name => 'always',
						 when => sub { 1 },
						 what => sub { "@_" },
						 whatargs => [ 1, 2, 3 ],
					       },
					     ],

			      ),		"new( args )";

ok $loaded = $m->load,				"load()";
ok $status = $m->status,			"status()";

is_deeply [ keys %$loaded ], [ "always" ],	"loaded() keys";
is_deeply [ values %$loaded ], [ "1 2 3" ],	"loaded() values";
is_deeply [ sort keys %$status ], [qw/always never/ ],	"keys in status";
is $status->{always}, 'loaded',			"always was loaded";
is $status->{never}, 'inactive',		"never is inactive";
