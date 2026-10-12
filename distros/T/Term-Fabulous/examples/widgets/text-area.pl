#!/usr/bin/env perl

# Term::Fabulous::Widget::TextArea: multi-line text that wraps at word
# boundaries, with a scrollbar once the text is taller than the area.
# Type, select with Shift and the arrow keys, undo with Ctrl+Z; Ctrl+C
# quits.
#
#     perl examples/widgets/text-area.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $notes = Term::Fabulous::Widget::TextArea->new(
	placeholder => 'Notes',
	value       => join(
		"\n",
		'Shopping list for the weekend:',
		'- bread, butter and a big wheel of cheese for the party on Saturday evening',
		'- coffee',
		'- apples',
		'- birthday card for Ada',
		'- batteries for the remote'
	),
	layout => { sizing => { width => sizing_grow(), height => sizing_fixed(6) } },
);
my $status = Term::Fabulous::Widget::Text->new( text => 'Long lines wrap at spaces; the scrollbar shows the position.', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( $notes, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($notes);
$ui->run;
