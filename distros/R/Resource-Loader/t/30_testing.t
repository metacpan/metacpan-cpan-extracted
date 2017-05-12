# -*- perl -*-

#use Test::More qw/no_plan/;
use Test::More tests => 6;

use Resource::Loader;
use Data::Dumper;

ok $m = Resource::Loader->new( testing => 1,
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

$loaded = $m->load;
ok ! $loaded,					"load()";
ok $status = $m->status,			"status()";

is_deeply [ sort keys %$status ], [qw/always never/ ],  "keys in status";
is $status->{always}, 'notrun',                 "always was loaded";
is $status->{never}, 'inactive',                "never is inactive";
