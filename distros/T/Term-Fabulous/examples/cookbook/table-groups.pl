#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(date number);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @staff = (
	{ id => 1,  name => 'Ada Lovelace',      team => 'Core',     role => 'Engineer',  started => '2019-03-04', salary => 81000 },
	{ id => 2,  name => 'Grace Hopper',      team => 'Web',      role => 'Lead',      started => '2021-11-15', salary => 92500 },
	{ id => 3,  name => 'Linus Torvalds',    team => 'Core',     role => 'Engineer',  started => '2017-06-01', salary => 90000 },
	{ id => 4,  name => 'Margaret Hamilton', team => 'Platform', role => 'Architect', started => '2016-02-22', salary => 99000 },
	{ id => 5,  name => 'Ken Thompson',      team => 'Core',     role => 'Engineer',  started => '2023-01-09', salary => 70000 },
	{ id => 6,  name => 'Barbara Liskov',    team => 'Platform', role => 'Lead',      started => '2018-09-17', salary => 95500 },
	{ id => 7,  name => 'Dennis Ritchie',    team => 'Core',     role => 'Engineer',  started => '2020-05-11', salary => 78000 },
	{ id => 8,  name => 'Radia Perlman',     team => 'Network',  role => 'Engineer',  started => '2022-08-29', salary => 76000 },
	{ id => 9,  name => 'Tim Berners-Lee',   team => 'Web',      role => 'Engineer',  started => '2020-10-05', salary => 74500 },
	{ id => 10, name => 'Hedy Lamarr',       team => 'Network',  role => 'Lead',      started => '2019-12-02', salary => 88000 },
);

my $money = number( decimals => 0, prefix => '$' );

# The text of a group header: the team, its size and its salaries.
sub team_label ($group) {
	my $total = 0;
	$total += $group->{table}->value( $_, 'salary' ) foreach @{ $group->{ids} };
	return sprintf '%s: %d people, %s per year', $group->{display}, $group->{count}, $money->( $total, {} );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id          => 'staff',
	row_id      => 'id',
	group_by    => 'team',
	group_label => \&team_label,
	group_style => { background_color => [ 40, 45, 58, 255 ], text_color => [ 229, 192, 123, 255 ] },
	sort        => [ [ salary => 'desc' ] ],    # within each group
		# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'name',    title => 'Name' },
		{ key => 'team',    title => 'Team', visible => 0 },    # the group header shows it
		{ key => 'role',    title => 'Role' },
		{ key => 'started', title => 'Started', type => 'date',   mutator => date('%d %b %Y') },
		{ key => 'salary',  title => 'Salary',  type => 'number', mutator => $money },
	],
	rows => \@staff,
);

my $help   = Term::Fabulous::Widget::Text->new( text => 'On a group header, Left closes it, Right opens it, Enter or a click toggles it.', text_color => [ 150, 160, 180, 255 ] );
my $status = Term::Fabulous::Widget::Text->new( text => 'All groups are open.',                                                            text_color => [ 229, 192, 123, 255 ] );
$root->add_child( $help, $table, $status );

$table->on(
	Collapse => sub ($event) {
		my $path = $event->group_path // return;
		$status->text( 'Closed the group ' . join ' / ', @$path );
		return;
	}
);
$table->on(
	Expand => sub ($event) {
		my $path = $event->group_path // return;
		$status->text( 'Opened the group ' . join ' / ', @$path );
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
