#!/usr/bin/env perl

# Term::Fabulous::Widget::Dialog: a dialog that opens over the screen,
# centered, behind a translucent backdrop that dims everything else, and
# keeps the focus inside itself. It brings its own title and buttons:
# Tab moves between the two buttons, Escape or a button closes it, and
# the dialog answers with the button pressed. It is open when the
# program starts; d opens it again. Ctrl+C quits.
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
use Term::Fabulous::Widget::Box;
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

# The title and the buttons come with the dialog; the text between them
# is its content. Pressing a button answers with its id, Escape answers
# cancel.
my $dialog = Term::Fabulous::Widget::Dialog->new(
	title   => 'Delete 3 files?',
	buttons => [ { id => 'delete', label => 'Delete', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
	layout  => { sizing => { width => sizing_fixed(44) } },
);
$dialog->add_child( text('They take 9.2 GB. This cannot be undone.') );
$dialog->on( Answer => sub ($event) { $status->text( $event->button eq 'delete' ? '3 files deleted.' : 'Nothing was deleted.' ); return } );

$root->on( Start => sub ($event) { $dialog->open($ui); return } );
$root->on(
	KeyPress => sub ($event) {
		$dialog->open($ui) if ( $event->key_name // '' ) eq 'd';
		return;
	}
);

$ui->run;
