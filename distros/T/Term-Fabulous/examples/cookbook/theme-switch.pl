#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Term::Fabulous;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# Three themes: the two built-in ones, and one from a file. The file
# starts from the dark theme and changes its palette, gives buttons a
# round border and defines a 'primary' variant for them.
my @themes  = ( 'dark', 'light', Term::Fabulous::Theme->from_file("$FindBin::Bin/../themes/ocean.kdl") );
my $current = 0;

# No widget here is given a color: the theme supplies them all. The
# screen is painted in the theme's background, the panel is a Box,
# which paints nothing of its own, and the text, the field and the
# buttons take their family's looks.
my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $label = Term::Fabulous::Widget::Text->new( text => 'Theme: dark. Press F2 to switch to the next theme.' );
my $field = Term::Fabulous::Widget::TextField->new( placeholder => 'Type here' );
my $save  = Term::Fabulous::Widget::Button->new( classes => ['primary'], bordered => 1, layout => { padding => { left => 2, right => 2 } } );
$save->add_child( Term::Fabulous::Widget::Text->new( text => 'Save' ) );
$root->add_child( $label, $field, $save );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24, theme => $themes[$current] );

# Setting the theme of the UI is all it takes: every widget reads its
# colors again in the next frame.
$root->on(
	KeyPress => sub ($event) {
		return unless ( $event->key_name // '' ) eq 'F2';
		$current = ( $current + 1 ) % @themes;
		$ui->theme( $themes[$current] );
		$label->text( 'Theme: ' . $ui->theme->name . '. Press F2 to switch to the next theme.' );
		return;
	}
);

$ui->interaction->set_focused_widget($field);
$ui->run;
