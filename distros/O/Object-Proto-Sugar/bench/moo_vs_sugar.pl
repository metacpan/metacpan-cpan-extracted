#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:all);

# ---- Moo class -------------------------------------------------------
{
	package Animal::Moo;
	use Moo;
	use Class::XSAccessor;

	has name  => ( is => 'rw' );
	has sound => ( is => 'rw', default => 'silence' );
	has age   => ( is => 'rw' );

	sub speak { $_[0]->sound }
}

{
	package Dog::Moo;
	use Moo;
	extends 'Animal::Moo';

	has breed => ( is => 'rw' );
}

# ---- Mouse class -----------------------------------------------------
{
	package Animal::Mouse;
	use Mouse;

	has name  => ( is => 'rw' );
	has sound => ( is => 'rw', default => 'silence' );
	has age   => ( is => 'rw' );

	sub speak { $_[0]->sound }
}

{
	package Dog::Mouse;
	use Mouse;
	extends 'Animal::Mouse';

	has breed => ( is => 'rw' );
}

# ---- Object::Proto::Sugar (method-style) -----------------------------
{
	package Animal::Sugar;
	use Object::Proto::Sugar;

	has name  => ( is => 'rw' );
	has sound => ( is => 'rw', default => 'silence' );
	has age   => ( is => 'rw' );

	sub speak { $_[0]->sound }
}

{
	package Dog::Sugar;
	use Object::Proto::Sugar;
	extends 'Animal::Sugar';

	has breed => ( is => 'rw' );
}

# ---- Object::Proto::Sugar (function-style accessors) -----------------
{
	package Animal::SugarFn;
	use Object::Proto::Sugar;

	has name  => ( is => 'rw', accessor => 1 );
	has sound => ( is => 'rw', accessor => 1, default => 'silence' );
	has age   => ( is => 'rw', accessor => 1 );

	sub speak { Animal::SugarFn::sound($_[0]) }  # fully qualified — in own package
}

{
	package Dog::SugarFn;
	use Object::Proto::Sugar;
	extends 'Animal::SugarFn';

	has breed => ( is => 'rw', accessor => 1 );
}

# Import function-style accessors into main
Dog::SugarFn->import_accessors;   # imports: name, sound, age, breed

# ---- Benchmarks ------------------------------------------------------

print "\nTest: new (named args)\n";
print "-" x 60, "\n";

my $r1 = timethese(-3, {
	'Moo'        => sub { Dog::Moo->new(name => 'Rex', sound => 'woof', age => 3, breed => 'Lab') },
	'Mouse'      => sub { Dog::Mouse->new(name => 'Rex', sound => 'woof', age => 3, breed => 'Lab') },
	'Sugar'      => sub { new Dog::Sugar   name => 'Rex', sound => 'woof', age => 3, breed => 'Lab' },
	'Sugar (fn)' => sub { new Dog::SugarFn 'Rex', 'woof', 3, 'Lab' },
});
cmpthese($r1);

print "\nTest: new + get\n";
print "-" x 60, "\n";

my $r2 = timethese(-3, {
	'Moo'   => sub {
		my $d = Dog::Moo->new(name => 'Rex', sound => 'woof', age => 3, breed => 'Lab');
		my $x = $d->name; my $y = $d->sound; my $z = $d->breed;
	},
	'Mouse' => sub {
		my $d = Dog::Mouse->new(name => 'Rex', sound => 'woof', age => 3, breed => 'Lab');
		my $x = $d->name; my $y = $d->sound; my $z = $d->breed;
	},
	'Sugar' => sub {
		my $d = new Dog::Sugar name => 'Rex', sound => 'woof', age => 3, breed => 'Lab';
		my $x = $d->name; my $y = $d->sound; my $z = $d->breed;
	},
	'Sugar (fn)' => sub {
		my $d = new Dog::SugarFn 'Rex', 'woof', 3, 'Lab';
		my $x = name($d);
		my $y = sound($d);
		my $z = breed($d);
	},
});
cmpthese($r2);

print "\nTest: new + set + get\n";
print "-" x 60, "\n";

my $r3 = timethese(-3, {
	'Moo'   => sub {
		my $d = Dog::Moo->new(name => 'Rex', age => 3, breed => 'Lab');
		$d->sound('woof'); my $x = $d->sound;
	},
	'Mouse' => sub {
		my $d = Dog::Mouse->new(name => 'Rex', age => 3, breed => 'Lab');
		$d->sound('woof'); my $x = $d->sound;
	},
	'Sugar' => sub {
		my $d = new Dog::Sugar name => 'Rex', age => 3, breed => 'Lab';
		$d->sound('woof'); my $x = $d->sound;
	},
	'Sugar (fn)' => sub {
		my $d = new Dog::SugarFn 'Rex', 'woof', 3,  'Lab';
		sound($d, 'woof'); my $x = sound($d);
	},
});
cmpthese($r3);

print "\nTest: get/set only (pre-constructed)\n";
print "-" x 60, "\n";

my $moo_obj    = Dog::Moo->new(name => 'Rex', sound => 'woof', age => 3, breed => 'Lab');
my $mouse_obj  = Dog::Mouse->new(name => 'Rex', sound => 'woof', age => 3, breed => 'Lab');
my $sugar_obj  = new Dog::Sugar   name => 'Rex', sound => 'woof', age => 3, breed => 'Lab';
my $sugarfn_obj= new Dog::SugarFn name => 'Rex', sound => 'woof', age => 3, breed => 'Lab';

my $r4 = timethese(-3, {
	'Moo'        => sub { $moo_obj->sound('bark');                    my $x = $moo_obj->sound                    },
	'Mouse'      => sub { $mouse_obj->sound('bark');                  my $x = $mouse_obj->sound                  },
	'Sugar'      => sub { $sugar_obj->sound('bark');                  my $x = $sugar_obj->sound                  },
	'Sugar (fn)' => sub { sound($sugarfn_obj,'bark'); my $x = sound($sugarfn_obj) },
});
cmpthese($r4);

print "\nTest: inherited method call\n";
print "-" x 60, "\n";

my $r5 = timethese(-3, {
	'Moo'        => sub { my $x = $moo_obj->speak    },
	'Mouse'      => sub { my $x = $mouse_obj->speak   },
	'Sugar'      => sub { my $x = $sugar_obj->speak   },
	'Sugar (fn)' => sub { my $x = $sugarfn_obj->speak },
});
cmpthese($r5);
