#!/usr/bin/perl -w
use strict;
use Object::Releaser;
use Test;
BEGIN { plan tests => 6 };

# debugging tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# variables
my ($object, $releaser);

# test release of all object properties
$object = {a=>1, b=>2, c=>3};
$releaser = Object::Releaser->new($object);
undef $releaser;

# object should have no properties
if (keys %$object)
	{ ok 0 }
else
	{ ok 1 }


# test release of just specific properties
$object = {a=>1, b=>2, c=>3};
$releaser = Object::Releaser->new($object);
$releaser->set_keys(qw{a b});
undef $releaser;

# object should have only c property
if ( (keys(%$object) == 1) && ($object->{'c'}) )
	{ ok 1 }
else
	{ ok 0 }

# test dismissal of releaser object using dismiss with no arguments
$object = {a=>1, b=>2, c=>3};
$releaser = Object::Releaser->new($object);
$releaser->dismiss();
undef $releaser;

# object should have all properties
if ( (keys(%$object) == 3) && ($object->{'a'}) && ($object->{'b'}) && ($object->{'c'}) )
	{ ok 1 }
else
	{ ok 0 }


# test dismissal of releaser object using dismiss with one true argument
$object = {a=>1, b=>2, c=>3};
$releaser = Object::Releaser->new($object);
$releaser->dismiss(1);
undef $releaser;

# object should have all properties
if ( (keys(%$object) == 3) && ($object->{'a'}) && ($object->{'b'}) && ($object->{'c'}) )
	{ ok 1 }
else
	{ ok 0 }


# test dismissal of releaser object using dismiss with one false argument
$object = {a=>1, b=>2, c=>3};
$releaser = Object::Releaser->new($object);
$releaser->dismiss(0);
undef $releaser;

# object should have no properties
if (keys %$object)
	{ ok 0 }
else
	{ ok 1 }


# test removing specific keys to release using delete_all
$object = {a=>1, b=>2, c=>3};
$releaser = Object::Releaser->new($object);
$releaser->set_keys(qw{a b});
$releaser->delete_all();
undef $releaser;

# object should have no properties
if (keys %$object)
	{ ok 0 }
else
	{ ok 1 }
