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


note 'public';

my ($bpush, $bpop, $bread, $bwrite, $bclear);
use MooX::Press (
	prefix => 'MyApp3',
	class => [
		'Foo' => {
			has => {
				bizzle => [
					is           => rw,
					isa          => ArrayRef,
					required     => true,
					init_arg     => 'b',
					reader       => \$bread,
					writer       => \$bwrite,
					clearer      => \$bclear,
					accessor     => 'bizzle',
					handles_via  => 'Array',
					handles      => [
						\$bpush => 'push',
						\$bpop  => 'pop',
						'ball'  => 'all',
					],
				],
			},
		},
	],
);

my $obj3 = MyApp3->new_foo( b => [666,999] );

is_deeply( $obj3->bizzle, [666,999], 'constructor and rw accessor' );

$obj3->$bclear;

is( $obj3->bizzle, undef, 'clearer' );

$obj3->$bwrite([42]);

is_deeply( $obj3->$bread, [42], 'writer and reader' );

$obj3->$bpush(69,70);

is_deeply( $obj3->$bread, [42, 69, 70], 'delegation(push) and reader' );

is($obj3->$bpop, 70, 'delegation(pop)');

is_deeply( [ $obj3->ball ], [42, 69], 'delegation(pop) and delegation(all)' );

done_testing;

