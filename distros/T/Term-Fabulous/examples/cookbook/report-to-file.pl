#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow sizing_fit CLAY_TOP_TO_BOTTOM);

my %sales = ( 'North' => 1250, 'South' => 980, 'East' => 1530 );

my $report = Term::Fabulous::Widget::Box->new(
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	border_color => [ 120, 180, 240, 255 ],
	layout       => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_fit() },
		padding          => { left  => 1,             right  => 1 },
	},
);
$report->add_child( Term::Fabulous::Widget::Text->new( text => 'Sales per region (in EUR)', text_color => [ 255, 200, 80, 255 ] ) );
foreach my $region ( sort keys %sales ) {
	my $line = sprintf '%-8s %6d', $region, $sales{$region};
	$report->add_child( Term::Fabulous::Widget::Text->new( text => $line, text_color => [ 230, 230, 230, 255 ] ) );
}

my $page = Term::Fabulous::Static->new( root => $report, width => 40 );

# To the terminal or a pipe: colors only when STDOUT is a terminal.
$page->print;

# To a file, always without colors. print() encodes the text as UTF-8
# itself, so open the file without an encoding layer.
open my $file, '>', 'report.txt' or die "Cannot write report.txt: $!";
$page->print( fh => $file, colors => 0 );
close $file;

# As a string, for example for an e-mail body (a character string).
my $text = $page->render_string( colors => 0 );
