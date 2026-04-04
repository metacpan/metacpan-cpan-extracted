use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	has name => (
	  is       => 'rw',
	  accessor => 1,
	);

	has age => (
	  is       => 'rw',
	  accessor => 'fetch_age',
	);

	has score => (
	  is     => 'rw',
	  reader => 1,
	  writer => 1,
	);

	1;
}

package main;

my $t = new Test 'Alice', 30, 99;

# accessor => 1 installs function named after attribute
is(Test::name($t),       'Alice', 'accessor => 1 get');
Test::name($t, 'Bob');
is(Test::name($t),       'Bob',   'accessor => 1 set');

# accessor => 'fname' installs function with custom name
is(Test::fetch_age($t),  30,      'accessor => fname get');
Test::fetch_age($t, 31);
is(Test::fetch_age($t),  31,      'accessor => fname set');

# reader => 1 installs get_$name method AND function
is($t->get_score,        99,      'reader => 1 method');
is(Test::get_score($t),  99,      'reader => 1 function');

# writer => 1 installs set_$name method AND function
$t->set_score(100);
is($t->score,            100,     'writer => 1 method set');
Test::set_score($t, 200);
is($t->score,            200,     'writer => 1 function set');

# import_accessors: child class imports parent + own functions into caller
{
	package Animal;
	use Object::Proto::Sugar;
	has name  => ( is => 'rw', accessor => 1 );
	has sound => ( is => 'rw', accessor => 1 );
	1;
}

{
	package Dog;
	use Object::Proto::Sugar;
	extends 'Animal';
	has breed => ( is => 'rw', accessor => 1 );
	1;
}

{
	package Consumer;
	Dog->import_accessors;   # should import name, sound, breed

	sub run {
		my $d = new Dog 'Rex', 'woof', 'Lab';
		return (main::name($d), main::sound($d), main::breed($d));
	}
}

# import_accessors with no args imports all (own + inherited)
Dog->import_accessors;
my $d = new Dog 'Rex', 'woof', 'Lab';
is(name($d),  'Rex',  'import_accessors: inherited name');
is(sound($d), 'woof', 'import_accessors: inherited sound');
is(breed($d), 'Lab',  'import_accessors: own breed');

# import_accessors with explicit list
{
	package Other;
	Dog->import_accessors('breed');
	sub check { breed($_[0]) }
}
is(Other::check($d), 'Lab', 'import_accessors: explicit list');

done_testing();
