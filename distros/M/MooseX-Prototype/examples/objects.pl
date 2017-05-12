# Based on http://www.javascriptkit.com/javatutors/oopjs.shtml
#

use 5.010;
use strict;
use warnings;
use lib '../lib';

use MooseX::Prototype;
use Data::Dumper;

# Creating objects using new Object()

my $person = object { };
$person->extend( name => undef, height => undef );
$person->name("Tim Scarfe");
$person->height("6Ft");

$person->extend( state => undef, speed => undef );
$person->extend( run => sub {
	$_[0]->state("running");
	$_[0]->speed("4ms^-1");
} );

print Dumper($person);

# Creating objects using Literal Notation

my $timObject = object {
	property1 => "Hello",
	property2 => "MmmMMm",
	property3 => ["mmm", 2, 3, 6, "kkk"],
	method1   => sub { say "Method had been called", $_[0]->property1 },
};

$timObject->method1;
say $timObject->property3->[2];  #// will yield 3


my $circle = object { x => 0, y => 0, radius => 2 }; #// another example

#// nesting is no problem.
my $rectangle = object {
	upperLeft  => object { x => 2, y => 2 },
	lowerRight => object { x => 4, y => 4 },
};

say $rectangle->upperLeft->x;  #// will yield 2


# http://www.javascriptkit.com/javatutors/oopjs2.shtml
#

my $Cat = object {
	name     => undef,
	'&talk'  => sub {
		say $_[0]->name, " say meeow!";
	},
};

my $cat1 = $Cat->new(name => "felix");
$cat1->talk;  # "felix says meeow!"

my $cat2 = $Cat->new(name => "ginger");
$cat2->talk;  # "ginger says meeow!"

# Adding methods to our object using prototype
# (In Moose, we use meta instead)
$Cat->meta->add_method(changeName => sub { $_[0]->name($_[1]) });

my $firstCat = $Cat->new(name => "pursur");
$firstCat->changeName("Bill");
$firstCat->talk;

