#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(number);
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# Colors separate the titles and the rows; a block frame encloses them.
my $table = Term::Fabulous::Widget::Table->new(
	id                      => 'planets',
	selection               => 'single',
	border                  => 'Outer',
	column_lines            => 'none',
	header_line             => 'none',
	line_color              => '#4b5568',
	header_background_color => '#2c3340',
	header_text_color       => '#e5c07b',
	stripe_color            => '#1c2029',
	selected_color          => '#2d4f75',
	cell_padding            => 2,
	columns                 => [
		{ key => 'name',   title => 'Planet' },
		{ key => 'moons',  title => 'Moons',       type => 'number' },
		{ key => 'radius', title => 'Radius (km)', type => 'number', mutator => number( decimals => 0 ) },
		{ key => 'day',    title => 'Day (hours)', type => 'number', mutator => number( decimals => 1 ) },
	],
	rows => [
		{ name => 'Mercury', moons => 0,   radius => 2439.7,  day => 4222.6 },
		{ name => 'Venus',   moons => 0,   radius => 6051.8,  day => 2802.0 },
		{ name => 'Earth',   moons => 1,   radius => 6371.0,  day => 24.0 },
		{ name => 'Mars',    moons => 2,   radius => 3389.5,  day => 24.7 },
		{ name => 'Jupiter', moons => 95,  radius => 69911.0, day => 9.9 },
		{ name => 'Saturn',  moons => 146, radius => 58232.0, day => 10.7 },
	],
);
$root->add_child($table);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
