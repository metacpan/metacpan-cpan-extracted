#!/usr/bin/env perl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::RadioButton;
use Term::Fabulous::Widget::RadioGroup;
use Term::Fabulous::Widget::Slider;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
use Term::Fabulous::Widget::TextField;
use Term::Fabulous::Validator;

use Clay::UI::Enum::Result;
use Clay::XS qw(:all);

use constant LABEL_COLUMNS => 12;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

sub text ( $string, $color = [ 220, 220, 220, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

$root->add_child( text('Tab and Shift-Tab move between inputs; the mouse works too. Ctrl+C quits.') );

my $form = Term::Fabulous::Widget::Box->new(
	background_color => [ 28, 33, 45, 255 ],
	bordered         => 1,
	border_color     => [ 97, 175, 239, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow() },
		padding          => { left  => 1, right => 1 },
	},
);
$root->add_child($form);

# One row of the form: a label of fixed width, then the input.
sub row ( $label, $input ) {
	my $row  = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1 } );
	my $cell = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(LABEL_COLUMNS) } } );
	$cell->add_child( text( $label, [ 150, 160, 180, 255 ] ) );
	$row->add_child( $cell, $input );
	$form->add_child($row);
	return $input;
}

my $name     = row( 'Name',     Term::Fabulous::Widget::TextField->new( id => 'name',     placeholder => 'Your name', preferred_columns => 30 ) );
my $password = row( 'Password', Term::Fabulous::Widget::TextField->new( id => 'password', mask        => '*',         preferred_columns => 30 ) );
my $notes    = row(
	'Notes',
	Term::Fabulous::Widget::TextArea->new(
		id          => 'notes',
		placeholder => 'Anything else? Enter starts a new line.',
		layout      => { sizing => { width => sizing_grow(), height => sizing_fixed(4) } },
	)
);
my $color = row(
	'Color',
	Term::Fabulous::Widget::Dropdown->new(
		id          => 'color',
		placeholder => 'Pick a color',
		options     => [ qw(Red Orange Yellow Green Cyan Blue Indigo Violet), [ 'Black (no color)' => 'none' ], 'White' ],
	)
);

my $size = Term::Fabulous::Widget::RadioGroup->new( id => 'size', value => 'm', layout => { layout_direction => CLAY_LEFT_TO_RIGHT, child_gap => 2 } );
$size->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) ) foreach [ Small => 's' ], [ Medium => 'm' ], [ Large => 'l' ];
row( 'Size', $size );

my $volume = row( 'Volume',     Term::Fabulous::Widget::Slider->new( id => 'volume', value => 30, step => 5, value_format => '%d%%', preferred_columns => 30 ) );
my $news   = row( 'Newsletter', Term::Fabulous::Widget::Checkbox->new( id => 'newsletter', label => 'Send me the newsletter' ) );
my $terms  = row( 'Terms',      Term::Fabulous::Widget::Checkbox->new( id => 'terms', label => 'I accept the terms (enables the password field)', checked => 1 ) );

# Validated fields: an invalid value is painted red; the message is in the status line.
my $email = row( 'E-mail', Term::Fabulous::Widget::TextField->new( id => 'email', validator => 'email', placeholder => 'name@example.com', preferred_columns => 30 ) );
my $port  = row( 'Port',   Term::Fabulous::Widget::TextField->new( id => 'port', validator => Term::Fabulous::Validator->integer( min => 1, max => 65535 ), value => '8080', preferred_columns => 6 ) );

$terms->on( Change => sub ($event) { $password->disabled( !$event->value ); return Clay::UI::Enum::Result->CONTINUE } );

# Every Change bubbles up to the form; show the latest one. A
# ValidityChange follows a Change whose value became valid or invalid.
my $status = text('Change something.');
$root->add_child($status);
$form->on(
	Change => sub ($event) {
		my $value = $event->value // 'nothing';
		$value =~ s/\n/\x{21B5}/g;
		$status->text( sprintf '%s changed to: %s', $event->target->id, $value );
		return;
	}
);
$form->on(
	ValidityChange => sub ($event) {
		$status->text( sprintf '%s: %s', $event->target->id, $event->error // 'fine now' );
		return;
	}
);
$name->on( Submit => sub ($event) { $status->text( 'Hello, ' . $event->value . '!' ); return } );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($name);
$ui->run;
