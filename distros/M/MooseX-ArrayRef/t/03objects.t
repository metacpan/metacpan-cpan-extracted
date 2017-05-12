use Test::More;

{
	package Foo;
	use MooseX::ArrayRef;
	has [qw/a c e/] => (is => 'rw');
}

{
	package Bar;
	use Moose::Role;
	has [qw/b/] => (is => 'rw', clearer => 'clear_b', predicate => 'has_b');
}

{
	package Foo::Bar;
	use MooseX::ArrayRef; extends 'Foo'; with 'Bar';
	has [qw/d/] => (is => 'ro');
	Foo::Bar->meta->make_immutable;
}

ok(
	Foo::Bar->meta->is_immutable
);

my $obj = Foo::Bar->new(
	a  => 'A',
	b  => 'B',
	d  => 'D',
	e  => 'E',
);

note q($obj = ), explain($obj);

note q(Foo slot_to_index_map ), explain(Foo->meta->slot_to_index_map);
note q(Foo::Bar slot_to_index_map ), explain(Foo::Bar->meta->slot_to_index_map);


is($obj->d, 'D', '$obj->d');
is($obj->a, 'A', '$obj->a');
is($obj->b, 'B', '$obj->b');
is($obj->e, 'E', '$obj->e');

ok($obj->has_b, 'predicates work');

$obj->b(undef);
ok($obj->has_b, 'empty slot is dfferent to undef');

$obj->clear_b;
ok(not($obj->has_b), 'clearers work');

$obj->b('Bee');
is($obj->b, 'Bee', 'setters work');

my $obj2 = $obj->meta->clone_object($obj, b => 'be');
is($obj2->a, 'A',  '$obj2->a');
is($obj2->b, 'be', '$obj2->b');

done_testing();
