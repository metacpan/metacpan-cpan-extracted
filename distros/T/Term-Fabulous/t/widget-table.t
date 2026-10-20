use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);
use Scalar::Util qw(refaddr);
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Static;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RIGHT TB_KEY_MOUSE_RELEASE TB_MOD_CTRL TB_MOD_SHIFT TB_MOD_MOTION TF_KEY_MOUSE_MOVE);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Filter;
use Term::Fabulous::Widget::Table::Mutator ();
use Term::Fabulous::Widget::Text;

my @PEOPLE = (
	{ id => 1, name => 'Ann', dept => 'Sales', age => 34 },
	{ id => 2, name => 'Bob', dept => 'IT',    age => 17 },
	{ id => 3, name => 'Cid', dept => 'Sales', age => undef },
	{ id => 4, name => 'Dan', dept => 'HR',    age => 50 },
	{ id => 5, name => 'Eve', dept => 'IT',    age => 23 },
);

my @COLUMNS = ( { key => 'name', title => 'Name' }, { key => 'dept', title => 'Dept' }, { key => 'age', title => 'Age', type => 'number' } );

my @EVENTS = qw(SelectionChange CursorMove RowActivate SortChange PageChange Expand Collapse FilterChange ColumnsChange);

# A focused table on a memory terminal; returns the table and a harness
# with the terminal, the UI and the names of the events fired since the
# last look. A clock goes to the UI.
sub table_ui (%args) {
	my $size  = delete $args{size} // [ 40, 14 ];
	my @clock = exists $args{clock} ? ( clock => delete $args{clock} ) : ();
	my $table = Term::Fabulous::Widget::Table->new( id => 'people', row_id => 'id', columns => [@COLUMNS], rows => [@PEOPLE], %args );
	my $root  = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($table);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => $size->[0], height => $size->[1] );
	my $ui       = Term::Fabulous->new( root => $root, width => $size->[0], height => $size->[1], terminal => $terminal, @clock );
	my %h        = ( terminal => $terminal, ui => $ui, events => [] );

	foreach my $name (@EVENTS) {
		$table->on( $name => sub ($event) { push @{ $h{events} }, [ $name, $event ]; return } );
	}
	$ui->interaction->set_focused_widget($table);
	$ui->step;
	return ( $table, \%h );
}

sub keys_to ( $h, @keys ) {
	$h->{terminal}->press_key($_) foreach @keys;
	$h->{ui}->step;
	return;
}

sub mouse ( $h, %fields ) {
	$h->{terminal}->mouse(%fields);
	$h->{terminal}->mouse( key => TB_KEY_MOUSE_RELEASE, x => $fields{x}, y => $fields{y}, ch => $fields{key} ) if $fields{key} == TB_KEY_MOUSE_LEFT && !( ( $fields{mod} // 0 ) & TB_MOD_MOTION );
	$h->{ui}->step;
	return;
}

sub click ( $h, $x, $y, $mod = 0 ) {
	return mouse( $h, key => TB_KEY_MOUSE_LEFT, x => $x, y => $y, mod => $mod );
}

# The names of the events fired since the last call.
sub fired ($h) {
	my @names = map { $_->[0] } @{ $h->{events} };
	$h->{events} = [];
	return \@names;
}

sub last_event ( $h, $name ) {
	my ($event) = reverse grep { $_->[0] eq $name } @{ $h->{events} };
	return defined $event ? $event->[1] : undef;
}

sub screen ($h) {
	return [ map { s/\s+\z//r } $h->{terminal}->lines ];
}

# The text of the static rendering of a table.
sub static_lines ( $table, $width = 40, $height = 12 ) {
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($table);
	my $ui = Term::Fabulous::Static->new( root => $root, width => $width, height => $height, trim_trailing_whitespace => 1 );
	$ui->draw;
	return [ grep { length } map { s/\s+\z//r } $ui->render_lines( colors => 0 ) ];
}

subtest 'construction' => sub {
	like dies { Term::Fabulous::Widget::Table->new( columns => [] ) }, qr/a table needs an id/, 'an id is required';
	like dies { Term::Fabulous::Widget::Table->new( id      => 't', selection    => 'some' ) }, qr/selection must be one of multiple, none, single, got 'some'/, 'selection';
	like dies { Term::Fabulous::Widget::Table->new( id      => 't', column_lines => 'Dots' ) }, qr/column_lines must be a border style, its name or 'none', got 'Dots'/,
		'line styles';
	like dies { Term::Fabulous::Widget::Table->new( id => 't', header_style => { size => 2 } ) }, qr/header_style does not know size/,                            'style hashes';
	like dies { Term::Fabulous::Widget::Table->new( id => 't', page_sizes   => [0] ) },           qr/page_sizes must be an array reference of positive integers/, 'page sizes';
	like dies { Term::Fabulous::Widget::Table->new( id => 't', colour       => 1 ) },             qr/Unrecognised parameters/,                                    'unknown parameters';
	like dies { Term::Fabulous::Widget::Table->new( id => 't', bordered     => 1 ) },             qr/a table takes no bordered; it draws its frame itself, in the style of border/, 'bordered dies';
	like dies { Term::Fabulous::Widget::Table->new( id => 't' )->bordered(1) }, qr/a table takes no bordered/, 'so does its writer';
};

subtest 'drawing' => sub {
	my $table = Term::Fabulous::Widget::Table->new( id => 't', row_id => 'id', columns => [@COLUMNS], rows => [@PEOPLE], sort => [ [ age => 'desc' ] ] );
	is static_lines($table), [
"\x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{252C}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{252C}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E}",
		"\x{2502} Name \x{2502} Dept  \x{2502} Age \x{25BE} \x{2502}",
"\x{251C}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{253C}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{253C}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2524}",
		"\x{2502} Dan  \x{2502} HR    \x{2502}    50 \x{2502}",
		"\x{2502} Ann  \x{2502} Sales \x{2502}    34 \x{2502}",
		"\x{2502} Eve  \x{2502} IT    \x{2502}    23 \x{2502}",
		"\x{2502} Bob  \x{2502} IT    \x{2502}    17 \x{2502}",
		"\x{2502} Cid  \x{2502} Sales \x{2502}       \x{2502}",
"\x{2570}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2534}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2534}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256F}",
		],
		'a frame, column lines joined to it, the header line, the sort marker, numbers on the right';

	my $empty = Term::Fabulous::Widget::Table->new( id => 'e', columns => [@COLUMNS] );
	like static_lines($empty)->[3], qr/\x{2502} No rows\s+\x{2502}/, 'an empty table says so, as wide as its columns';
	my $none = Term::Fabulous::Widget::Table->new( id => 'n', row_id => 'id', columns => [@COLUMNS], rows => [@PEOPLE] );
	$none->search('zzz');
	like static_lines($none)->[3], qr/No rows match/, 'a table whose filters let nothing through says that';

	my $bare = Term::Fabulous::Widget::Table->new( id => 'b', row_id => 'id', columns => [@COLUMNS], rows => [ $PEOPLE[0] ], header => 0, border => 'none', column_lines => 'none' );
	is static_lines($bare), [' Ann  Sales  34'], 'no header, no lines';

	my $narrow = Term::Fabulous::Widget::Table->new( id => 'w', columns => [ { key => 'a' }, { key => 'b' } ], rows => [ { a => 'xx', b => 'yy' } ] );
	is static_lines( $narrow, 10 ), [
		"\x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{252C}\x{2500}\x{2500}\x{2500}\x{2500}",
		"\x{2502} a  \x{2502} b",
		"\x{251C}\x{2500}\x{2500}\x{2500}\x{2500}\x{253C}\x{2500}\x{2500}\x{2500}\x{2500}",
		"\x{2502} xx \x{2502} yy",
		"\x{2570}\x{2500}\x{2500}\x{2500}\x{2500}\x{2534}\x{2500}\x{2500}\x{2500}\x{2500}",
		],
		'a table too narrow for its columns clips the header and the rows alike';
};

subtest 'groups and trees' => sub {
	my $grouped = Term::Fabulous::Widget::Table->new( id => 'g', row_id => 'id', columns => [@COLUMNS], rows => [@PEOPLE], group_by => 'dept' );
	my $lines   = static_lines( $grouped, 40, 14 );
	like $lines->[2], qr/\x{251C}\x{2500}+\x{2534}\x{2500}+\x{2534}\x{2500}+\x{2524}/, 'the column lines end above a group header';
	like $lines->[3], qr/\x{2502} \x{25BE} Dept: HR \(1\)\s+\x{2502}\z/,               'a group header spans the columns';
	like $lines->[4], qr/\x{2502} Dan\s+\x{2502}/,                                     'its rows follow';
	$grouped->collapse_group('HR');
	$grouped->group_label( sub ($group) { uc( $group->{display} ) . " x$group->{count}" } );
	like static_lines( $grouped, 40, 14 )->[3], qr/\x{25B8} HR x1/, 'a collapsed group, and a group label of your own';

	my $tree = Term::Fabulous::Widget::Table->new(
		id           => 'tree',
		row_id       => 'name',
		children_key => 'kids',
		columns      => [ { key => 'name', title => 'Name' }, { key => 'size', title => 'Size', type => 'number' } ],
		rows => [ { name => 'src', size => 3, kids => [ { name => 'a.c', size => 1 }, { name => 'lib', size => 2, kids => [ { name => 'x.pm', size => 2 } ] } ] }, { name => 'README', size => 1 } ],
	);
	$tree->expand('src');
	my @names = map { /\x{2502}(.*?)\x{2502}/ ? $1 : () } @{ static_lines($tree) }[ 3 .. 6 ];
	is \@names, [ " \x{25BE} src    ", '     a.c  ', "   \x{25B8} lib  ", '   README ' ], 'markers and indentation in the first column';
};

subtest 'keyboard' => sub {
	my ( $table, $h ) = table_ui( selection => 'multiple' );
	is $table->cursor, 1, 'the cursor starts on the first row';
	keys_to( $h, qw(Down Down) );
	is [ $table->cursor, fired($h) ],  [ 3, [qw(CursorMove CursorMove)] ], 'Down moves the cursor';
	is last_event( $h, 'CursorMove' ), undef,                              'fired() forgets the events';
	keys_to( $h, 'Space', 'Shift+Down', 'Shift+Down' );
	is [ $table->selected_ids ], [ 3, 4, 5 ], 'Space selects, Shift+Down extends from there';
	keys_to( $h, 'Space' );
	is [ $table->selected_ids ], [ 3, 4 ], 'Space toggles';
	fired($h);
	keys_to( $h, 'Ctrl+A' );
	is [ [ $table->selected_ids ], fired($h) ], [ [ 1 .. 5 ], ['SelectionChange'] ], 'Ctrl+A selects all';
	keys_to( $h, 'Ctrl+A' );
	is [ $table->selected_ids ], [], 'and again none';
	keys_to( $h, 'Home', 'End' );
	is $table->cursor, 5, 'Home and End';
	keys_to( $h, 'Enter' );
	my ($activate) = grep { $_->[0] eq 'RowActivate' } @{ $h->{events} };
	is [ $activate->[1]->row_id, $activate->[1]->row->{name} ], [ 5, 'Eve' ], 'Enter activates the row';
	keys_to( $h, 'Escape' );
	is $table->cursor, 5, 'other keys are left to the application';
};

subtest 'header keys' => sub {
	my ( $table, $h ) = table_ui();
	keys_to( $h, 'Up', 'Right', 'Right', 'Enter' );
	is [ $table->sort_spec, fired($h) ], [ [ [ age => 'asc' ] ], ['SortChange'] ], 'Up from the first row enters the header; Enter sorts by its column';
	keys_to( $h, 'Enter' );
	is $table->sort_spec, [ [ age => 'desc' ] ], 'again: descending';
	keys_to( $h, 'Left', 'Space' );
	is $table->sort_spec, [ [ age => 'desc' ], [ dept => 'asc' ] ], 'Space adds a column to the sort';
	keys_to( $h, 'Enter', 'Enter' );
	is $table->sort_spec, [], 'Enter sorts by the column alone and cycles back to unsorted';
	fired($h);
	keys_to( $h, 'c' );
	ok $table->is_column_chooser_open, 'c opens the column chooser';
	keys_to( $h, 'Space' );
	is [ [ $table->visible_columns ], fired($h) ], [ [qw(dept age)], ['ColumnsChange'] ], 'which shows and hides columns';
	keys_to( $h, 'Escape' );
	ok !$table->is_column_chooser_open, 'Escape closes it';
	is refaddr( $h->{ui}->interaction->get_focused_widget ), refaddr($table), 'and the table has the focus again';
	keys_to( $h, 'Down', 'Down' );
	is $table->cursor, 2, 'Down leaves the header';
};

subtest 'mouse' => sub {
	my ( $table, $h ) = table_ui( selection => 'multiple', clock => sub { 1000 } );    # every click is quick

	# The selection column is 5 cells wide, the rows start on screen row 3.
	click( $h, 8, 4 );
	is [ [ $table->selected_ids ], $table->cursor, fired($h) ], [ [2], 2, [qw(CursorMove SelectionChange)] ], 'a click selects the row alone';
	click( $h, 8, 6, TB_MOD_CTRL );
	is [ $table->selected_ids ], [ 2, 4 ], 'Ctrl+click adds';
	click( $h, 2, 4 );
	is [ $table->selected_ids ], [4], 'a click on the selection column toggles';
	click( $h, 8, 3 );
	click( $h, 8, 5, TB_MOD_SHIFT );
	is [ $table->selected_ids ], [ 1, 2, 3 ], 'Shift+click selects a range';
	click( $h, 2, 1 );
	is [ $table->selected_ids ], [ 1 .. 5 ], 'the selection column header selects all';
	fired($h);
	click( $h, 9, 1 );
	is [ $table->sort_spec, fired($h) ], [ [ [ name => 'asc' ] ], ['SortChange'] ], 'a click on a header sorts';
	click( $h, 17, 1, TB_MOD_CTRL );
	is $table->sort_spec, [ [ name => 'asc' ], [ dept => 'asc' ] ], 'Ctrl+click adds to the sort';
	click( $h, 9, 7 );
	click( $h, 9, 7 );
	is [ map { $_->row_id } map { $_->[1] } grep { $_->[0] eq 'RowActivate' } @{ $h->{events} } ], [5], 'a double click activates';
	mouse( $h, key => TB_KEY_MOUSE_RIGHT, x => 9, y => 1 );
	ok $table->is_column_chooser_open, 'a right click on the header opens the column chooser';
};

subtest 'double clicks on the clock of the UI' => sub {
	my $now = 1000;
	my ( $table, $h ) = table_ui( clock => sub { $now } );
	my $activated = sub {
		[ map { $_->[1]->row_id } grep { $_->[0] eq 'RowActivate' } splice @{ $h->{events} } ]
	};
	click( $h, 9, 7 );
	$now += 0.3;
	click( $h, 9, 7 );
	is $activated->(), [5], 'two clicks 0.3 seconds apart activate the row';
	click( $h, 9, 7 );
	is $activated->(), [], 'a third quick click is a single click';
	click( $h, 9, 7 );
	is $activated->(), [5], 'and a fourth a double click again';
	$now += 1;
	click( $h, 9, 6 );
	$now += 0.5;
	click( $h, 9, 6 );
	is $activated->(), [], 'two clicks 0.5 seconds apart do not';
	click( $h, 9, 5 );
	click( $h, 9, 6 );
	is $activated->(), [], 'nor two quick clicks on two lines';
};

subtest 'the column chooser stays on the screen' => sub {
	my @columns = map { { key => "c$_", title => "Column $_" } } 1 .. 8;
	my $table   = Term::Fabulous::Widget::Table->new(
		id     => 'wide', row_id => 'id', columns => \@columns, rows => [ { id => 1 } ],
		layout => { sizing => { width => sizing_grow(), height => sizing_fixed(5) } }
	);
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child( Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_fixed(15) } } ), $table );
	my $ui = Term::Fabulous->new( root => $root, width => 40, height => 20, terminal => Term::Fabulous::Terminal::Memory->new( width => 40, height => 20 ) );
	$ui->step;
	is $ui->bounding_box($table)->{y}, 15, 'the table starts at row 15 of 20';
	$table->open_column_chooser;
	$ui->step;
	my ($chooser) = grep { $_->isa('Term::Fabulous::Widget::Table::ColumnChooser') } @{ $table->children };
	my $box = $ui->bounding_box($chooser);
	is [ @{$box}{qw(y height)} ], [ 8, 12 ], 'the chooser of 12 rows moves up to end at the bottom of the screen';
	is $box->{x} + $box->{width}, 40,        'at the right edge of the table';
	my @lines = $ui->terminal->lines;
	like $lines[18], qr/Esc closes/, 'its last line shows';
};

subtest 'mouse on trees and groups' => sub {
	my ( $table, $h ) = table_ui( group_by => 'dept' );
	click( $h, 4, 3 );
	is [ $table->is_group_expanded('HR'), fired($h) ], [ 0, ['Collapse'] ], 'a click on a group header closes it (the cursor was on it)';
	is last_event( $h, 'Collapse' ),                   undef,               'fired() forgot it';
	click( $h, 4, 3 );
	ok $table->is_group_expanded('HR'), 'and opens it again';

	my ( $tree, $t ) = table_ui( children_key => 'kids', rows => [ { id => 1, name => 'src', kids => [ { id => 2, name => 'x.c' } ] } ] );
	click( $t, 7, 3 );
	is $tree->is_expanded(1), 0, 'a click beside the marker does not open the row';
	click( $t, 2, 3 );
	is [ $tree->is_expanded(1), $tree->page_row_ids ], [ 1, 1, 2 ], 'a click on the marker does';
	keys_to( $t, 'Left' );
	is $tree->is_expanded(1), 0, 'Left closes it';
	keys_to( $t, 'Right', 'Right' );
	is $tree->cursor, 2, 'Right opens it, and goes to the first child';
	keys_to( $t, 'Left' );
	is $tree->cursor, 1, 'Left on a child goes to its parent';
};

subtest 'selection modes' => sub {
	my ( $single, $h ) = table_ui( selection => 'single' );
	keys_to( $h, 'Down' );
	is [ $single->selected_ids ], [2], 'single: the selection follows the cursor';
	like dies { $single->select( 1, 2 ) }, qr/selects one row at most/, 'and holds one row';
	$single->selection('multiple');
	ok $single->selection_column, 'multiple mode shows the selection column';
	$single->selection('none');
	is [ $single->selected_ids ], [], 'none drops the selection';
	like dies { $single->select(1) }, qr/nothing can be selected/, 'and allows none';

	my ( $multiple, $m ) = table_ui( selection => 'multiple' );
	keys_to( $m, 'Space' );
	my ($ann) = grep { /Ann/ } @{ screen($m) };
	like $ann, qr/\[x\]/, 'the mark of the cursor line shows the selection at once';
	is scalar( $multiple->selected_ids ), 1, 'selected_ids counts in scalar context';
};

subtest 'turning the page moves the cursor like any user move' => sub {
	my ( $single, $h ) = table_ui( selection => 'single', page_size => 2 );
	keys_to( $h, 'Ctrl+PageDown' );
	is [ [ $single->selected_ids ], fired($h) ], [ [3], [qw(CursorMove PageChange SelectionChange)] ], 'single mode selects the new cursor row';

	my ( $multiple, $m ) = table_ui( selection => 'multiple', page_size => 2 );
	keys_to( $m, 'Down', 'Ctrl+PageDown', 'Shift+Down' );
	is [ $multiple->selected_ids ], [ 3, 4 ], 'a range starts on the new page';

	my ( $unpaged, $u ) = table_ui( selection => 'multiple' );
	keys_to( $u, 'Down' );
	$unpaged->cursor(4);
	keys_to( $u, 'Shift+Down' );
	is [ $unpaged->selected_ids ], [ 4, 5 ], 'and where the program put the cursor';
};

subtest 'clicks on a button without a background in a cell' => sub {
	my ( $table, $h ) = table_ui(
		selection => 'multiple',
		columns   => [
			{ key => 'name', title => 'Name' },
			{
				key   => 'go',
				title => 'Go',
				cell  => sub ($cell) {
					my $button = Term::Fabulous::Widget::Button->new;
					$button->add_child( Term::Fabulous::Widget::Text->new( text => 'go', text_color => '#ffffff' ) );
					return $button;
				},
			},
		],
	);
	my @lines = @{ screen($h) };
	my ($row) = grep { $lines[$_] =~ /Bob/ } 0 .. $#lines;
	my $x     = index( $lines[$row], 'go' );
	click( $h, $x, $row );
	click( $h, $x, $row );
	is [ $table->cursor, [ $table->selected_ids ], [ grep { $_ eq 'RowActivate' } @{ fired($h) } ] ], [ 2, [], [] ], 'move the cursor only';
};

subtest 'data changes in a filtered tree show new matches' => sub {
	my $tree = Term::Fabulous::Widget::Table->new(
		id           => 'tree',
		row_id       => 'name',
		children_key => 'kids',
		columns      => [ { key => 'name', title => 'Name' }, { key => 'note', title => 'Note' } ],
		rows         => [ { name => 'a', kids => [ { name => 'a1' }, { name => 'a2' } ] }, { name => 'zz' } ],
	);
	$tree->search('zz');
	$tree->set_value( a2 => note => 'zz' );
	is [ $tree->page_row_ids ], [qw(a a2 zz)], 'the parent of a new match opens';
};

subtest 'rows given again with the same ids show their new values' => sub {
	my ( $table, $h ) = table_ui();
	$table->rows(
		[
			map {
				{ %$_, name => uc $_->{name} }
			} @PEOPLE
		]
	);
	$h->{ui}->step;
	my $shown = join "\n", @{ screen($h) };
	like $shown,   qr/ANN.*BOB.*CID.*DAN.*EVE/s, 'rows() with the same ids';
	unlike $shown, qr/Ann|Bob/,                  'no old text is left';

	$table->remove_row(2);
	$table->add_row( { id => 2, name => 'Zed', dept => 'Ops', age => 99 }, index => 1 );
	$h->{ui}->step;
	my ($second) = grep { /Zed/ } @{ screen($h) };
	like $second, qr/Zed\s.*Ops\s.*99/, 'a row removed and added again with its id between two frames';
};

subtest 'colors and checks after construction' => sub {
	my ( $table, $h ) = table_ui( page_size => 2, size => [ 50, 14 ] );
	$table->muted_color('#ff0000');
	$h->{ui}->step;
	my @lines = @{ screen($h) };
	my ($row) = grep { $lines[$_] =~ /of 5/ } 0 .. $#lines;
	is $h->{terminal}->cell( index( $lines[$row], 'of 5' ), $row )->[1] & 0xFFFFFF, 0xFF0000, 'a new muted_color reaches the pager';
	like dies { $table->filter_error('nope') }, qr/there is no column 'nope'/, 'filter_error checks the column';
};

subtest 'the focus survives a cell widget that goes away' => sub {
	my ( $table, $h ) = table_ui(
		columns => [
			{ key => 'name', title => 'Name' },
			{
				key   => 'remove',
				title => '',
				cell  => sub ($cell) {
					my $button = Term::Fabulous::Widget::Button->new;
					$button->add_child( Term::Fabulous::Widget::Text->new( text => 'x', text_color => '#ffffff' ) );
					$button->on( Activate => sub ($event) { $cell->{table}->remove_row( $cell->{id} ); return } );
					return $button;
				},
			},
		],
	);
	$h->{ui}->interaction->set_focused_widget( $table->cell_widget( 1, 'remove' ) );
	keys_to( $h, 'Enter' );
	$h->{ui}->step;
	is [ $table->has_row(1), refaddr( $h->{ui}->interaction->get_focused_widget // 0 ) ], [ 0, refaddr($table) ], 'the table takes the focus back';
};

subtest 'programmatic changes fire no events' => sub {
	my ( $table, $h ) = table_ui( selection => 'multiple', page_size => 2 );
	$table->select(1);
	$table->cursor(2);
	$table->sort_by('name');
	$table->page(2);
	$table->filter_text( name => 'a' );
	$table->hide_columns('dept');
	$h->{ui}->step;
	is fired($h), [], 'none at all';
};

subtest 'pages' => sub {
	my ( $table, $h ) = table_ui( page_size => 2, size => [ 50, 14 ] );
	like join( "\n", @{ screen($h) } ), qr/Page 1 of 3.*1\x{2013}2 of 5/s, 'the pager';
	keys_to( $h, 'Ctrl+PageDown' );
	is [ $table->page, [ $table->page_row_ids ], fired($h) ], [ 2, [ 3, 4 ], [ 'CursorMove', 'PageChange' ] ], 'Ctrl+PageDown turns the page and moves the cursor';
	keys_to( $h, 'Down', 'Down', 'Down' );
	is [ $table->page, $table->cursor ], [ 2, 4 ], 'the cursor stays on the page';
	my ($last) = grep { /\x{00BB}/ } @{ screen($h) };
	my $x      = index $last, "\x{00BB}";
	my ($y)    = grep { screen($h)->[$_] =~ /\x{00BB}/ } 0 .. $#{ screen($h) };
	click( $h, $x, $y );
	is [ $table->page, last_event( $h, 'PageChange' )->page ], [ 3, 3 ], 'the pager buttons';
	$table->page_size(10);
	$h->{ui}->step;
	is [ $table->page_count, $table->page ], [ 1, 1 ], 'page_size';
};

subtest 'filter row' => sub {
	my ( $table, $h ) = table_ui( filter_row => 1 );
	click( $h, 3, 2 );
	$h->{terminal}->type_text('a');
	$h->{ui}->step;
	is [ [ $table->page_row_ids ], fired($h) ], [ [ 1, 4 ], ['FilterChange'] ], 'typing into a field filters by the display text';
	click( $h, 19, 2 );
	$h->{terminal}->type_text('>x');
	$h->{ui}->step;
	like last_event( $h, 'FilterChange' )->error, qr/'>x' is not a number filter/, 'an invalid expression reports why';
	is [ $table->page_row_ids ], [ 1, 4 ], 'and does not filter';
	like $table->filter_error('age'), qr/not a number filter/, 'filter_error';
	keys_to( $h, 'Backspace', 'Backspace', '>', '4', '0' );
	is [ $table->page_row_ids ], [4], 'a number filter';
	keys_to( $h, 'Escape' );
	is [ $table->filter_text('age'), [ $table->page_row_ids ] ], [ '', [ 1, 4 ] ], 'Escape clears the field';
	keys_to( $h, 'Down' );
	is refaddr( $h->{ui}->interaction->get_focused_widget ), refaddr($table), 'Down goes to the rows';
	$table->clear_filters;
	$h->{ui}->step;
	is [ $table->page_row_ids ], [ 1 .. 5 ], 'clear_filters empties the fields';
};

subtest 'cells of your own' => sub {
	my @made;
	my ( $table, $h ) = table_ui(
		columns => [
			{ key => 'name', title => 'Name' },
			{
				key         => 'done',
				title       => 'Done',
				cell        => sub ($cell) { my $box = Term::Fabulous::Widget::Checkbox->new( checked => $cell->{value} ? 1 : 0 ); push @made, $box; $box },
				update_cell => sub ( $box, $cell ) { $box->checked( $cell->{value} ? 1 : 0 ) },
			},
			{
				key        => 'age', title => 'Age', type => 'number', mutator => Term::Fabulous::Widget::Table::Mutator::number( decimals => 1 ),
				cell_style => sub ($cell) { ( $cell->{value} // 0 ) > 30 ? { text_color => '#ff0000' } : undef }
			},
		],
	);
	is scalar @made, 5, 'a cell widget per row';
	my $box = $table->cell_widget( 1, 'done' );
	$table->set_value( 1, done => 1 );
	$table->set_value( 1, age  => 35 );
	$h->{ui}->step;
	is [ scalar @made, $box->checked ], [ 5, 1 ], 'update_cell keeps the widget';
	like join( "\n", @{ screen($h) } ), qr/35\.0/, 'default cells show the new value';
	my @lines = $h->{terminal}->lines;
	my ($row) = grep { $lines[$_] =~ /Ann/ } 0 .. $#lines;
	my $x     = index( $lines[$row], '35.0' );
	is $h->{terminal}->cell( $x, $row )->[1] & 0xFFFFFF, 0xFF0000, 'cell_style colors the cell';
};

subtest 'styles and borders' => sub {
	my $table = Term::Fabulous::Widget::Table->new( id => 's', row_id => 'id', columns => [@COLUMNS], rows => [ @PEOPLE[ 0, 1 ] ] );
	$table->set_row_style( 2, { border_top => 'Double' } );
	$table->set_cell_style( 1, 'dept', { border_left => 'Heavy' } );
	my $lines = static_lines($table);
	like $lines->[3], qr/\x{2502} Ann  \x{2503} Sales/, 'a cell border';
	like $lines->[4], qr/\x{255E}\x{2550}+\x{256A}/,    'a row border, joined with the column lines';
	is $table->row_style_of(2), { border_top => Term::Fabulous::Enum::BorderStyle->Double }, 'row_style_of';
	like dies { $table->set_row_style( 1, { colour => 'red' } ) }, qr/row style does not know colour/, 'style keys are checked';

	my ( $styled, $h ) = table_ui(
		header_style => { background_color => '#ff0000', text_color => '#00ff00' },
		columns      => [ { key => 'name', title => 'Name', header_style => { background_color => '#0000ff' } }, { key => 'dept', title => 'Dept' } ],
	);
	my @lines   = $h->{terminal}->lines;
	my ($at)    = grep { $lines[$_] =~ /Name/ } 0 .. $#lines;
	my $cell_of = sub ($title) { $h->{terminal}->cell( index( $lines[$at], $title ), $at ) };
	is [ map { $_ & 0xFFFFFF } @{ $cell_of->('Dept') }[ 1, 2 ] ], [ 0x00FF00, 0xFF0000 ], 'the table header_style colors header cells';
	is $cell_of->('Name')->[2] & 0xFFFFFF,                        0x0000FF,               'a column header_style wins over the table one';
};

subtest 'scrolling' => sub {
	my ( $table, $h ) = table_ui( rows => [ map { { id => $_, name => "n$_", dept => 'd', age => $_ } } 1 .. 30 ], size => [ 40, 10 ], layout => { sizing => { height => sizing_grow() } } );
	keys_to( $h, ('PageDown') x 3 );
	my $cursor = $table->cursor;
	ok $cursor > 10, 'PageDown moves by what the body shows';
	ok( ( grep { /\bn$cursor\b/ } @{ screen($h) } ), 'the cursor row is scrolled into view' );
	ok !( grep { /\bn1\b/ } @{ screen($h) } ), 'the first rows scrolled away';
	keys_to( $h, 'Ctrl+Home' );
	ok( ( grep { /\bn1\b/ } @{ screen($h) } ), 'and come back' );

	my $early = Term::Fabulous::Widget::Table->new( id => 'early', row_id => 'id', columns => [@COLUMNS], rows => [ map { { id => $_, name => "n$_", dept => 'd', age => $_ } } 1 .. 30 ] );
	$early->cursor(25);
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($early);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 10 );
	my $ui       = Term::Fabulous->new( root => $root, width => 40, height => 10, terminal => $terminal );
	$ui->step for 1 .. 2;
	ok( ( grep { /\bn25\b/ } @{ screen( { terminal => $terminal } ) } ), 'a cursor set before the table was in a UI is scrolled into view after the first frame' );
};

subtest 'the frame stays while the rows scroll' => sub {
	my ( $table, $h ) = table_ui( rows => [ map { { id => $_, name => "n$_", dept => 'd', age => $_ } } 1 .. 30 ], size => [ 40, 10 ], layout => { sizing => { height => sizing_grow() } } );
	my $lines = screen($h);
	like $lines->[0],   qr/\A\x{256D}\x{2500}+\x{252C}.*\x{2500}\x{256E}\z/, 'the top of the frame runs on over the scrollbar column';
	like $lines->[9],   qr/\A\x{2570}\x{2500}+\x{2534}.*\x{2500}\x{256F}\z/, 'the bottom of the frame is the last line';
	like $lines->[3],   qr/\bn1\b.*\x{2503}\x{2502}\z/,                      'the scrollbar is inside the frame, right of the last column';
	unlike $lines->[1], qr/\x{2502}\s\x{2502}\z/,                            'the header has no line left of the scrollbar column';
	keys_to( $h, 'Ctrl+End' );
	$lines = screen($h);
	ok( ( grep { /\bn30\b/ } @$lines ), 'the last row is in view' );
	like $lines->[9], qr/\A\x{2570}.*\x{256F}\z/, 'and the bottom of the frame still is';

	my ( $bare, $g )
		= table_ui( rows => [ map { { id => $_, name => "n$_", dept => 'd', age => $_ } } 1 .. 30 ], header => 0, size => [ 40, 10 ], layout => { sizing => { height => sizing_grow() } } );
	keys_to( $g, 'Ctrl+End' );
	$lines = screen($g);
	like $lines->[0], qr/\A\x{256D}\x{2500}+\x{252C}/, 'without column titles, the top of the frame stays too';
	ok( ( grep { /\bn30\b/ } @$lines ), 'with the last row in view' );

	my ( $fits, $f ) = table_ui( size => [ 40, 14 ] );
	$lines = screen($f);
	like $lines->[3], qr/\x{2502} Ann\s+\x{2502} Sales \x{2502}\s+34 \x{2502}\z/, 'rows that fit have no scrollbar column';
};

subtest 'a growing column wraps its text instead of scrolling sideways' => sub {
	my $text = 'The quick brown fox jumps over the lazy dog and keeps on running far away';
	my ( $table, $h ) = table_ui(
		columns => [ { key => 'id', title => 'Id' }, { key => 'text', title => 'Text', width => 'grow' } ],
		rows    => [ { id  => 1,    text  => $text } ],
		layout  => { sizing => { width => sizing_grow() } },
	);
	my @rows = grep { /\x{2502}/ } @{ screen($h) };
	ok !( grep { !/\x{2502}\z/ } @rows ), 'every row ends at the right side of the frame';
	ok( ( grep { /\x{2502} running far away\s+\x{2502}/ } @rows ), 'the text wraps in the column' );
	$table->update_column( text => width => 'fit' );
	$h->{ui}->step;
	ok( ( grep { /The quick brown fox jumps over th\z/ } @{ screen($h) } ), 'a fit column keeps its text on one line and scrolls sideways' );
};

subtest 'a growing column cuts off a word that is longer than its width' => sub {
	my ( $table, $h ) = table_ui(
		columns => [ { key => 'id', title => 'Id' }, { key => 'url', title => 'URL', width => 'grow', wrap => 'none' } ],
		rows    => [ { id  => 1,    url   => 'https://example.com/a/very/long/path/without/any/spaces/in/it' } ],
		layout  => { sizing => { width => sizing_grow() } },
	);
	my @rows = grep { /\x{2502}/ } @{ screen($h) };
	ok !( grep { !/\x{2502}\z/ } @rows ), 'every row ends at the right side of the frame';
	ok( ( grep { /\x{2502} https:\/\/example\.com\S*\s*\x{2502}\z/ } @rows ), 'the word is cut off inside the column' );
};

subtest 'a percent column keeps its share of the width with a long text' => sub {
	my ( $table, $h ) = table_ui(
		columns => [ { key => 'key', title => 'Key', width => 'percent(40)', wrap => 'none' }, { key => 'value', title => 'Value', width => 'grow', wrap => 'none' } ],
		rows    => [ { id  => 1,     key   => 'extraKnownMarketplaces.claude-globals.source.path', value => 'directory' } ],
		layout  => { sizing => { width => sizing_grow() } },
	);
	my @lines = @{ screen($h) };
	my @rows  = grep { /\x{2502}/ } @lines;
	ok !( grep { !/\x{2502}\z/ } @rows ), 'every row ends at the right side of the frame';
	ok( index( $lines[0], "\x{252C}" ) <= 17, 'the key column is about 40% of the 40 columns wide' );
};

subtest 'hover and scrollbar' => sub {
	my ( $table, $h ) = table_ui( rows => [ map { { id => $_, name => "n$_", dept => 'd', age => $_ } } 1 .. 30 ], size => [ 40, 10 ], layout => { sizing => { height => sizing_grow() } } );
	my $plain = $h->{terminal}->cell( 3, 5 )->[2];
	mouse( $h, key => TF_KEY_MOUSE_MOVE, x => 3, y => 5 );
	isnt $h->{terminal}->cell( 3, 5 )->[2], $plain, 'the row under the pointer is highlighted';
	is $h->{terminal}->cell( 3, 6 )->[2],   $plain, 'only that row';

	my ($bar_x) = grep { ( $h->{terminal}->cell( $_, 3 ) // [''] )->[0] eq "\x{2503}" } 0 .. 39;
	ok defined $bar_x, 'a scrollbar shows the thumb';
	mouse( $h, key => TB_KEY_MOUSE_LEFT, x => $bar_x, y => 8 );
	ok( ( grep { /\bn30\b/ } @{ screen($h) } ), 'a click at the end of the scrollbar shows the end' );
	mouse( $h, key => TB_KEY_MOUSE_LEFT, x => $bar_x, y => 3, mod => TB_MOD_MOTION );
	ok( ( grep { /\bn1\b/ } @{ screen($h) } ), 'dragging to the top shows the start' );
};

subtest 'keys on groups' => sub {
	my ( $table, $h ) = table_ui( group_by => 'dept' );
	is $table->cursor_group, ['HR'], 'the cursor is on the first group header';
	keys_to( $h, 'Left' );
	is [ $table->is_group_expanded('HR'), fired($h) ], [ 0, ['Collapse'] ], 'Left closes a group';
	keys_to( $h, '+' );
	is [ $table->is_group_expanded('HR'), fired($h) ], [ 1, ['Expand'] ], '+ opens it';
	keys_to( $h, 'Right' );
	is $table->cursor, 4, 'Right on an open group goes into it';
	keys_to( $h, 'Left' );
	is $table->cursor_group, ['HR'], 'Left on one of its rows goes back to the group';
	keys_to( $h, 'Enter' );
	ok !$table->is_group_expanded('HR'), 'Enter on a group header toggles it';
	$table->collapse_all_groups;
	$h->{ui}->step;
	is [ map { $_->{kind} } $table->model->page_lines ], [qw(group group group)], 'collapse_all_groups';
};

subtest 'looks' => sub {
	my $table = Term::Fabulous::Widget::Table->new(
		id           => 'looks',
		row_id       => 'id',
		rows         => [ @PEOPLE[ 0 .. 2 ] ],
		stripe_color => '#102030',
		row_style    => sub ( $row, $id ) { $row->{name} eq 'Cid' ? { background_color => '#400000', bold => 1 } : undef },
		columns      => [ { key => 'name', title => 'Name', header => sub ($column) { Term::Fabulous::Widget::Text->new( text => '*' . $column->title . '*' ) } }, { key => 'dept', title => 'Dept' } ],
	);
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($table);
	my $ui = Term::Fabulous::Static->new( root => $root, width => 30, height => 8 );
	$ui->draw;
	like( ( $ui->render_lines )[1], qr/\*Name\*/, 'a header widget of your own' );
	is $ui->cell( 2, 5 )->[2] & 0xFFFFFF, 0x400000, 'row_style colors a row';
	ok $ui->cell( 2, 5 )->[1] & Term::Fabulous::Termbox::TB_BOLD(), 'and makes it bold';
	is $ui->cell( 2, 4 )->[2] & 0xFFFFFF, 0x102030, 'every other row is striped';
};

subtest 'a line between two colors takes the table background' => sub {
	my $table = Term::Fabulous::Widget::Table->new( id => 'lines', row_id => 'id', row_lines => 'Solid', rows => [ @PEOPLE[ 0 .. 2 ] ], columns => [ @COLUMNS[ 0, 1 ] ] );
	$table->set_row_style( 2, { background_color => '#400000' } );
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($table);
	my $ui = Term::Fabulous::Static->new( root => $root, width => 30, height => 10 );
	$ui->draw;
	my @lines    = $ui->render_lines( colors => 0 );
	my ($bob)    = grep { $lines[$_] =~ /Bob/ } 0 .. $#lines;
	my $column_x = index( $lines[$bob], "\x{2502}", 1 );
	my $bg_at    = sub ( $x, $y ) { $ui->cell( $x, $y )->[2] & 0xFFFFFF };
	is $bg_at->( $column_x, $bob ),     0x400000, 'a column line inside a colored row keeps its color';
	is $bg_at->( $column_x, $bob - 1 ), 0x16191F, 'the junction above the row does not';
	is $bg_at->( 2,         $bob - 1 ), 0x16191F, 'nor the row line above it';
	is $bg_at->( 2,         $bob + 1 ), 0x16191F, 'nor the one below it';
	is $bg_at->( 2,         2 ),        0x16191F, 'the line under the titles takes neither color';
};

subtest 'columns' => sub {
	my ( $table, $h ) = table_ui();
	$table->hide_columns('dept');
	$table->move_column( age => 0 );
	$table->update_column( name => title => 'Who' );
	$h->{ui}->step;
	like screen($h)->[1], qr/\x{2502} Age \x{2502} Who \x{2502}/, 'hide, move and change columns';
	$table->add_column( { key => 'dept', title => 'Dept' } ) for ();
	$table->remove_column('age');
	$h->{ui}->step;
	like screen($h)->[1],                                      qr/\x{2502} Who \x{2502}\z/, 'remove a column';
	like dies { $table->update_column( name => key => 'x' ) }, qr/cannot change the key/,   'keys stay';
};

subtest 'KDL' => sub {
	my $layout = Term::Fabulous::Layout->new( string => <<'KDL' );
use Term::Fabulous::Widget::Table as Table
Table "inventory" {
	selection multiple
	row_id "sku"
	page_size 3
	lines frame=Double columns=Solid header=Heavy
	column "sku" title="SKU"
	column "qty" title="Qty" type=number {
		style text_color="#e5c07b" border_left=Heavy
	}
	sort "qty" "desc"
}
KDL
	my $table = $layout->build;
	$table->rows( [ map { { sku => "A$_", qty => $_ } } 1 .. 4 ] );
	is [ $table->selection, $table->page_size, $table->column_keys, $table->sort_spec ], [ 'multiple', 3, 'sku', 'qty', [ [ qty => 'desc' ] ] ], 'properties';
	like static_lines($table)->[0], qr/\x{2554}/, 'lines';
	like dies { Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Table as Table\nuse Term::Fabulous::Widget::Text as Text\nTable \"t\" {\n\tText\n}" )->build },
		qr/a table takes no child widgets/, 'child widgets die';
};

subtest 'a search reaches every page, and revealing a match turns to its page' => sub {
	my ( $table, $h ) = table_ui( page_size => 2 );
	ok $table->DOES('Term::Fabulous::Role::Searchable'), 'a table is searchable';
	my %text_of = map { join( '/', @{ $_->[0] } ) => $_->[1] } $table->search_texts;
	is $text_of{'5/name'}, 'Eve', 'a row on the last page is among the texts';
	is $text_of{'3/age'},  '',    'an undefined value is an empty text';
	is [ map { join '/', @{ $_->[0] } } $table->search_texts ], [
		map {
			my $id = $_;
			map { "$id/$_" } qw(name dept age)
		} 1 .. 5
		],
		'in row order, column by column';
	my $revision = $table->search_revision( [ 5, 'name' ] );
	$table->highlight_text( [ 5, 'name' ], [ [ 0, 2, 'on accent' ] ] );
	like dies { $table->highlight_text( [ 5, 'name' ], [ [ 0, 99, 'on accent' ] ] ) }, qr/highlight end 99 lies past the text \(3 characters\)/,
		'offsets past the text of a row that is not built die at the call';
	is $table->reveal_text( [ 5, 'name' ], 0 ), [ undef, undef ], 'before the table was prepared again, the cell has no widget yet';
	$h->{ui}->step;
	is [ $table->page, $table->cursor ], [ 3, 5 ], 'the page turned and the cursor is on the row';
	my ($text) = @{ $table->reveal_text( [ 5, 'name' ], 0 ) };
	ref_is $text, $table->cell_widget( 5, 'name' ), 'now the cell text is there';
	is $text->highlights->[0][1],                2,         'with the highlights the search set before it was built';
	is $table->search_revision( [ 5, 'name' ] ), $revision, 'the revision stayed';
	$table->update_row( 5, { name => 'Eva' } );
	$h->{ui}->step;
	isnt $table->search_revision( [ 5, 'name' ] ),   $revision, 'a changed row has another revision';
	is $table->cell_widget( 5, 'name' )->highlights, [],        'and its highlights are gone';
	is $table->search_revision( [ 9, 'name' ] ),     'gone',    'a row that does not exist is gone';
	$table->clear_text_highlights;
	like dies { $table->highlight_text( 'x', [] ) }, qr/highlight_text needs a key of \[ row id, column key \]/, 'keys are checked';
};

subtest 'revealing a match expands the rows and groups above it' => sub {
	my ( $table, $h ) = table_ui(
		children_key => 'children',
		rows         => [
			{ id => 1, name => 'Ann', dept => 'Sales', children => [ { id => 2, name => 'Bob', dept => 'Sales', children => [ { id => 3, name => 'Cid', dept => 'Sales' } ] } ] },
			{ id => 4, name => 'Dan', dept => 'HR' }
		],
	);
	my %text_of = map { join( '/', @{ $_->[0] } ) => $_->[1] } $table->search_texts;
	is $text_of{'3/name'}, 'Cid', 'a row under collapsed rows is among the texts';
	$table->reveal_text( [ 3, 'name' ], 0 );
	$h->{ui}->step;
	is [ $table->is_expanded(1), $table->is_expanded(2), $table->cursor ], [ 1, 1, 3 ], 'its ancestors are expanded and the cursor is on it';

	$table->group_by('dept');
	$table->collapse_group('HR');
	$h->{ui}->step;
	$table->reveal_text( [ 4, 'name' ], 0 );
	$h->{ui}->step;
	is [ $table->is_group_expanded('HR'), $table->cursor ], [ 1, 4 ], 'a collapsed group is opened for its row';
};

subtest 'the widgets of a custom cell are searched while the row is built' => sub {
	my ( $table, $h ) = table_ui(
		columns => [
			{ key => 'name', title => 'Name' }, { key => 'age', title => 'Age', cell => sub ($cell) { return Term::Fabulous::Widget::Text->new( text => 'aged ' . ( $cell->{row}{age} // '?' ) ) } }
		],
		page_size => 2,
	);
	my %text_of = map {
		join( '/', map { $_ // '-' } @{ $_->[0] } ) => $_->[1]
	} $table->search_texts;
	is $text_of{'1/age/0/-'}, 'aged 34', 'a text inside the cell widget of a built row';
	ok !exists $text_of{'5/age/0/-'}, 'not of a row on another page';
	$table->highlight_text( [ 1, 'age', 0, undef ], [ [ 0, 4, 'on accent' ] ] );
	ref_is $table->reveal_text( [ 1, 'age', 0, undef ], 0 )->[0], $table->cell_widget( 1, 'age' ), 'reveal_text names the text in the cell';
	is $table->cell_widget( 1, 'age' )->highlights->[0][1], 4, 'the highlight went onto it';
	my $serial = $table->cell_widget( 1, 'age' )->search_serial;
	like $table->search_revision( [ 1, 'age', 0, undef ] ), qr/\A[0-9]+:[0-9]+:$serial:[0-9]+\z/, 'the revision joins the row, the columns, the widget and its revision';
	is $table->search_revision( [ 5, 'age', 0, undef ] ), 'gone', 'a cell that is not built is gone';
	$table->page(3);
	$h->{ui}->step;
	$table->page(1);
	$h->{ui}->step;
	is $table->cell_widget( 1, 'age' )->highlights->[0][1], 4, 'a cell built again gets the highlight back';
};

done_testing;
