#!/usr/bin/env perl

# A tour of Term::Fabulous on one screen: a form with every input widget,
# buttons, a live area chart, a log that grows from a timer in a scroll
# box, a translucent notification and text in several scripts. The
# screenshot at the top of the documentation shows it.
#
#     perl examples/showcase.pl
#
# Tab and Shift+Tab move between the inputs, the mouse works too. Save
# shows a notification, Ctrl+C quits.

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use IO::Async::Timer::Periodic;
use POSIX qw(strftime);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::RadioButton;
use Term::Fabulous::Widget::RadioGroup;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Slider;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Clay::XS qw(
	sizing_grow sizing_fit sizing_fixed
	CLAY_TOP_TO_BOTTOM CLAY_LEFT_TO_RIGHT CLAY_ALIGN_Y_CENTER
	CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_RIGHT_BOTTOM
);

# The palette, a dark theme.
my %color = (
	panel  => [ 28,  33,  45,  255 ],
	header => [ 33,  44,  70,  255 ],
	border => [ 70,  85,  110, 255 ],
	accent => [ 97,  175, 239, 255 ],
	text   => [ 220, 223, 228, 255 ],
	muted  => [ 140, 150, 170, 255 ],
	green  => [ 152, 195, 121, 255 ],
	yellow => [ 229, 192, 123, 255 ],
	red    => [ 224, 108, 117, 255 ],
	button => [ 43,  58,  85,  255 ],
);

sub text ( $string, $text_color = $color{text} ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $text_color );
}

# A framed panel with a title, holding the given children in a column.
sub panel ( $title, $sizing, @children ) {
	my $panel = Term::Fabulous::Widget::Box->new(
		background_color => $color{panel},
		bordered         => 1,
		border_color     => $color{border},
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
		layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => $sizing, padding => { left => 1, right => 1 }, child_gap => 1 },
	);
	$panel->add_child( text( $title, $color{accent} ), @children );
	return $panel;
}

# --- The form ------------------------------------------------------------

sub form_row ( $label, $input ) {
	my $row  = Term::Fabulous::Widget::Box->new( layout      => { child_gap => 1, sizing => { width => sizing_grow() } } );
	my $cell = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$cell->add_child( text( $label, $color{muted} ) );
	$row->add_child( $cell, $input );
	return $row;
}

my $name  = Term::Fabulous::Widget::TextField->new( id => 'name',  placeholder => 'Your name',       layout => { sizing => { width => sizing_grow() } } );
my $email = Term::Fabulous::Widget::TextField->new( id => 'email', placeholder => 'you@example.com', layout => { sizing => { width => sizing_grow() } } );
my $plan  = Term::Fabulous::Widget::RadioGroup->new( id => 'plan', value => 'pro', layout => { layout_direction => CLAY_LEFT_TO_RIGHT, child_gap => 2 } );
$plan->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) ) foreach [ Free => 'free' ], [ Pro => 'pro' ], [ Team => 'team' ];
my $region = Term::Fabulous::Widget::Dropdown->new(
	id      => 'region',
	options => [ [ 'Europe' => 'eu' ], [ 'North America' => 'na' ], [ 'Asia Pacific' => 'ap' ] ],
	value   => 'eu',
);
my $volume     = Term::Fabulous::Widget::Slider->new( id => 'volume', value => 70, step => 5, value_format => '%d%%', layout => { sizing => { width => sizing_grow() } } );
my $newsletter = Term::Fabulous::Widget::Checkbox->new( id => 'newsletter', label => 'Send me the newsletter', checked => 1 );

sub button ( $caption, $border_color ) {
	my $button = Term::Fabulous::Widget::Button->new(
		bordered     => 1,
		border_color => $border_color,
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
		layout       => { padding => { left => 2, right => 2 } },
	);
	$button->add_child( text( $caption, [ 255, 255, 255, 255 ] ) );
	return $button;
}
my $save    = button( 'Save',   $color{green} );
my $cancel  = button( 'Cancel', $color{border} );
my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
$buttons->add_child( $save, $cancel );

my $form = panel(
	'Create an account',
	{ width => sizing_grow(), height => sizing_fit() },
	form_row( 'Name',   $name ),
	form_row( 'E-mail', $email ),
	form_row( 'Plan',   $plan ),
	form_row( 'Region', $region ),
	form_row( 'Volume', $volume ),
	form_row( '',       $newsletter ),
	$buttons,
);

# --- The chart -----------------------------------------------------------

# Two series of requests per second as filled areas; the chart keeps the
# newest 60 points, the newest at the right edge.
my $chart = Term::Fabulous::Widget::AreaChart->new(
	curve        => 'monotone',
	fill_opacity => 0.85,
	x_axis       => { visible => 0, nice => 0 },
	y_axis       => { min     => 0, grid => 'dotted' },
	max_points   => 60,
	series       => [ { name => 'api', color => '#61afef' }, { name => 'workers', color => '#c678dd' } ],
);
my $tick = 0;

sub requests ( $series, $sample ) {
	my $t = $sample / 6;
	return $series eq 'api'
		? 0.55 + 0.25 * sin($t) + 0.12 * sin( $t * 2.7 + 1 )
		: 0.30 + 0.15 * sin( $t * 1.3 + 2 ) + 0.08 * sin( $t * 3.1 );
}

# Adds the next point of both series, in requests per second.
sub sample_requests () {
	$tick++;
	$chart->append( $tick, { map { $_ => int( 1000 * requests( $_, $tick ) ) } qw(api workers) } );
	return;
}
sample_requests() foreach 1 .. 60;    # a full chart from the first frame

my $chart_panel = panel( 'Requests per second', { width => sizing_grow(), height => sizing_grow() }, $chart );

# A translucent notification that floats over the chart's lower right
# corner for a few seconds: added to the chart's panel to show it,
# removed to hide it.
my $toast_text = text( '', [ 255, 255, 255, 255 ] );
my $toast      = Term::Fabulous::Widget::Box->new(
	background_color    => [ 40, 90, 70, 200 ],
	glyphs_show_through => 1,
	bordered            => 1,
	border_color        => $color{green},
	border_style        => Term::Fabulous::Enum::BorderStyle->Round,
	layout              => { padding => { left => 1, right => 1 } },
	floating            => {
		attach_to     => CLAY_ATTACH_TO_PARENT,
		attach_points => { element => CLAY_ATTACH_POINT_RIGHT_BOTTOM, parent => CLAY_ATTACH_POINT_RIGHT_BOTTOM },
		offset        => { x       => -2,                             y      => -1 },
	},
);
$toast->add_child($toast_text);

sub show_toast ($message) {
	$toast_text->text($message);
	$chart_panel->add_child($toast) unless defined $toast->parent;
	return;
}

sub hide_toast () {
	$chart_panel->remove_child($toast);
	return;
}

# --- The log -------------------------------------------------------------

# follow_end keeps the newest line in view.
my $log = Term::Fabulous::Widget::ScrollBox->new(
	id         => 'log',
	follow_end => 1,
	layout     => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
);
my $log_panel = panel( 'Events', { width => sizing_grow(), height => sizing_fixed(10) }, $log );

my @events = (
	[ $color{green},  'GET  /api/users        200   12 ms' ],
	[ $color{green},  'POST /api/orders       201   48 ms' ],
	[ $color{yellow}, 'GET  /api/reports      304    3 ms' ],
	[ $color{green},  'GET  /api/users/42     200    9 ms' ],
	[ $color{red},    'POST /api/payments     502  310 ms' ],
	[ $color{green},  'GET  /health           200    1 ms' ],
);
my $event_number = 0;

# Adds the next event and drops the oldest beyond 100.
sub log_event () {
	my ( $level_color, $message ) = @{ $events[ $event_number++ % @events ] };
	my $line = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
	$line->add_child( text( strftime( '%H:%M:%S', localtime ), $color{muted} ), text( $message, $level_color ) );
	$log->add_child($line);
	my $oldest = $log->children->[0];
	$log->remove_child($oldest) if @{ $log->children } > 100;
	return;
}

# --- Unicode -------------------------------------------------------------

my $scripts = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
$scripts->add_child(
	text('Grüße aus München · Ελληνικά'),
	text('こんにちは、世界 · 안녕하세요'),
	text( '🚀 Emoji and CJK take two cells', $color{yellow} ),
);
my $unicode_panel = panel( 'Any script, any width', { width => sizing_grow(), height => sizing_fit() }, $scripts );

# --- The screen ----------------------------------------------------------

my $clock  = text( '--:--:--', $color{muted} );
my $header = Term::Fabulous::Widget::Box->new(
	background_color => $color{header},
	layout           => { sizing => { width => sizing_grow() }, padding => { left => 2, right => 2 }, child_gap => 2, child_alignment => { y => CLAY_ALIGN_Y_CENTER } },
);
my $spacer = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() } } );
$header->add_child( text( 'Term::Fabulous', [ 255, 255, 255, 255 ] ), text( 'terminal user interfaces for Perl', $color{muted} ), $spacer, $clock );

my $left_column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(46), height => sizing_grow() }, child_gap => 1 } );
$left_column->add_child( $form, $unicode_panel );
my $right_column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );
$right_column->add_child( $chart_panel, $log_panel );

my $body = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, right => 2 }, child_gap => 2 } );
$body->add_child( $left_column, $right_column );

my $footer = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, padding => { left => 2, right => 2 }, child_gap => 3 } );
foreach my $hint ( [ 'Tab' => 'next input' ], [ 'Shift+Tab' => 'previous input' ], [ 'Enter' => 'activate' ], [ 'Ctrl+C' => 'quit' ] ) {
	my $pair = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
	my $key  = Term::Fabulous::Widget::Box->new( background_color => $color{button}, layout => { padding => { left => 1, right => 1 } } );
	$key->add_child( text( $hint->[0], [ 255, 255, 255, 255 ] ) );
	$pair->add_child( $key, text( $hint->[1], $color{muted} ) );
	$footer->add_child($pair);
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { bottom => 1 }, child_gap => 1 },
);
$root->add_child( $header, $body, $footer );

my $ui = Term::Fabulous->new( width => 100, height => 30, root => $root );

# --- Behaviour -------------------------------------------------------------

my $loop = IO::Async::Loop->new;

my $hide_timer = IO::Async::Timer::Countdown->new( delay => 4, on_expire => sub { hide_toast(); return } );
$loop->add($hide_timer);

$save->on(
	Activate => sub ($event) {
		my $who = length $name->value ? $name->value : 'you';
		show_toast("\x{2713} Saved. Welcome, $who!");
		$hide_timer->is_running ? $hide_timer->reset : $hide_timer->start;
		return;
	}
);
$cancel->on( Activate => sub ($event) { $ui->loop->stop; return } );

$loop->add(
	IO::Async::Timer::Periodic->new(
		interval       => 1,
		first_interval => 0,
		on_tick        => sub { $clock->text( strftime( '%H:%M:%S', localtime ) ); log_event(); return },
	)->start
);
$loop->add( IO::Async::Timer::Periodic->new( interval => 0.25, on_tick => sub { sample_requests(); return } )->start );

$ui->interaction->set_focused_widget($name);
$ui->run;
