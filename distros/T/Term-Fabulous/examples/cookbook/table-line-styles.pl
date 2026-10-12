#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# The same small table with the lines of each example.
my @examples = (
	[ 'The default'         => {} ],
	[ 'A grid'              => { border => 'Solid',  row_lines    => 'Solid' } ],
	[ 'No lines'            => { border => 'none',   column_lines => 'none', header_line => 'none' } ],
	[ 'Double, Heavy title' => { border => 'Double', header_line  => 'Heavy' } ],
	[ 'Heavy, Dashed rows'  => { border => 'Heavy',  row_lines    => 'Dashed' } ],
	[ 'Ascii'               => { border => 'Ascii',  column_lines => 'Ascii', header_line  => 'Ascii' } ],
	[ 'Outer block frame'   => { border => 'Outer',  column_lines => 'none',  header_line  => 'none', header_background_color => '#2c3340' } ],
	[ 'Inner block frame'   => { border => 'Inner',  column_lines => 'none',  header_line  => 'none', header_background_color => '#2c3340' } ],
	[ 'Thick, padding 2'    => { border => 'Thick',  column_lines => 'none',  cell_padding => 2 } ],
);

sub example ( $index, $caption, $lines ) {
	my $box = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
	$box->add_child( Term::Fabulous::Widget::Text->new( text => $caption, text_color => '#e5c07b' ) );
	$box->add_child(
		Term::Fabulous::Widget::Table->new(
			id        => "example$index",
			scrollbar => 0,
			columns   => [ { key => 'item', title => 'Item' }, { key => 'qty', title => 'Qty', type => 'number' } ],
			rows      => [ { item => 'Pens', qty => 12 }, { item => 'Ink', qty => 3 } ],
			%$lines,
		)
	);
	return $box;
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# Three examples per line.
foreach my $first ( 0, 3, 6 ) {
	my $line = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 4 } );
	$line->add_child( example( $_, @{ $examples[$_] } ) ) foreach $first .. $first + 2;
	$root->add_child($line);
}

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->run;
