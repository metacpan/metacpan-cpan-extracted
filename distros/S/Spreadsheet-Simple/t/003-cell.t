#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN { use_ok "Spreadsheet::Simple::Cell" }

my $cell;
lives_ok {
	$cell = Spreadsheet::Simple::Cell->new(
		value => 'foo'
	);
} 'construct cell';

ok($cell, 'constructed cell');
isa_ok($cell, 'Spreadsheet::Simple::Cell');

is($cell->value, 'foo');

dies_ok {
	$cell->value({});
} 'cells cannot contain hashrefs';

lives_ok {
	$cell->value('bar');
} 'cells can contain strings';

my $cell2 = Spreadsheet::Simple::Cell->new(
	value => 'bar',
	color => [0xff, 0xff, 0xff],
);
isa_ok($cell2, 'Spreadsheet::Simple::Cell');

is_deeply($cell2->color, [255, 255, 255], 'check rgb value');

