#!/usr/bin/env perl

# Term::Fabulous::Widget::Prompt: a list of contacts. n opens a prompt
# with two fields, a name that must be filled in and an e-mail address
# that must look like one; Add checks them and keeps the prompt open
# while something is wrong. d asks before it deletes the last contact,
# starting on the Cancel button. Escape closes a prompt. Ctrl+C quits.
#
#     perl examples/widgets/prompt.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Text::Markup qw(escape_markup);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @contacts = ( 'Grace Hopper <grace@navy.example>', 'Alan Turing <alan@bletchley.example>' );

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $list = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( Term::Fabulous::Widget::Text->new( text => 'Contacts', bold => 1 ), $list, Term::Fabulous::Widget::Text->new( text => 'n adds a contact, d deletes the last one, Ctrl+C quits.' ) );

sub show_contacts () {
	$list->clear_children;
	$list->add_child( map { Term::Fabulous::Widget::Text->new( text => $_ ) } @contacts );
	return;
}
show_contacts();

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# A prompt of your own: two fields that check their values, and a
# primary button that checks them before it answers.
sub add_contact () {
	my $prompt = Term::Fabulous::Widget::Prompt->new(
		title   => 'New contact',
		message => 'The name is required. The e-mail address may stay empty.',
		width   => 56,
		fields  => [
			{ name => 'name',  label => 'Name',   input => Term::Fabulous::Widget::TextField->new( required  => 1,       layout => { sizing => { width => sizing_grow() } } ) },
			{ name => 'email', label => 'E-mail', input => Term::Fabulous::Widget::TextField->new( validator => 'email', layout => { sizing => { width => sizing_grow() } } ) },
		],
		buttons => [ { id => 'add', label => 'Add', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
	);
	$prompt->on(
		Answer => sub ($event) {
			return if $event->button ne 'add';
			my $email = $event->value('email');
			push @contacts, $event->value('name') . ( length $email ? " <$email>" : '' );
			show_contacts();
			return;
		}
	);
	$prompt->open($ui);
	return;
}

# A question in one call, which starts on its Cancel button. The message
# is markup: escape_markup keeps a [ in a name from starting a tag.
sub delete_contact () {
	return unless @contacts;
	Term::Fabulous::Widget::Prompt->confirm(
		$ui,
		title   => 'Delete a contact?',
		message => '[bold]' . escape_markup( $contacts[-1] ) . '[/] is deleted for good.',
		ok      => 'Delete',
		focus   => 'cancel',
	)->on(
		Answer => sub ($event) {
			return if $event->button ne 'ok';
			pop @contacts;
			show_contacts();
			return;
		}
	);
	return;
}

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		return add_contact() if $key eq 'n';
		return delete_contact() if $key eq 'd';
		return Clay::UI::Enum::Result->CONTINUE;
	}
);

$ui->run;
