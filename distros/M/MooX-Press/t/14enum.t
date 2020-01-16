use strict;
use warnings;
use Test::More;

use MooX::Press (
	prefix => 'MyApp',
	class => [
		'Foo' => [
			has => {
				'foo' => { enum => [qw/aaa bbb ccc/], handles => 2 },
			},
		],
	],
);


my $foo = MyApp::Foo->new(foo => 'bbb');

ok !$foo->foo_is_aaa;
ok  $foo->foo_is_bbb;
ok !$foo->foo_is_ccc;

done_testing;
