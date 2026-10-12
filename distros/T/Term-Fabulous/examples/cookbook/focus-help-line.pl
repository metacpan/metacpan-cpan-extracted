#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Slider;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
use Term::Fabulous::Widget::TextField;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my %help_by_id = (
	title  => 'A short title, at most 40 characters.',
	notes  => 'Enter starts a new line; Ctrl+Z undoes.',
	rating => 'Left and Right change the rating.',
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $status = Term::Fabulous::Widget::Text->new( text => 'Press Tab to start.', text_color => [ 150, 200, 255, 255 ] );
$root->add_child(
	Term::Fabulous::Widget::TextField->new( id => 'title', placeholder => 'Title', max_length => 40 ),
	Term::Fabulous::Widget::TextArea->new( id => 'notes', placeholder => 'Notes', layout => { sizing => { width => sizing_grow(), height => sizing_fixed(5) } } ),
	Term::Fabulous::Widget::Slider->new( id => 'rating', min => 1, max => 5, value => 3 ),
	$status,
);

# OnFocus is fired on the widget that gets the focus and bubbles up to
# the root, because the inputs' own OnFocus listeners return CONTINUE.
$root->on(
	OnFocus => sub ($event) {
		$status->text( $help_by_id{ $event->target->id } // '' );
		return;
	}
);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
