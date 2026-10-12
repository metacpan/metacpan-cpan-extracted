#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use POSIX qw(strftime);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

use constant MAX_LINES => 500;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);

# A ScrollBox needs an id: Clay keeps the scroll position by id.
my $log = Term::Fabulous::Widget::ScrollBox->new(
	id               => 'log',
	background_color => [ 30, 35, 50, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);
$root->add_child($log);

my $count = 0;
my $timer = IO::Async::Timer::Periodic->new(
	interval => 0.5,
	on_tick  => sub {
		$count++;
		$log->add_child(
			Term::Fabulous::Widget::Text->new(
				text       => strftime( '%H:%M:%S', localtime ) . " event number $count",
				text_color => [ 200, 210, 230, 255 ],
			)
		);

		# Keep the log from growing forever: drop the oldest line.
		my $oldest = $log->children->[0];
		$log->remove_child($oldest) if @{ $log->children } > MAX_LINES;
		return;
	},
);
$timer->start;
IO::Async::Loop->new->add($timer);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
