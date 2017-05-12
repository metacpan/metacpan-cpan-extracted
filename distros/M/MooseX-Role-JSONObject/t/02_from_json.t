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
);

has y => (
	is =>	'rw',
	isa =>	'Num',
	required => 1,
);

has label => (
	is => 	'rw',
	isa => 	'Maybe[Str]',
	required => 1,
);

package Local::Test::LineSegment;

use v5.012;
use strict;
use warnings;

use Moose;

with 'MooseX::Role::JSONObject';

has 'start' => (
	'is' => 'rw',
	'isa' => 'Local::Test::Point',
	'required' => 1,
);

has 'end' => (
	'is' => 'rw',
	'isa' => 'Local::Test::Point',
	'required' => 1,
);

has 'label' => (
	'is' => 'rw',
	'isa' => 'Str',
	'required' => 0,
);

package main;

use Test::More 0.98 tests => 4;

my $h = {
	x => 1,
	y => 2,
	label => 'A',
};

my $p = Local::Test::Point->from_json($h);
ok defined $p, 'from_json - object created';
ok $p->x == $h->{x} && $p->y == $h->{y} && $p->label eq $h->{label},
    'from_json - object created correctly';

my $l = {
	start => {
		x => 2,
		y => 3,
		label => 'B',
	},
	end => {
		x => 3,
		y => 2,
		label => 'C',
	},
	label => 'a',
};
my $line = Local::Test::LineSegment->from_json($l);
ok defined $line, 'from_json - recursive creation';
ok $line->start->x == $l->{start}->{x} &&
    $line->end->y == $l->{end}->{y} &&
    $line->label eq $l->{label},
    'from_json - recursive creation correct';
