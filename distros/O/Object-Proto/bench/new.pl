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

print "Test: Object construction (10000 objects)\n";
print "-" x 40, "\n";

my $r = timethese(-2, {
	'Raw Hash' => sub {
		my $h = { name => 'Alice', age => 30, score => 95.5 }
	},
	'Pure Hash OO' => sub {
		PureHash->new(name => 'Alice', age => 30, score => 95.5)
	},
	'Object::Proto (XS)' => sub {
		(new Person 'Alice', 30, 95.5);
	},
	'Object::Proto (XS named)' => sub {
		(new Person name => 'Alice', age => 30, score => 95.5);
	},
	'Object::Proto typed' => sub {
		(new TypedPerson name => 'Alice', age => 30, score => 95.5);
	},
});

cmpthese $r;
