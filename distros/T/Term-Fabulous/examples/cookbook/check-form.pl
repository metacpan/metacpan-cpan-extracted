#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Validator;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $form = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
$root->add_child($form);

# One row per input: a label, the input and a message beside it, which
# the ValidityChange listener below fills in. The width groups line up
# the inputs and the messages.
my %message_of;

sub row ( $label, $input ) {
	my $label_box = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label_box->add_child( Term::Fabulous::Widget::Text->new( text => $label, text_color => [ 150, 160, 180, 255 ] ) );
	my $input_box = Term::Fabulous::Widget::Box->new( width_group => 2 );
	$input_box->add_child($input);
	$message_of{ $input->id } = Term::Fabulous::Widget::Text->new( text => ' ', text_color => [ 224, 108, 117, 255 ] );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( $label_box, $input_box, $message_of{ $input->id } );
	$form->add_child($row);
	return $input;
}

sub text_field ( $id, %parameters ) {
	return Term::Fabulous::Widget::TextField->new( id => $id, preferred_columns => 22, %parameters );
}

# Required fields, and fields checked by a named validator. An optional
# field may stay empty; its validator only checks what the user typed.
row( 'Name', text_field( 'name', required => 1, required_message => 'Please tell us your name.' ) );
row( 'E-mail', text_field( 'email', required => 1, validator => 'email', placeholder => 'name@example.com' ) );

row( 'Website', text_field( 'website', validator => 'url',      placeholder => 'https://...' ) );
row( 'Server',  text_field( 'server',  validator => 'hostname', placeholder => 'db.example.com' ) );
row( 'Address', text_field( 'address', validator => 'ip',       placeholder => '192.0.2.1 or 2001:db8::1' ) );
row( 'Alarm',   text_field( 'alarm',   validator => 'time',     placeholder => 'HH:MM' ) );

# Validators with options are objects. integer, number and date also
# restrict what the user can type: integer lets through only digits and
# the minus sign.
my $port_validator     = Term::Fabulous::Validator->integer( min => 1, max => 65535 );
my $price_validator    = Term::Fabulous::Validator->number( min => 0 );
my $birthday_validator = Term::Fabulous::Validator->date( message => 'Please enter your birthday as YYYY-MM-DD.' );
row( 'Port',     text_field( 'port',     validator => $port_validator,     value       => '8080' ) );
row( 'Price',    text_field( 'price',    validator => $price_validator,    placeholder => '9.99' ) );
row( 'Birthday', text_field( 'birthday', validator => $birthday_validator, placeholder => 'YYYY-MM-DD' ) );

# A dropdown without a choice and an unchecked check box count as empty.
row( 'Color', Term::Fabulous::Widget::Dropdown->new( id => 'color', required => 1, options => [qw(Red Green Blue)], placeholder => 'Choose one' ) );

row( 'Terms', Term::Fabulous::Widget::Checkbox->new( id => 'terms', required => 1, required_message => 'Please accept the terms.', label => 'I accept the terms' ) );

my $status = Term::Fabulous::Widget::Text->new( text => 'Enter in a text field sends the form.' );
$root->add_child($status);

# Every input reports a change of its message; the event bubbles up to
# the form. A valid value reports undef as its error.
$form->on(
	ValidityChange => sub ($event) {
		$message_of{ $event->target->id }->text( $event->error // ' ' );
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# Enter in a text field fires Submit, which bubbles up to the form. An
# input that was never changed has reported nothing yet: validate makes
# it report its message now.
$form->on(
	Submit => sub ($event) {
		my @invalid = $form->invalid_inputs;
		if ( !@invalid ) {
			$status->text('Thank you, the form is complete.');
			return;
		}
		$_->validate foreach @invalid;
		$status->text( sprintf '%d fields need your attention.', scalar @invalid );
		$ui->interaction->set_focused_widget( $invalid[0] );
		return;
	}
);

$ui->run;
