#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ColorPicker;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::Text;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $color = '#e5c07b';    # the setting: the color of the highlight

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $sample = Term::Fabulous::Widget::Box->new( background_color => $color, layout => { sizing => { width => sizing_fixed(24), height => sizing_fixed(3) } } );
my $label  = Term::Fabulous::Widget::Text->new( text => "Highlight color: $color" );
$root->add_child( $label, $sample, Term::Fabulous::Widget::Text->new( text => 'c changes the color, q quits.' ) );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

sub ask_color () {
	my $picker = Term::Fabulous::Widget::ColorPicker->new(
		value     => $color,
		alpha     => 0,
		list_rows => 6,
		swatches  => [
			[ '#e5c07b', 'Sand',  '#e5c07b' ],
			[ '#61afef', 'Sky',   '#61afef' ],
			[ '#98c379', 'Mint',  '#98c379' ],
			[ '#e06c75', 'Rose',  '#e06c75' ],
			[ '#c678dd', 'Lilac', '#c678dd' ],
			[ '#56b6c2', 'Teal',  '#56b6c2' ],
		],
	);
	Term::Fabulous::Widget::Prompt->new(
		title   => 'Highlight color',
		message => 'Pick a color, type one or move the sliders.',
		fields  => [ { name => 'color', label => 'Color',  input   => $picker } ],
		buttons => [ { id   => 'ok',    label => 'Use it', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
		width   => 66,
	)->on(
		Answer => sub ($event) {
			return if $event->button ne 'ok';
			$color = $event->value('color');
			$sample->background_color( $picker->rgba );
			$label->text("Highlight color: $color");
			return;
		}
	)->open($ui);
	return;
}

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		if ( $key eq 'c' ) {
			ask_color();
			return;
		}
		if ( $key eq 'q' ) {
			$ui->loop->stop;
			return;
		}
		return Clay::UI::Enum::Result->CONTINUE;
	}
);

$ui->run;
