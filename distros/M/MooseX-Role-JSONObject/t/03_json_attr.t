#!/usr/bin/perl

use v5.012;
use strict;
use warnings;

package Local::Test::Point;

use v5.012;
use strict;
use warnings;

use Moose;

with 'MooseX::Role::JSONObject';

has x => (
	is => 	'rw',
	isa =>	'Num',
	required => 1,
	traits => ['MooseX::Role::JSONObject::Meta::Trait'],
	json_attr => 'width',
);

has y => (
	is =>	'rw',
	isa =>	'Num',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'height',
);

has label => (
	is => 	'rw',
	isa => 	'Maybe[Str]',
	required => 1,
);

package main;

use Test::More 0.98 tests => 4;

my $h = {
	width => 1,
	height => 2,
	label => 'A',
};

my $p = Local::Test::Point->from_json($h);
ok defined $p, 'from_json/attr - object created';
ok $p->x == $h->{width} && $p->y == $h->{height} && $p->label eq $h->{label},
    'from_json/attr - object created correctly';

my $back = $p->to_json;
ok defined $back, 'to_json/attr - hash created';
is_deeply $back, $h, 'to_json/attr - hash is the same';
