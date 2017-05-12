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

package Local::Test::SetOfPointPairs;

use v5.012;
use strict;
use warnings;

use Moose;

with 'MooseX::Role::JSONObject';

has 'pairs' => (
	is => 'rw',
	isa => 'HashRef[ArrayRef[Local::Test::Point]]',
	required => 1,
);

package Local::Test::Polygon;

use v5.012;
use strict;
use warnings;

use Moose;
use Method::Signatures;

with 'MooseX::Role::JSONObject';

has 'points' => (
	is => 'rw',
	isa => 'ArrayRef[Local::Test::Point]',
	required => 1,
);

method stuff_pairs()
{
	my @pts = @{$self->points};
	return Local::Test::SetOfPointPairs->new(pairs => {
	    map {
		($_, [$pts[$_], $pts[($_ + 1) % scalar @pts]])
	    } (0..$#pts)
	});
}

package main;

use Test::More 0.98 tests => 8;

my $p_start = Local::Test::Point->new(x => 0, y => 0, label => 'Origin');

ok defined $p_start, 'the role is instantiable';
my $jp_start = $p_start->to_json;
is_deeply $jp_start, { x => 0, y => 0, label => 'Origin' },
    'to_json - trivial object';

my $p_end = Local::Test::Point->new(x => 0, y => 1, label => undef);
my $jp_end = $p_end->to_json;
is_deeply $jp_end, { x => 0, y => 1, label => undef },
    'to_json - maybe';

my $line = Local::Test::LineSegment->new(
    start => $p_start,
    end => $p_end,
    label => 'Up');
ok defined $line, 'the role is instantiable again';
my $jline = $line->to_json;
is_deeply $jline, { start => $jp_start, end => $jp_end, label => 'Up' },
    'to_json - recurse into an object';

my $line2 = Local::Test::LineSegment->new(
    start => $p_start,
    end => $p_end);
my $jline2 = $line2->to_json;
is_deeply $jline2, { start => $jp_start, end => $jp_end },
    'to_json - non-required attributes';

my $p_third = Local::Test::Point->new(x => 1, y => 1, label => undef);
my $jp_third = $p_third->to_json;
my $poly = Local::Test::Polygon->new(
    points => [
	$p_start,
	$p_end,
	$p_third,
    ]
);
my $jpoly = $poly->to_json;
is_deeply $jpoly, { points => [ $jp_start, $jp_end, $jp_third ] },
    'to_json - ArrayRef';

my $set = $poly->stuff_pairs;
my $jset = $set->to_json;
is_deeply $set->to_json, {
    pairs => {
	0 => [ $jp_start, $jp_end ],
	1 => [ $jp_end, $jp_third ],
	2 => [ $jp_third, $jp_start ],
    },
};
