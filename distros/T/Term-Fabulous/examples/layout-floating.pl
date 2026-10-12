#!/usr/bin/env perl

# Floating widgets: a menu attached below a button, a badge on the
# corner of a panel and a message in the bottom row of the screen. They
# are drawn on top of the other widgets and take no space in the layout.
# The File button (click it, or Tab and Enter) opens and closes the
# menu. Ctrl+C quits.
#
#     perl examples/layout-floating.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(
	Clay_GetElementId sizing_grow CLAY_TOP_TO_BOTTOM
	CLAY_ATTACH_TO_PARENT CLAY_ATTACH_TO_ROOT CLAY_ATTACH_TO_ELEMENT_WITH_ID
	CLAY_ATTACH_POINT_LEFT_TOP CLAY_ATTACH_POINT_LEFT_BOTTOM CLAY_ATTACH_POINT_RIGHT_TOP CLAY_ATTACH_POINT_RIGHT_BOTTOM
);

sub text ( $content, $color = [ 220, 220, 220, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $content, text_color => $color );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $toolbar = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
my $file    = Term::Fabulous::Widget::Button->new(
	id               => 'file-button',
	background_color => [ 60, 68, 92, 255 ],
	layout           => { padding => { left => 1, right => 1 } },
);
$file->add_child( text('File') );
my $edit = Term::Fabulous::Widget::Button->new( background_color => [ 60, 68, 92, 255 ], layout => { padding => { left => 1, right => 1 } } );
$edit->add_child( text('Edit') );
$toolbar->add_child( $file, $edit );

# A panel in the normal layout, with a badge floating over its top
# right corner: attached to its parent, the panel.
my $panel = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
	background_color => [ 30, 35, 50, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
);
$panel->add_child( text( "Line $_ of the document", [ 150, 160, 180, 255 ] ) ) foreach 1 .. 6;

my $badge = Term::Fabulous::Widget::Box->new(
	background_color => [ 224, 108, 117, 255 ],
	layout           => { padding => { left => 1, right => 1 } },
	floating         => {
		attach_to     => CLAY_ATTACH_TO_PARENT,
		attach_points => { element => CLAY_ATTACH_POINT_RIGHT_TOP, parent => CLAY_ATTACH_POINT_RIGHT_TOP },
		offset        => { x       => -2,                          y      => 0 },
	},
);
$badge->add_child( text( '3 changes', [ 20, 25, 35, 255 ] ) );
$panel->add_child($badge);

# A message attached to the root: in the bottom row of the screen, two
# cells from its right edge.
my $message = Term::Fabulous::Widget::Box->new(
	background_color => [ 152, 195, 121, 255 ],
	layout           => { padding => { left => 1, right => 1 } },
	floating         => {
		attach_to     => CLAY_ATTACH_TO_ROOT,
		attach_points => { element => CLAY_ATTACH_POINT_RIGHT_BOTTOM, parent => CLAY_ATTACH_POINT_RIGHT_BOTTOM },
		offset        => { x       => -2,                             y      => 0 },
	},
);
$message->add_child( text( 'Saved 09:41', [ 20, 25, 35, 255 ] ) );

# The menu: attached to the File button by its id, its top left corner
# on the button's bottom left corner, above everything else.
my $menu = Term::Fabulous::Widget::Box->new(
	id     => 'file-menu',
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		padding          => { left => 1, right => 1 },
	},
	background_color => [ 40, 46, 64, 255 ],
	bordered         => 1,
	border_color     => [ 229, 192, 123, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Solid,
	floating         => {
		attach_to     => CLAY_ATTACH_TO_ELEMENT_WITH_ID,
		parent_id     => Clay_GetElementId('file-button')->{id},
		attach_points => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_LEFT_BOTTOM },
		z_index       => 10,
	},
);
$menu->add_child( map { text($_) } 'New', 'Open...', 'Save', 'Quit' );

$root->add_child( $toolbar, $panel, $message, $menu );

$file->on(
	Activate => sub ($event) {
		if ( $root->has_child($menu) ) {
			$root->remove_child($menu);
		}
		else {
			$root->add_child($menu);
		}
		return;
	}
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
