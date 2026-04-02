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
		(new Person 'Alice', 30, 95.5;
	},
	'Object::Proto (XS named)' => sub {
		(new Person name => 'Alice', age => 30, score => 95.5);
	},
	'Object::Proto typed' => sub {
		(new TypedPerson name => 'Alice', age => 30, score => 95.5);
	},
});

cmpthese $r;
print "\n\nTest: Getter (100000 reads)\n";
print "-" x 40, "\n";

my $pure_hash  = PureHash->new(name => 'Bob', age => 25, score => 88.0);
my $pure_array = PureArray->new(name => 'Bob', age => 25, score => 88.0);
my $obj_xs     = new Person name => 'Bob', age => 25, score => 88.0;
my $obj_typed  = new TypedPerson name => 'Bob', age => 25, score => 88.0;

$r = timethese(-2, {
	'Pure Hash' => sub {
		my $x = $pure_hash->name;
	},
	'Pure Array' => sub {
		my $x = $pure_array->name;
	},
	'Object::Proto (XS OO)' => sub {
		my $x = $obj_xs->name;
	},
	'Object::Proto (XS func)' => sub {
		my $x = name($obj_xs);
	},
	'Object::Proto typed' => sub {
		my $x = $obj_typed->name;
	},
});

cmpthese $r;

print "\n\nTest: Setter (100000 writes)\n";
print "-" x 40, "\n";

$r = timethese(-2, {
	'Pure Hash' => sub {
		$pure_hash->name('Alice');
	},
	'Pure Array' => sub {
		$pure_array->name('Alice');
	},
	'Object::Proto (XS OO)' => sub {
		$obj_xs->name('Alice');
	},
	'Object::Proto (XS func)' => sub {
		name($obj_xs, 'Alice');
	},
	'Object::Proto typed' => sub {
		$obj_typed->name('Alice');
	},
});

cmpthese $r;

print "\n\nTest: Mixed get/set (50000 each)\n";
print "-" x 40, "\n";

$r = timethese(-2, {
    'Raw Hash' => sub {
        my $h = { name => 'Alice', age => 30, score => 95.5 };
        $h->{age} = 31;
        my $x = $h->{age};
    },
	'Pure Hash' => sub {
		$pure_hash->age(31);
		my $x = $pure_hash->age;
	},
	'Pure Array' => sub {
		$pure_array->age(31);
		my $x = $pure_array->age;
	},
	'Object::Proto (XS OO)' => sub {
		$obj_xs->age(31);
		my $x = $obj_xs->age;
	},
	'Object::Proto (XS func)' => sub {
		age($obj_xs, 31);
		my $x = age($obj_xs);
	},
	'Object::Proto typed' => sub {
		$obj_typed->age(31);
		my $x = $obj_typed->age;
	},
});

cmpthese $r;

print "\n\nTest: Create + access + destroy cycle (5000 objects)\n";
print "-" x 40, "\n";

$r = timethese(-2, {
	'Pure Hash' => sub {
		my $o = PureHash->new(name => 'Test', age => 20, score => 100);
		$o->name('Changed');
		my $n = $o->name;
		my $a = $o->age;
	},
	'Pure Array' => sub {
		my $o = PureArray->new(name => 'Test', age => 20, score => 100);
		$o->name('Changed');
		my $n = $o->name;
		my $a = $o->age;
	},
	'Object::Proto (XS)' => sub {
		my $o = new Person name => 'Test', age => 20, score => 100;
		$o->name('Changed');
		my $n = $o->name;
		my $a = $o->age;
	},
	'Object::Proto typed' => sub {
		my $o = new TypedPerson name => 'Test', age => 20, score => 100;
		$o->name('Changed');
		my $n = $o->name;
		my $a = $o->age;
	},
});

cmpthese $r;

print "\n\nTest: Multiple attribute access (all 3 attrs x 10000)\n";
print "-" x 40, "\n";

$r = timethese(-2, {
	'Pure Hash' => sub {
		my $n = $pure_hash->name;
		my $a = $pure_hash->age;
		my $s = $pure_hash->score;
	},
	'Pure Array' => sub {
		my $n = $pure_array->name;
		my $a = $pure_array->age;
		my $s = $pure_array->score;
	},
	'Object::Proto (XS OO)' => sub {
		my $n = $obj_xs->name;
		my $a = $obj_xs->age;
		my $s = $obj_xs->score;
	},
	'Object::Proto (XS func)' => sub {
		my $n = name($obj_xs);
		my $a = age($obj_xs);
		my $s = score($obj_xs);
	},
	'Object::Proto typed' => sub {
		my $n = $obj_typed->name;
		my $a = $obj_typed->age;
		my $s = $obj_typed->score;
	},
});

cmpthese $r;

print "\n", "=" x 60, "\n";
print "Summary:\n";
print "- Pure Hash: Standard blessed hashref (baseline)\n";
print "- Pure Array: Blessed arrayref with constants (faster baseline)\n";
print "- Object::Proto (XS OO): XS with custom ops, OO style (\$obj->name)\n";
print "- Object::Proto (XS func): XS with custom ops, function style (name \$obj)\n";
print "- Object::Proto typed: XS with inline type checking (Str, Int, Num)\n";
print "=" x 60, "\n";
