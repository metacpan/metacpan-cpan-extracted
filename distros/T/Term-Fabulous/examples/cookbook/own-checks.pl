#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Validator;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
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

# A label, the input and its message below it.
sub row ( $label, $input ) {
	my $label_box = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label_box->add_child( Term::Fabulous::Widget::Text->new( text => $label, text_color => [ 150, 160, 180, 255 ] ) );
	my $message = Term::Fabulous::Widget::Text->new( text => ' ', text_color => [ 224, 108, 117, 255 ] );
	my $column  = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
	$column->add_child( $input, $message );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( $label_box, $column );
	$root->add_child($row);

	$input->on( ValidityChange => sub ($event) { $message->text( $event->error // ' ' ); return } );
	return $input;
}

# accept with a character class body: only capital letters and digits
# can be typed; a pattern checks the whole value, with its own message.
row(
	'Product code',
	Term::Fabulous::Widget::TextField->new(
		accept     => 'A-Z0-9',
		max_length => 6,
		validator  => Term::Fabulous::Validator->pattern( qr/\A[A-Z]{3}[0-9]{3}\z/, message => 'Three letters and three digits, such as ABC123.' ),
	)
);

# accept with a regular expression, tested on every typed character:
# letters of any script, blanks, hyphens and apostrophes.
row( 'Name', Term::Fabulous::Widget::TextField->new( accept => qr/[\p{L} '-]/, placeholder => 'José Saramago' ) );

# A code reference returns what is wrong with the value, or nothing.
row(
	'Even number',
	Term::Fabulous::Widget::TextField->new(
		validator => sub ($value) {
			return 'Please enter a whole number.' unless $value =~ /\A-?[0-9]+\z/;
			return 'Please enter an even number.' if $value % 2;
			return;
		},
	)
);

# A list: every validator must pass, the first message wins.
row(
	'Mail server',
	Term::Fabulous::Widget::TextField->new(
		validator   => [ 'hostname', Term::Fabulous::Validator->pattern( qr/\.example\.com\z/i, message => 'Please use a host in example.com.' ) ],
		placeholder => 'mail.example.com',
	)
);

# A validator object can check values outside of a widget too: here
# each line of a text area.
my $hostname = Term::Fabulous::Validator->hostname;
row(
	'Hosts',
	Term::Fabulous::Widget::TextArea->new(
		preferred_rows => 3,
		validator      => sub ($value) {
			my @lines = split /\n/, $value;
			foreach my $number ( 1 .. @lines ) {
				my $error = $hostname->check( $lines[ $number - 1 ] ) // next;
				return "Line $number: $error";
			}
			return;
		},
	)
);

$root->add_child( Term::Fabulous::Widget::Text->new( text => 'Tab moves to the next field, Escape quits.', text_color => [ 150, 160, 180, 255 ] ) );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$root->on( KeyPress => sub ($event) { $ui->loop->stop if ( $event->key_name // '' ) eq 'Escape'; return } );
$ui->run;
