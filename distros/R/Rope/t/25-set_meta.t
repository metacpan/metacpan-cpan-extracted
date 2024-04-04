use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Monkey;

	property one => (
		value => 2,
		writeable => 1,
		enumerable => 0,
		clearer => 1
	);

	property two => (
		value => 2,
		writeable => 1,
		enumerable => 0,
		clearer => 'we_clear_two'
	);

	property three => (
		value => 2,
		writeable => 1,
		enumerable => 0,
		clearer => sub { $_[0]->{$_[1]} = undef; }
	);

	property four => (
		value => 2,
		writeable => 1,
		clearer => {
			value => sub { $_[0]->{$_[1]} = undef; },
			writeable => 1
		}
	);

	monkey;

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}

my $meta = Rope->get_meta('Extendings');

Rope->clear_meta('Extendings');

my $meta2 = Rope->get_meta('Extendings');

is_deeply($meta2, {
	name => 'Extendings',
	locked => 0,
	properties => {},
	requires => {},
	keys => 0
});

my $clone = {%{$meta}};
delete $clone->{properties}; # as we can just inherit all the methods!
Rope->set_meta($clone);

is_deeply(Rope->get_meta('Extendings'), $meta);





ok(1);

done_testing();
