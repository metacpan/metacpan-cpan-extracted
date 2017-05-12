#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

package Person;
use Moose;
with 'MooseX::Role::Matcher' => { default_match => 'name' };

has name  => (is => 'ro', isa => 'Str');
has age   => (is => 'ro', isa => 'Num');
has phone => (is => 'ro', isa => 'Str');

package main;
my @people = (
    Person->new(name => 'James', age => 22, phone => '555-1914'),
    Person->new(name => 'Jesse', age => 22, phone => '555-6287'),
    Person->new(name => 'Eric',  age => 21, phone => '555-7634'),
);

# is James 22?
ok($people[0]->match(age => 22), "James is 22");

# which people are not 22?
is_deeply([Person->grep_matches([@people], '!age' => 22)],
          [$people[2]], "Eric is not 22");

# do any of the 22-year-olds have a phone number ending in 4?
ok(Person->any_match([@people], age => 22, phone => qr/4$/),
   "James is 22 and has a phone number ending in 4");

# does everyone's name start with either J or E?
ok(Person->all_match([@people], name => [qr/^J/, qr/^E/]),
   "everyone's name starts with either J or E");

# find the first person whose name is 4 characters long (using the
# default_match of name)
is(Person->first_match([@people], sub { length == 4 }), $people[2],
   "Eric is the first person whose name is 4 characters long");
