use strict;
use warnings;
use Test::More;
use Test::Fatal;

use MooX::Press::Keywords;

note 'simple';

my $bizzle;
use MooX::Press (
	prefix => 'MyApp',
	class => [
		'Foo' => {
			has => {
				bizzle => [ is => private, isa => Int, accessor => \$bizzle ],
			},
		},
	],
);

my $obj = MyApp->new_foo(bizzle => 42);

ok(!$obj->can('bizzle'), 'no normal accessor method created for bizzle');
ok(!exists $obj->{bizzle}, 'bizzle not set by constructor');

$obj->$bizzle(666);
is($obj->$bizzle, 666, 'lexical accessor works');


note 'delegation';

use MooX::Press (
	prefix => 'MyApp2',
	class => [
		'Foo' => {
			has => {
				bizzle => [
					is           => private,
					isa          => ArrayRef[Int],
					default      => sub { [] },
					handles_via  => 'Array',
					handles      => [
						push_bizzle => 'push',
						pop_bizzle  => 'pop',
					],
				],
			},
		},
	],
);

my $obj2 = MyApp2->new_foo(bizzle => 42);

ok(!$obj2->can('bizzle'), 'no normal accessor method created for bizzle');
ok(!exists $obj2->{bizzle}, 'bizzle not set by constructor');

$obj2->push_bizzle(666);
$obj2->push_bizzle(999);
$obj2->push_bizzle(420);

is($obj2->pop_bizzle, 420);
is($obj2->pop_bizzle, 999);
is($obj2->pop_bizzle, 666);

done_testing;

