# -*- perl -*-

#use Test::More qw/no_plan/;
use Test::More tests => 7;
use Test::Exception;

use Resource::Loader;

ok $m = Resource::Loader->new( resources => [ { name => 'always',
						when => sub { @_ },
						whenargs => [ "do it!" ],
						what => sub { 'loaded' },
					      },
					    ],
			      ),		"new()";

ok $loaded = $m->load,				"load()";
is $loaded->{always}, 'loaded',			"loaded correctly";

dies_ok { Resource::Loader->new( resources => [ { name => 'never',
						  when => sub { @_ },
						  whenargs => "do it!",
						  what => sub { 'loaded' },
						},
					      ],
			       )
         }  					"new() with bad 'whenargs'";

ok $m = Resource::Loader->new( resources => [ { name => 'always',
						when => sub { @_ },
						whenargs => [ 1, 2, 3 ],
						what => sub { 'loaded' },
					      },
					    ],
			      ),		"new()";
ok $loaded = $m->load,				"load()";
is $loaded->{always}, 'loaded',			"loaded correctly";
