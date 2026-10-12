#!/usr/bin/env perl

# Term::Fabulous::Widget::Toast: toasts of every kind stacked in the top
# right corner, a filled (important) one that stays in the bottom right
# corner, and one used as an alert box inside the form. The keys 1 to 4
# show a toast of each kind, i an important one, Ctrl+C quits. Toasts go
# away after five seconds or with a click on their close mark.
#
#     perl examples/widgets/toast.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Term::Fabulous::Widget::Toast;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

sub text ( $string, $color = [ 200, 205, 215, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A small form with an alert box inside it.
my $form = Term::Fabulous::Widget::Box->new(
	background_color => [ 28, 33, 45, 255 ],
	bordered         => 1,
	border_color     => [ 70, 85, 110, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(40) }, padding => { left => 1, right => 1 }, child_gap => 1 },
);
my $name = Term::Fabulous::Widget::TextField->new( placeholder => 'Your name', layout => { sizing => { width => sizing_grow() } } );
$form->add_child(
	text( 'Profile', [ 97, 175, 239, 255 ] ),
	$name,
	Term::Fabulous::Widget::Toast->new( kind => 'warning', message => 'You have unsaved changes.', closable => 0, layout => { sizing => { width => sizing_grow() } } ),
);
$root->add_child( $form, text( '1 to 4: show a toast of each kind, i: an important one', [ 150, 160, 180, 255 ] ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

my %toast = (
	1 => [ info    => 'Update available', 'Version 2.1 can be installed.' ],
	2 => [ success => 'Saved',            'Your changes were written to disk.' ],
	3 => [ warning => 'Disk almost full', '93% of the volume is in use.' ],
	4 => [ danger  => 'Upload failed',    'The server did not answer in time.' ],
);
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->main_key_name // return;
		if ( my $spec = $toast{$key} ) {
			my ( $kind, $title, $message ) = @$spec;
			Term::Fabulous::Widget::Toast->new( kind => $kind, title => $title, message => $message )->show($ui);
		}
		elsif ( $key eq 'i' ) {
			Term::Fabulous::Widget::Toast->new(
				kind    => 'danger', title => 'Connection lost', message => 'Reconnecting in the background.', important => 1, position => 'bottom_right',
				timeout => undef
			)->show($ui);
		}
		return;
	}
);

$ui->run;
