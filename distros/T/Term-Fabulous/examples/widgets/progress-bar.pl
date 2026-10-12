#!/usr/bin/env perl

# Term::Fabulous::Widget::ProgressBar in its forms: a block bar with its
# percentage, one with the percentage inside, a thin line bar with a
# label of its own, a striped bar whose stripes move, a bar of three
# colored segments, an indeterminate bar with its runner, and a two-row
# ASCII bar. The bars fill up from a timer; Ctrl+C quits.
#
#     perl examples/widgets/progress-bar.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ProgressBar;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# A row: the name of the form, then the bar showing it.
sub state_row ( $state, $widget ) {
	my $label = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label->add_child( Term::Fabulous::Widget::Text->new( text => $state, text_color => [ 150, 160, 180, 255 ] ) );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2, sizing => { width => sizing_grow() } } );
	$row->add_child( $label, $widget );
	$root->add_child($row);
	return $widget;
}

my $grow    = { sizing => { width => sizing_grow() } };
my @filling = (
	state_row( 'block',  Term::Fabulous::Widget::ProgressBar->new( value => 42, layout => $grow ) ),
	state_row( 'inside', Term::Fabulous::Widget::ProgressBar->new( value => 42, value_position => 'inside', layout => $grow ) ),
	state_row(
		'line',
		Term::Fabulous::Widget::ProgressBar->new(
			max => 2048, value => 860, style => 'line', color => [ 152, 195, 121, 255 ], value_format => sub ( $kb, $fraction ) { sprintf '%d of %d KB', $kb, 2048 }, layout => $grow
		)
	),
	state_row( 'striped', Term::Fabulous::Widget::ProgressBar->new( value => 65, striped => 1, animated => 1, color => [ 229, 192, 123, 255 ], layout => $grow ) ),
);
state_row(
	'segments',
	Term::Fabulous::Widget::ProgressBar->new(
		max          => 500,
		segments     => [ { value => 210, color => [ 152, 195, 121, 255 ] }, { value => 90, color => [ 229, 192, 123, 255 ] }, { value => 40, color => [ 224, 108, 117, 255 ] } ],
		separated    => 1,
		value_format => sub ( $gb, $fraction ) { sprintf '%d of 500 GB', $gb },
		layout       => $grow,
	)
);
state_row( 'indeterminate', Term::Fabulous::Widget::ProgressBar->new( indeterminate => 1, layout => $grow ) );
state_row(
	'ascii, 2 rows',
	Term::Fabulous::Widget::ProgressBar->new( value => 42, style => 'ascii', value_position => 'left', layout => { sizing => { width => sizing_grow(), height => sizing_fixed(2) } } )
);

# The bars fill up a little every tenth of a second and start over.
my $timer = IO::Async::Timer::Periodic->new(
	interval => 0.1,
	on_tick  => sub {
		foreach my $bar (@filling) {
			my $next = $bar->value + ( $bar->max - $bar->min ) / 100;
			$bar->value( $next > $bar->max ? $bar->min : $next );
		}
		return;
	},
);
$timer->start;
IO::Async::Loop->new->add($timer);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->run;
