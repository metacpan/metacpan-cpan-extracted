#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my @teams = qw(Backend Frontend Mobile);
my $chart = Term::Fabulous::Widget::AreaChart->new(
	title   => 'Closed issues per week',
	labels  => [ map { "W$_" } 1 .. 12 ],
	stacked => 1,
	series  => [
		{ name => 'Backend',  data => [ 12, 15, 11, 18, 21, 17, 16, 22, 25, 19, 23, 27 ] },
		{ name => 'Frontend', data => [ 8,  9,  12, 10, 13, 15, 14, 12, 16, 18, 17, 20 ] },
		{ name => 'Mobile',   data => [ 5,  4,  6,  9,  7,  8,  11, 10, 9,  12, 14, 13 ] },
	],
);
my $status = Term::Fabulous::Widget::Text->new( text => 'Point at the chart, or press 1-3 to emphasize a team (0: none, q: quit).', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( $chart, $status );

# What the pointer is on: a point of a series, a legend entry, or nothing.
$chart->on(
	SeriesHover => sub ($event) {
		my $series = $event->series;
		$status->text(
			  !defined $series       ? 'Point at the chart, or press 1-3 to emphasize a team (0: none, q: quit).'
			: !defined $event->index ? "$series: " . join( ', ', map { $_ // 0 } $chart->series($series)->{data}->@* )
			:                          sprintf( '%s closed %d issues in week %s', $series, $event->value, $event->label )
		);
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# Emphasis from the program, as if the pointer were on the series.
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		$ui->loop->stop if $key eq 'q';
		$chart->highlight( $key eq '0' ? undef : $teams[ $key - 1 ] ) if $key =~ /\A[0-3]\z/;
		return;
	}
);

$ui->run;
