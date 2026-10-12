#!/usr/bin/env perl

# Term::Fabulous::Widget::Dialog: a dialog that opens over the screen,
# centered, behind a translucent backdrop that dims everything else, and
# keeps the focus inside itself: Tab moves between its two buttons (the
# focused one has a blue border), Escape or a button closes it. It is
# open when the program starts; d opens it again. Ctrl+C quits.
#
#     perl examples/widgets/dialog.pl

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
use Term::Fabulous::Widget::Dialog;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

sub text ( $string, $color = [ 220, 220, 220, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);
$root->add_child( text( 'Selected files (d asks to delete them):', [ 150, 160, 180, 255 ] ) );
$root->add_child( text( sprintf '  %-28s %8s', @$_ ) ) foreach [ 'holiday-photos.tar.gz', '1.2 GB' ], [ 'notes-2026.txt', '14 kB' ], [ 'old-backup.img', '8.0 GB' ];
my $status = text( '', [ 150, 200, 255, 255 ] );
$root->add_child( text(''), $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

my $dialog = Term::Fabulous::Widget::Dialog->new( layout => { sizing => { width => sizing_fixed(44) } } );

sub button ( $caption, $background, $action ) {
	my $button = Term::Fabulous::Widget::Button->new(
		background_color => $background,
		bordered         => 1,
		border_color     => [ 90, 110, 140, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
		layout           => { padding => { left => 1, right => 1 } },
	);
	$button->add_child( text( $caption, [ 255, 255, 255, 255 ] ) );
	$button->on( Activate => sub ($event) { $action->(); return } );
	return $button;
}

my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
$buttons->add_child(
	button( 'Delete', [ 140, 45, 50, 255 ], sub { $status->text('3 files deleted.'); $dialog->close } ),
	button( 'Cancel', [ 43,  58, 85, 255 ], sub { $dialog->close } ),
);
$dialog->add_child( text( 'Delete 3 files?', [ 255, 255, 255, 255 ] ), text('They take 9.2 GB. This cannot be undone.'), $buttons );
$dialog->on( Close => sub ($event) { $status->text('Nothing was deleted.') unless length $status->text; return } );

$root->on( Start => sub ($event) { $dialog->open($ui); return } );
$root->on(
	KeyPress => sub ($event) {
		$dialog->open($ui) if ( $event->key_name // '' ) eq 'd';
		return;
	}
);

$ui->run;
