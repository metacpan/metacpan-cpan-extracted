#!/usr/bin/env perl

# Term::Fabulous::Widget::Button: buttons that take the focus (shown by
# the border color), react to clicks and to Enter or Space, and swap
# their colors while the mouse button is held on them. The Archive
# button is disabled: it is drawn gray, Tab skips it and clicks do
# nothing. Tab moves the focus, Ctrl+C quits.
#
#     perl examples/widgets/button.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
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

my $status = Term::Fabulous::Widget::Text->new( text => 'Nothing pressed yet.', text_color => [ 150, 160, 180, 255 ] );

sub button ( $caption, $background, $border ) {
	my $button = Term::Fabulous::Widget::Button->new(
		background_color => $background,
		bordered         => 1,
		border_color     => $border,
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
		layout           => { padding => { left => 1, right => 1 } },
	);
	$button->add_child( Term::Fabulous::Widget::Text->new( text => $caption, text_color => [ 255, 255, 255, 255 ] ) );
	$button->on( Activate => sub ($event) { $status->text("$caption was pressed."); return } );
	return $button;
}

my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
my $save    = button( 'Save',    [ 40, 60, 90, 255 ], [ 90, 110, 140, 255 ] );
my $archive = button( 'Archive', [ 40, 60, 90, 255 ], [ 90, 110, 140, 255 ] );
$archive->disabled(1);
$buttons->add_child( $save, button( 'Cancel', [ 40, 60, 90, 255 ], [ 90, 110, 140, 255 ] ), button( 'Delete', [ 110, 40, 45, 255 ], [ 170, 80, 85, 255 ] ), $archive );
$root->add_child( $buttons, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($save);
$ui->run;
