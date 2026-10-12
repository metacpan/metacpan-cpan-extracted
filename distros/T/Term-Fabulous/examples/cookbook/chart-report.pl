#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Sparkline;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my %disk = ( '/' => 71, '/home' => 88, '/var' => 46, '/srv' => 23 );
my @load = ( 0.4, 0.6, 0.5, 0.9, 1.4, 2.1, 1.8, 1.2, 0.9, 1.1, 1.6, 1.3, 0.8, 0.7, 0.6, 0.9, 1.0, 0.8 );

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() }, child_gap => 1 } );

# A chart in a report needs a fixed height: there is no screen to fill.
$root->add_child(
	Term::Fabulous::Widget::BarChart->new(
		title        => 'Disk usage (%)',
		horizontal   => 1,
		value_labels => 1,
		labels       => [ sort keys %disk ],
		y_axis       => { min => 0, max => 100 },
		series       => [ { name => 'used', data => [ map { $disk{$_} } sort keys %disk ] } ],
		layout       => { sizing => { width => sizing_grow(), height => sizing_fixed(9) } },
	)
);

# Text is black unless it has a text_color, which a dark terminal does
# not show: give it a color, as the chart does for its labels.
my $line = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
$line->add_child(
	Term::Fabulous::Widget::Text->new( text => 'Load, last 18 hours:', text_color => [ 230, 230, 230, 255 ] ),
	Term::Fabulous::Widget::Sparkline->new( type => 'bar', values => \@load, layout => { sizing => { width => sizing_fixed(18) } } ),
	Term::Fabulous::Widget::Text->new( text => sprintf( 'now %.1f', $load[-1] ), text_color => [ 230, 230, 230, 255 ] ),
);
$root->add_child($line);

# Colors on a terminal, plain characters in a pipe or file.
Term::Fabulous::Static->new( root => $root, width => 60 )->print;
