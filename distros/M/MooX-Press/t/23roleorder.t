use strict;
use warnings;
use Test::More;

use MooX::Press (
	prefix => 'MyApp',
	class => [
		'Class' => {
			with => ['Role1', 'Role4'],
		},
	],
	role => [
		'Role1' => {
			with => 'Role2',
		},
		'Role2' => {
			with => ['Role3', 'Role4'],
		},
		'Role3' => {
			can => {
				'foo' => sub { 666 },
			},
		},
		'Role4' => {
			can => {
				'bar' => sub { 999 },
			},
		},
	],
);

my $obj = MyApp->new_class;

is($obj->foo, 666);
is($obj->bar, 999);

done_testing;
