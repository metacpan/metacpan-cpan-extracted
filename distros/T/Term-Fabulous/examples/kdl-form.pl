#!/usr/bin/env perl

# A form of input widgets described in KDL. The program finds the inputs
# by their ids, shows every change in a status line and prints the values
# when it ends.
#
#     perl examples/kdl-form.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Layout;

my $layout = Term::Fabulous::Layout->new( string => <<'KDL' );
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::Text as Text
use Term::Fabulous::Widget::TextField as TextField
use Term::Fabulous::Widget::Checkbox as Checkbox
use Term::Fabulous::Widget::RadioGroup as RadioGroup
use Term::Fabulous::Widget::RadioButton as RadioButton
use Term::Fabulous::Widget::Dropdown as Dropdown
use Term::Fabulous::Widget::Slider as Slider

Box "root" {
	layout direction=down gap=1
	sizing width=grow height=grow
	padding left=2 right=2 top=1 bottom=1

	Text { text "Fill in the form. Tab moves on, F2 shows the values, Ctrl+C ends."; text_color "#dcdcdc"; }

	Box "form" {
		layout direction=down gap=1
		sizing width=grow
		padding left=1 right=1
		border style=Round color="#61afef"
		bordered #true
		background_color "#1c212d"

		Box {
			layout gap=1
			Box { width_group 1; Text { text "Name"; text_color "#96a0b4"; } }
			TextField "name" { placeholder "Your name"; preferred_columns 30; required #true; }
		}
		Box {
			layout gap=1
			Box { width_group 1; Text { text "Password"; text_color "#96a0b4"; } }
			TextField "password" { mask "*"; preferred_columns 30; }
		}
		Box {
			layout gap=1
			Box { width_group 1; Text { text "Size"; text_color "#96a0b4"; } }
			RadioGroup "size" {
				layout direction=right gap=2
				value "m"
				RadioButton { label "Small"; value "s"; }
				RadioButton { label "Medium"; value "m"; }
				RadioButton { label "Large"; value "l"; }
			}
		}
		Box {
			layout gap=1
			Box { width_group 1; Text { text "Color"; text_color "#96a0b4"; } }
			Dropdown "color" {
				placeholder "Pick a color"
				options "Red" "Green" "Blue"
				option "Dark blue" value="navy"
			}
		}
		Box {
			layout gap=1
			Box { width_group 1; Text { text "Volume"; text_color "#96a0b4"; } }
			Slider "volume" { step 5; value 30; value_format "%d%%"; }
		}
		Box {
			layout gap=1
			Box { width_group 1; Text { text "Newsletter"; text_color "#96a0b4"; } }
			Checkbox "newsletter" { label "Send me the newsletter"; }
		}
	}

	Text "status" { text "Nothing changed yet."; text_color "#dcdcdc"; }
}
KDL

my $root = $layout->build;

my %input  = map { $_ => $root->find_by_id($_) } qw(name password size color volume newsletter);
my $status = $root->find_by_id('status');

# The password is shown as stars, here and in the status line.
sub shown_value ( $id, $value ) {
	return '*' x length $value if $id eq 'password';
	return $value // '(none)';
}

sub values_text () {
	return join ', ', map { sprintf '%s=%s', $_, shown_value( $_, $input{$_}->value ) } sort keys %input;
}

# Change events bubble from every input up to the form box.
$root->find_by_id('form')->on(
	Change => sub ($event) {
		my $id = $event->target->id;
		$status->text( sprintf '%s is now %s', $id, shown_value( $id, $event->value ) );
		return;
	}
);

$root->on(
	KeyPress => sub ($event) {
		return unless ( $event->key_name // '' ) eq 'F2';
		my ($invalid) = $root->invalid_inputs;
		$status->text( defined $invalid ? sprintf( '%s: %s', $invalid->id, $invalid->error ) : values_text() );
		return;
	}
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget( $input{name} );
$ui->run;

say values_text();
