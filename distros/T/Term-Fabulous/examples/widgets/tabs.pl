#!/usr/bin/env perl

# Term::Fabulous::Widget::Tabs in its forms: tabs along the top of a
# settings page with a disabled tab, a bar at the bottom in the Heavy
# style with the tabs in the center, tabs along the left side as a
# sidebar, and tabs with downward labels without a border around the
# page. Tab moves the focus, Left and Right (or Up and Down, Home and
# End) choose a tab, so does a click, Ctrl+PageUp and Ctrl+PageDown turn
# the pages from anywhere inside, Ctrl+C quits.
#
#     perl examples/widgets/tabs.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Tabs;
use Term::Fabulous::Widget::Tabs::Page;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 3,
	},
);

sub text ( $string, $color = [ 200, 205, 215, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

sub row ( $label, $input ) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
	$row->add_child( text($label), $input );
	return $row;
}

sub page ( $title, %options ) {
	my $content = delete $options{content} // [];
	my $page    = Term::Fabulous::Widget::Tabs::Page->new( title => $title, %options );
	$page->add_child(@$content);
	return $page;
}

sub column (@tabs) {
	my $column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );
	$column->add_child(@tabs);
	return $column;
}

# Tabs along the top: the classic settings page. The Network tab has
# the focus, the Licenses tab is disabled.
my $settings = Term::Fabulous::Widget::Tabs->new( id => 'settings', layout => { sizing => { width => sizing_grow(), height => sizing_fixed(12) } } );
$settings->add_child(
	page(
		'General',
		content => [
			row( 'Language ', Term::Fabulous::Widget::TextField->new( value => 'en', preferred_columns => 8 ) ), Term::Fabulous::Widget::Checkbox->new( label => 'Check for updates', checked => 1 )
		]
	),
	page(
		'Network',
		active  => 1,
		content => [
			row( 'Hostname ', Term::Fabulous::Widget::TextField->new( value => 'example.org', preferred_columns => 14 ) ),
			row( 'Port     ', Term::Fabulous::Widget::TextField->new( value => '443',         preferred_columns => 6 ) )
		]
	),
	page( 'Users',    content  => [ text('Three accounts, two groups.') ] ),
	page( 'Licenses', disabled => 1, content => [ text('Not available in this edition.') ] ),
);

# A bar at the bottom, in the Heavy style, the tabs in the center and
# the active label bold.
my $panels = Term::Fabulous::Widget::Tabs->new( side => 'bottom', line_style => 'Heavy', tab_alignment => 'center', active_bold => 1 );
$panels->add_child(
	page( 'Output',   content => [ text('Build finished in 2.4 s.'), text( 'No warnings.', [ 152, 195, 121, 255 ] ) ] ),
	page( 'Problems', content => [ text( '2 problems in 1 file', [ 224, 108, 117, 255 ] ) ] ),
	page( 'Terminal', content => [ text('$ make test') ] ),
);

# Tabs along the left side: a sidebar.
my $details = Term::Fabulous::Widget::Tabs->new( side => 'left', layout => { sizing => { width => sizing_grow(), height => sizing_fixed(13) } } );
$details->add_child(
	page( 'Info',  content => [ text('perl-term-fabulous'), text( 'A toolkit for terminal user interfaces.', [ 150, 160, 180, 255 ] ) ] ),
	page( 'Stats', content => [ text('42 widgets, 20 border styles') ] ),
	page( 'Log',   content => [ text('Nothing to show yet.') ] ),
);

# Tabs with downward labels, without a border around the page.
my $views = Term::Fabulous::Widget::Tabs->new( orientation => 'vertical', page_border => 0, line_style => 'Solid', line_color => [ 97, 175, 239, 255 ] );
$views->add_child(
	page( 'List', content => [ text('README.md'), text('Changes'), text('Makefile.PL') ] ),
	page( 'Grid', content => [ text('README.md  Changes  Makefile.PL') ] ),
	page( 'Map',  content => [ text('No map for this folder.') ] ),
);
$views->select(1);

$root->add_child( column( $settings, $panels ), column( $details, $views ) );

my $ui = Term::Fabulous->new( width => 100, height => 30, root => $root );
$ui->interaction->set_focused_widget( $settings->bar->active );
$ui->run;
