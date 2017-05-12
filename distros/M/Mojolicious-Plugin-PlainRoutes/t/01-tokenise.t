#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Deep;
use Mojolicious::Plugin::PlainRoutes;

sub tokenise {
	state $m = Mojolicious::Plugin::PlainRoutes->new;
	return $m->tokenise(@_);
}

my $t1 = tokenise(<<EOF);
GET / -> Foo.bar
GET /baz -> Foo.baz
EOF

cmp_deeply(
	$t1,
	[
		{
			action => 'foo#bar',
			verb => 'GET',
			path => '/',
		},
		{
			action => 'foo#baz',
			verb => 'GET',
			path => '/baz',
		},
	],
	"Simple case"
);

my $t2 = tokenise(<<EOF);
ANY /foo -> Foo.do {
	GET /bar -> Foo.bar
	GET /baz -> Foo.baz
}
EOF

cmp_deeply(
	$t2,
	[
		[
			{ action => 'foo#do', verb => 'ANY', path => '/foo' },
			{ action => 'foo#bar', verb => 'GET', path => '/bar' },
			{ action => 'foo#baz', verb => 'GET', path => '/baz' },
		],
	],
	"One-depth bridge",
);

my $t3 = tokenise(<<EOF);
ANY / -> Foo.do {
	GET /bar -> Foo.bar
	ANY /baz -> Foo.baz {
		GET /quux -> Foo.quux
	}
	GET /egimosx -> Foo.regex
}
EOF

cmp_deeply(
	$t3,
	[
		[
			{ action => 'foo#do', verb => 'ANY', path => '/' },
			{ action => 'foo#bar', verb => 'GET', path => '/bar' },
			[
				{ action => 'foo#baz', verb => 'ANY', path => '/baz' },
				{ action => 'foo#quux', verb => 'GET', path => '/quux' },
			],
			{ action => 'foo#regex', verb => 'GET', path => '/egimosx' },
		],
	],
	"Two-depth bridge",
);


my $t4 = tokenise(<<EOF);
ANY / -> Foo.do {
	ANY /baz -> Foo.baz {
		GET /quux -> Foo.quux
	}
}
EOF

cmp_deeply(
	$t4,
	[
		[
			{ action => 'foo#do', verb => 'ANY', path => '/' },
			[
				{ action => 'foo#baz', verb => 'ANY', path => '/baz' },
				{ action => 'foo#quux', verb => 'GET', path => '/quux' },
			],
		],
	],
	"Double bridge termination",
);

cmp_deeply(
	tokenise("ANY/ ->Foo.do{GET/baz ->Foo.baz}"),
	[
		[
			{ action => 'foo#do', verb => 'ANY', path => '/' },
			{ action => 'foo#baz', verb => 'GET', path => '/baz' },
		],
	],
	"Compact",
);

cmp_deeply(
	tokenise("GET / Foo.do"),
	[{ action => 'foo#do', verb => 'GET', path => '/' }],
	"Ommitted arrow",
);

cmp_deeply(
	tokenise("GET / -> Foo.do (do)"),
	[{ action => 'foo#do', verb => 'GET', path => '/', name => 'do' }],
	"Ordinary name",
);

cmp_deeply(
	tokenise("GET / -> Foo.do (GET)"),
	[{ action => 'foo#do', verb => 'GET', path => '/', name => 'GET' }],
	"Name containing keyword",
);

cmp_deeply(
	tokenise("GET / -> # Foo.do \n Foo.bar"),
	[{ action => 'foo#bar', verb => 'GET', path => '/' }],
	"Basic comment",
);

done_testing;
