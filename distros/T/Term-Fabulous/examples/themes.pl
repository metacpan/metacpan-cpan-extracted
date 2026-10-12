#!/usr/bin/env perl

# Themes: the same widgets under the built-in dark and light themes and
# under the theme files in examples/themes/. A theme paints the screen
# in its background, so a light theme is readable on a dark terminal and
# the other way around. F2 switches to the next theme; a theme name on
# the command line picks the first one:
#
#     perl examples/themes.pl nord
#
# The widgets that were given a color of their own keep it under every
# theme. See Term::Fabulous::Manual::Looks and Term::Fabulous::Theme.

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Divider;
use Term::Fabulous::Widget::ProgressBar;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

# The built-in themes first, then every theme file, by name.
my @themes = ( ( map { Term::Fabulous::Theme->builtin($_) } qw(dark light) ), ( map { Term::Fabulous::Theme->from_file($_) } sort glob("$FindBin::Bin/themes/*.kdl") ) );
my @names  = map { $_->name } @themes;

my $current = 0;
if ( my ($wanted) = @ARGV ) {
	($current) = grep { $names[$_] eq $wanted } 0 .. $#names;
	die "themes.pl: unknown theme '$wanted' (known: @names)\n" unless defined $current;
}

# A panel: its frame is the box family's border, drawn in the theme's
# border style and color; the title is a Text without a color of its
# own, so it is drawn in the theme's text color, and the screen around
# the panel in the theme's background.
my $panel = Term::Fabulous::Widget::Box->new(
	bordered => 1,
	layout   => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(56) }, padding => { left => 1, right => 1 }, child_gap => 1 },
);
my $title = Term::Fabulous::Widget::Text->new( text => "Theme: $names[$current] (F2 switches, Ctrl+C quits)" );

my $name  = Term::Fabulous::Widget::TextField->new( placeholder => 'Your name', layout => { sizing => { width => sizing_grow() } } );
my $agree = Term::Fabulous::Widget::Checkbox->new( label => 'Subscribe to the newsletter', checked => 1 );
my $bar   = Term::Fabulous::Widget::ProgressBar->new( value => 65, layout => { sizing => { width => sizing_grow() } } );

# Two buttons: the first is 'primary', which the theme files style in
# their accent; the second keeps its own border color under every theme.
my $save = Term::Fabulous::Widget::Button->new( classes => ['primary'], bordered => 1, layout => { padding => { left => 2, right => 2 } } );
$save->add_child( Term::Fabulous::Widget::Text->new( text => 'Save' ) );
my $cancel = Term::Fabulous::Widget::Button->new( bordered => 1, border_color => '#e06c75', layout => { padding => { left => 2, right => 2 } } );
$cancel->add_child( Term::Fabulous::Widget::Text->new( text => 'Cancel' ) );
my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
$buttons->add_child( $save, $cancel );

$panel->add_child( $title, Term::Fabulous::Widget::Divider->new( text => 'Account' ), $name, $agree, $bar, $buttons );

my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, right => 2, top => 1, bottom => 1 } } );
$root->add_child($panel);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24, theme => $themes[$current] );
$root->on(
	KeyPress => sub ($event) {
		return unless ( $event->key_name // '' ) eq 'F2';
		$current = ( $current + 1 ) % @themes;
		$ui->theme( $themes[$current] );
		$title->text("Theme: $names[$current] (F2 switches, Ctrl+C quits)");
		return;
	}
);
$ui->interaction->set_focused_widget($name);
$ui->run;
