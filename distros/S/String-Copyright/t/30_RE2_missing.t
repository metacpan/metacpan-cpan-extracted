use Test2::V0;

use Test::Without::Module qw( re::engine::RE2 );

plan 1;

use String::Copyright {
	format => sub { join ':', $_->[0] || '', $_->[1] || '' }
};

is copyright('This software is copyright (c) 2016 by Foo'), '2016:Foo',
	'sign pseudosign intro';

done_testing;
