use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin qw($Bin);
use lib "$Bin/lib";
use InputTest;
use Term::Fabulous::ThemeEditor::SettingsList;

# A settings list on the 40x20 memory terminal of InputTest, with the
# rows given and a clock for the UI if the first argument is a code
# reference; the ids it activated and the cursor moves it reported.
sub settings_list (@rows) {
	my @options = ref $rows[0] eq 'CODE' ? { clock => shift @rows } : ();
	my %seen    = ( activated => [], cursor => [] );
	my $list    = Term::Fabulous::ThemeEditor::SettingsList->new(
		id          => 'settings',
		on_activate => sub ($id) { push @{ $seen{activated} }, $id; return },
		on_cursor   => sub ($id) { push @{ $seen{cursor} },    $id; return },
	);
	$list->rows( \@rows );
	my $ui = layout_ui( $list, @options );
	return ( $list, $ui, \%seen );
}

# The screen line that shows the setting.
sub line_of ( $ui, $setting ) {
	$ui->step;
	my ($line) = grep { /\b\Q$setting\E\b/ } $ui->terminal->lines;
	return $line;
}

# A click on the terminal at a cell of the screen.
sub click_at ( $ui, $x, $y ) {
	$ui->terminal->click( $x, $y );
	$ui->step;
	return;
}

subtest 'a cut value keeps its clusters whole' => sub {
	my ( $list, $ui ) = settings_list( { id => 'theme.name', setting => 'name', value => "abcdefg\x{2764}\x{FE0F}ijk", origin => 'file', set => 1 } );
	my $line = line_of( $ui, 'name' );
	like $line,   qr/ abcdefg~ /, 'the emoji and its variation selector go together';
	unlike $line, qr/\x{2764}/,   'no heart without its selector is left';
};

subtest 'a double click on a setting activates it' => sub {
	my $now = 1000;
	my ( $list, $ui, $seen ) = settings_list( sub { $now }, map { { id => $_, setting => $_, value => 'on', origin => 'file' } } qw(alpha beta) );
	click_at( $ui, 10, 1 );
	$now += 0.3;
	click_at( $ui, 10, 1 );
	is $seen->{activated}, ['alpha'], 'two clicks 0.3 seconds apart';
	click_at( $ui, 10, 2 );
	$now += 0.5;
	click_at( $ui, 10, 2 );
	is $seen->{activated}, ['alpha'], 'two clicks 0.5 seconds apart are two clicks';
	is $list->cursor,      'beta',    'that put the cursor on the row';
};

# Two sections of settings; only button.color is set.
sub sections () {
	return (
		{
			id       => '#button', setting => 'button', section => 1, value => '',
			children => [ map { { id => "button.$_", setting => $_, value => 'blue', origin => $_ eq 'color' ? 'set' : 'default', set => $_ eq 'color' ? 1 : 0 } } qw(color border) ]
		},
		{ id => '#table', setting => 'table', section => 1, value => '', children => [ { id => 'table.color', setting => 'color', value => 'red', origin => 'default', set => 0 } ] },
	);
}

subtest 'sections open and close, and the cursor moves with them' => sub {
	my ( $list, $ui, $seen ) = settings_list( sections() );
	is [ $list->filtered_row_ids ],        [ '#button', '#table' ],    'every section starts closed';
	is [ $list->cursor, $seen->{cursor} ], [ '#button', ['#button'] ], 'the cursor starts on the first row and says so';
	$list->expand('#button');
	is [ $list->filtered_row_ids ], [ '#button', 'button.color', 'button.border', '#table' ], 'an open section shows its rows';
	$list->cursor('button.border');
	is $list->cursor_index, 2, 'the cursor on a row of it';
	$list->collapse('#button');
	is [ $list->cursor, $seen->{cursor}[-1] ], [ '#button', '#button' ], 'closing the section puts the cursor on the first row shown';
	$list->cursor('table.color');
	is [ $list->is_expanded('#table'), $list->cursor ],                                               [ 1, 'table.color' ],                          'a cursor on a row of a closed section opens it';
	is [ $list->parent_of('table.color'), $list->children_of('#button') ],                            [ '#table', 'button.color', 'button.border' ], 'parent_of and children_of';
	is [ $list->parent_of('nothing'), $list->children_of('nothing'), $list->is_expanded('nothing') ], [ undef, 0 ],                                  'unknown rows have none';
	is $list->row('button.color')->{value},                                                           'blue',                                        'row gives the data';
	ok !exists $list->row('#button')->{children}, 'without the children';
};

subtest 'a search shows the settings it finds with their sections' => sub {
	my ( $list, $ui ) = settings_list( sections() );
	$list->expand('#table');
	$list->search('BLUE');
	is [ $list->filtered_row_ids ], [ '#button', 'button.color', 'button.border' ], 'any case, the sections open, a section with nothing found gone';
	$list->search('button');
	is [ $list->filtered_row_ids ], [ '#button', 'button.color', 'button.border' ], 'the id counts, a section does not match by itself';
	$list->search('table');
	is [ $list->filtered_row_ids ], [ '#table', 'table.color' ], 'only its settings bring a section';
	$list->search('');
	is [ $list->filtered_row_ids ], [ '#button', '#table', 'table.color' ], 'after the search the sections are open as before';
	like dies { $list->search('blue')->cursor('table.color') }, qr/the row 'table.color' is not shown \(a search or filter hides it\)/, 'a cursor on a hidden row dies';
};

subtest 'the only-set filter' => sub {
	my ( $list, $ui ) = settings_list( sections() );
	$list->filter( only_set => sub ($row) { $row->{set} } );
	is [ $list->filtered_row_ids ], [ '#button', 'button.color' ], 'only the settings that pass, in their open sections';
	$list->filter( only_set => undef );
	is [ $list->filtered_row_ids ], [ '#button', '#table' ], 'undef removes it';
};

subtest 'keys fold sections and move the cursor' => sub {
	my ( $list, $ui ) = settings_list( sections() );
	$ui->interaction->set_focused_widget($list);
	press( $list, 'Right' );
	ok $list->is_expanded('#button'), 'Right opens a section';
	press( $list, 'Right' );
	is $list->cursor, 'button.color', 'Right on an open one goes to its first row';
	press( $list, 'Left' );
	is $list->cursor, '#button', 'Left on a row goes to its section';
	press( $list, 'Left' );
	ok !$list->is_expanded('#button'), 'Left on an open section closes it';
	press( $list, 'End' );
	is $list->cursor, '#table', 'End goes to the last row';
	$list->search('red');
	press( $list, 'Left' );
	is [ $list->is_expanded('#table'), $list->cursor ], [ 0, '#table' ], 'while a search shows it open, Left leaves the section alone';
};

done_testing;
