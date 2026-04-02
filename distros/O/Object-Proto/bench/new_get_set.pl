#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:all);

use Object::Proto;

# Define classes in BEGIN so call checkers work
BEGIN {
	# Object::Proto (XS) - no types
	Object::Proto::define('Person', qw(name age score));

	# Object::Proto (XS) - with types
	Object::Proto::define('TypedPerson', 'name:Str', 'age:Int', 'score:Num');

	# Import function-style accessors
	Object::Proto::import_accessors('Person');
}

print "=" x 60, "\n";
print "Object Benchmark: Object::Proto (XS) vs Pure Perl OO\n";
print "=" x 60, "\n\n";

# Pure Perl hashref-based OO (baseline)
package PureHash {
	sub new {
		my ($class, %args) = @_;
		return bless { name => $args{name}, age => $args{age}, score => $args{score} }, $class;
	}
	sub name  { @_ > 1 ? $_[0]->{name}  = $_[1] : $_[0]->{name}  }
	sub age   { @_ > 1 ? $_[0]->{age}   = $_[1] : $_[0]->{age}   }
	sub score { @_ > 1 ? $_[0]->{score} = $_[1] : $_[0]->{score} }
}

# Pure Perl arrayref-based OO (faster than hash)
package PureArray {
	use constant { NAME => 0, AGE => 1, SCORE => 2 };
	sub new {
		my ($class, %args) = @_;
		return bless [ $args{name}, $args{age}, $args{score} ], $class;
	}
	sub name  { @_ > 1 ? $_[0]->[NAME]  = $_[1] : $_[0]->[NAME]  }
	sub age   { @_ > 1 ? $_[0]->[AGE]   = $_[1] : $_[0]->[AGE]   }
	sub score { @_ > 1 ? $_[0]->[SCORE] = $_[1] : $_[0]->[SCORE] }
}

package main;

print "\n\nTest: Mixed new->set->get (5 seconds)\n";
print "-" x 40, "\n";

my $r = timethese(-5, {
	'Raw Hash' => sub {
		my %hh = ( name => 'Alice', age => 30, score => 95.5 );
		$hh{age} = 31;
		my $x = $hh{age};
	},
	'Raw Hash Ref' => sub {
		my $h = { name => 'Alice', age => 30, score => 95.5 };
		$h->{age} = 31;
		my $x = $h->{age};
	},
	'Pure Hash' => sub {
		my $pure_hash  = PureHash->new(name => 'Bob', age => 25, score => 88.0);
		$pure_hash->age(31);
		my $x = $pure_hash->age;
	},
	'Pure Array' => sub {
		my $pure_array = PureArray->new(name => 'Bob', age => 25, score => 88.0);
		$pure_array->age(31);
		my $x = $pure_array->age;
	},
	'Object::Proto (XS OO)' => sub {
		my $obj_xs = new Person name => 'Bob', age => 25, score => 88.0;
		$obj_xs->age(31);
		my $x = $obj_xs->age;
	},
	'Object::Proto (XS func)' => sub {
		my $obj_xs = new Person 'Bob', 25, 88.0;
		age($obj_xs, 31);
		my $x = age($obj_xs);
	},
	'Object::Proto typed' => sub {
		my $obj_typed  = new TypedPerson 'Bob', 25, 88.0;
		age $obj_typed, 31;
		my $x = age $obj_typed;
	},
});

cmpthese $r;
