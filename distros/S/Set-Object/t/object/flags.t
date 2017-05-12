#!/usr/bin/perl -w
#
#  check that objects retain things like overloading after going in
#  and out of Set::Object containers
#

use strict;

use Set::Object;

require 't/object/Person.pm';
require 't/object/Saint.pm';

print "1..2\n";

my $person = new Person( firstname => "Montgomery", name => "Burns" );

my $set = Set::Object->new($person);

my ($newperson) = $set->members();

if ($newperson ne "Montgomery Burns") {
    print "not ";
}
print "ok 1\n";

my $saint = Saint->new( firstname => "Timothy", name => "Leary" );

$set = Set::Object->new($saint);

my ($newsaint) = $set->members();

if ($newsaint ne "Saint Timothy Leary") {
    print "not ";
}

print "ok 2\n";


