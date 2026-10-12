#!/usr/bin/env perl

use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use POSIX qw(strftime);
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# Hourly temperatures: measured until noon on June 3rd, forecast from
# then on. The x values are date strings (local time; a trailing Z means
# UTC); epoch seconds or DateTime objects work as well.
my $now = '2026-06-03 12:00Z';
my ( @measured, @forecast );
foreach my $hour ( 0 .. 4 * 24 ) {
	my $time  = strftime( '%Y-%m-%d %H:%MZ', gmtime( 1780272000 + 3600 * $hour ) );
	my $value = 17 + 6 * sin( ( $hour - 9 ) * 3.14159 / 12 ) + 2 * sin( $hour / 17 );
	push @measured, [ $time, $value ] if $hour <= 2 * 24 + 12;
	push @forecast, [ $time, $value + 1.5 * ( $hour - 2 * 24 - 12 ) / 36 ] if $hour >= 2 * 24 + 12;    # drifts away from the measurements
}

my $chart = Term::Fabulous::Widget::LineChart->new(
	title  => 'Temperature in Lisbon',
	curve  => 'monotone',
	x_axis => { type  => 'time', utc    => 1, min => '2026-06-01 00:00Z', max => '2026-06-05 00:00Z' },
	y_axis => { title => '°C',   format => '%d°' },
	series => [
		{ name => 'Measured', data => \@measured },
		{ name => 'Forecast', data => \@forecast, line_style => 'dashed' },

		# The same data, drawn only from the start of the 2nd to noon of the 3rd.
		{ name => 'Heat warning', data => \@measured, type => 'area', from => '2026-06-02 00:00Z', to => $now, fill_opacity => 0.25, color => '#e66767' },
	],
);
$root->add_child($chart);

Term::Fabulous->new( root => $root, width => 90, height => 24 )->run;
