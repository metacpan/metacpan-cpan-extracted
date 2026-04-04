use Test::More;

{
	package Animal;

	use Object::Proto::Sugar;

	has name => (
	  is  => 'rw',
	  isa => 'Str',
	);

	has sound => (
	  is      => 'rw',
	  isa     => 'Str',
	  default => 'silence',
	);

	sub speak { $_[0]->sound }

	1;
}

{
	package Dog;

	use Object::Proto::Sugar;

	extends 'Animal';

	has breed => (
	  is  => 'rw',
	  isa => 'Str',
	);

	1;
}

package main;

my $dog = new Dog name => 'Rex', sound => 'woof', breed => 'Lab';

is($dog->name,  'Rex',  'inherited name accessor works');
is($dog->sound, 'woof', 'inherited sound accessor works');
is($dog->breed, 'Lab',  'own breed accessor works');
is($dog->speak, 'woof', 'inherited method works');
ok($dog->isa('Animal'), 'isa Animal');
ok($dog->isa('Dog'),    'isa Dog');

my $cat = new Animal name => 'Whiskers';
is($cat->sound, 'silence', 'default inherited by parent instance');

done_testing();
