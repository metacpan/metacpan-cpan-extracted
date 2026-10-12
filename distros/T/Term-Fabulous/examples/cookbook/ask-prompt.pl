#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::Text;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $minutes = 25;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $session = Term::Fabulous::Widget::Text->new( text => "The next session lasts $minutes minutes." );
$root->add_child( $session, Term::Fabulous::Widget::Text->new( text => 't changes it, q quits.' ) );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# The field checks that it holds a whole number; the check of the
# prompt runs after it and keeps the number in range.
sub ask_minutes () {
	Term::Fabulous::Widget::Prompt->ask(
		$ui,
		title     => 'Session length',
		message   => 'How many minutes should the next session last?',
		label     => 'Minutes',
		value     => $minutes,
		required  => 1,
		validator => 'integer',
		check     => sub ($values) { return $values->{value} >= 1 && $values->{value} <= 120 ? undef : 'A session lasts 1 to 120 minutes.' },
		width     => 52,
	)->on(
		Answer => sub ($event) {
			return if $event->button ne 'ok';
			$minutes = $event->value('value');
			$session->text("The next session lasts $minutes minutes.");
			return;
		}
	);
	return;
}

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		if ( $key eq 't' ) {
			ask_minutes();
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
