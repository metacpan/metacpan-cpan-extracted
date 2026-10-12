#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @users = (
	{ login => 'ada',      name => 'Ada Lovelace',      shell => '/bin/zsh',  uid => 1001, last_login => '2026-05-31 22:14' },
	{ login => 'grace',    name => 'Grace Hopper',      shell => '/bin/bash', uid => 1002, last_login => '2026-06-01 08:02' },
	{ login => 'linus',    name => 'Linus Torvalds',    shell => '/bin/bash', uid => 1003, last_login => '2026-05-28 17:45' },
	{ login => 'margaret', name => 'Margaret Hamilton', shell => '/bin/zsh',  uid => 1004, last_login => '2026-04-12 09:30' },
	{ login => 'ken',      name => 'Ken Thompson',      shell => '/bin/sh',   uid => 1005, last_login => '2026-06-01 07:55' },
	{ login => 'barbara',  name => 'Barbara Liskov',    shell => '/bin/fish', uid => 1006, last_login => '2026-05-30 13:20' },
	{ login => 'dennis',   name => 'Dennis Ritchie',    shell => '/bin/sh',   uid => 1007, last_login => '2026-03-02 11:05' },
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id        => 'users',
	row_id    => 'login',
	selection => 'multiple',
	sort      => ['name'],

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'name',       title => 'Name' },
		{ key => 'shell',      title => 'Shell' },
		{ key => 'uid',        title => 'UID',        type => 'number' },
		{ key => 'last_login', title => 'Last login', type => 'date' },
	],
	rows => \@users,
);

my $help      = Term::Fabulous::Widget::Text->new( text => 'Space selects, Enter opens, a click on a title sorts. q quits.', text_color => [ 150, 160, 180, 255 ] );
my $selected  = Term::Fabulous::Widget::Text->new( text => 'Selected: nothing',                                              text_color => [ 230, 230, 230, 255 ] );
my $activated = Term::Fabulous::Widget::Text->new( text => 'Opened: nothing yet',                                            text_color => [ 229, 192, 123, 255 ] );
$root->add_child( $help, $table, $selected, $activated );

$table->on(
	SelectionChange => sub ($event) {
		my $logins = $event->selected_ids;
		$selected->text( @$logins ? 'Selected: ' . join( ', ', @$logins ) : 'Selected: nothing' );
		return;
	}
);

$table->on(
	RowActivate => sub ($event) {
		my $user = $event->row;
		$activated->text( sprintf 'Opened: %s (%s, uid %d)', $user->{name}, $user->{shell}, $user->{uid} );
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		$ui->loop->stop if $key eq 'q';
		return;
	}
);

$ui->interaction->set_focused_widget($table);
$ui->run;
