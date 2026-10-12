#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Time::HiRes ();

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# The last minute: the x axis always spans 60 seconds up to the newest
# point, and each series keeps at most 240 points.
my $chart = Term::Fabulous::Widget::LineChart->new(
	title      => 'Network traffic',
	x_axis     => { type => 'time', span => 60, format => '%H:%M:%S' },
	y_axis     => { min  => 0, title => 'Mbit/s' },
	max_points => 240,
	series     => [ { name => 'Received', type => 'area', line => 1 }, { name => 'Sent' } ],
);
my $status = Term::Fabulous::Widget::Text->new( text => 'Waiting for data', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( $chart, $status );

# Made-up measurements, four per second.
my $tick = 0;

sub measure () {
	$tick++;
	return ( 65 + 20 * sin( $tick / 23 ) + 8 * sin( $tick / 3.1 ) + 4 * sin( $tick * 1.7 ), 18 + 6 * sin( $tick / 11 ) + 3 * sin( $tick * 2.3 ) );
}

my $timer = IO::Async::Timer::Periodic->new(
	interval => 0.25,
	on_tick  => sub {
		my ( $received, $sent ) = measure();

		# One point for each series, both at this moment.
		$chart->append( Time::HiRes::time(), { Received => $received, Sent => $sent } );
		$status->text( sprintf 'Now: %.1f Mbit/s in, %.1f Mbit/s out', $received, $sent );
		return;
	},
);
$timer->start;
IO::Async::Loop->new->add($timer);

Term::Fabulous->new( root => $root, width => 80, height => 22 )->run;
