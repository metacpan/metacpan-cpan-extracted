use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::Widget::Table::Filter;
use Term::Fabulous::Widget::Table::Model;

my $F = 'Term::Fabulous::Widget::Table::Filter';

sub model (%args) {
	my $columns = delete $args{columns} // [ { key => 'name' }, { key => 'dept' }, { key => 'age', type => 'number' } ];
	my $model   = Term::Fabulous::Widget::Table::Model->new(%args);
	$model->add_column($_) foreach @$columns;
	return $model;
}

my @PEOPLE = (
	{ id => 1, name => 'Ann', dept => 'Sales', age => 34 },
	{ id => 2, name => 'bob', dept => 'IT',    age => 17 },
	{ id => 3, name => 'Cid', dept => 'Sales', age => undef },
	{ id => 4, name => 'Dan', dept => 'HR',    age => 50 },
	{ id => 5, name => 'Eve', dept => 'IT',    age => 23 },
);

# The view as text: rows by name (indented by depth, + closed, - open),
# groups as [display:count] (> when collapsed).
sub view ( $model, @lines ) {
	@lines = $model->lines unless @lines;
	return join ' ', map {
		$_->{kind} eq 'group'
			? '[' . $_->{display} . ':' . $_->{count} . ( $_->{expanded} ? '' : '>' ) . ']'
			: ( '.' x $_->{depth} )
			. $model->display_of( $_->{id}, 'name' )
			. ( $_->{has_children} ? ( $_->{expanded} ? '-' : '+' ) : '' )
	} @lines;
}

sub key_of ($id) { return Term::Fabulous::Widget::Table::Model::row_key($id) }

subtest 'rows and ids' => sub {
	my $model = model();
	my $ids   = $model->set_rows( [ { name => 'a' }, { name => 'b' } ] );
	is $ids,                                                    [ 1, 2 ], 'without row_id the model numbers the rows';
	is [ $model->add_rows( [ { name => 'c' } ], index => 0 ) ], [3],      'add_rows returns the new ids';
	is view($model),                                            'c a b',  'inserted at the index';

	my $by_key = model( row_id => 'id' );
	$by_key->set_rows( [@PEOPLE] );
	is $by_key->row(4), { id => 4, name => 'Dan', dept => 'HR', age => 50 }, 'row returns a copy of the data';
	$by_key->row(4)->{name} = 'changed';
	is $by_key->value_of( 4, 'name' ), 'Dan', 'which does not change the model';
	like dies { $by_key->add_rows( [ { id => 4 } ] ) },     qr/two rows have the id '4'/,                         'duplicate ids die';
	like dies { $by_key->add_rows( [ { name => 'x' } ] ) }, qr/a row has no id \(row_id key 'id' holds undef\)/,  'a missing id dies';
	like dies { $by_key->update_row( 4, { id => 9 } ) },    qr/would give row '4' the id '9'; ids cannot change/, 'ids cannot change';
	like dies { $by_key->row(99) },                         qr/there is no row with the id '99'/,                 'unknown ids die';

	my $by_code = model( row_id => sub ($row) { lc $row->{name} } );
	$by_code->set_rows( [ { name => 'Ann' } ] );
	is [ $by_code->row_ids ], ['ann'], 'a row_id code reference makes the ids';
	like dies { model( row_id => [] ) }, qr/row_id must be a column key or a code reference/, 'row_id is checked';
};

subtest 'changing rows' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	my $revision = $model->row_revision(2);
	$model->update_row( 2, { name => 'Bob' } );
	is [ $model->value_of( 2, 'name' ), $model->row_revision(2) ], [ 'Bob', $revision + 1 ], 'update_row merges and counts the change';
	$model->set_value( 2, age => 18 );
	is $model->value_of( 2, 'age' ), 18, 'set_value';
	$model->replace_row( 2, { id => 2, name => 'Robert' } );
	is $model->row(2), { id => 2, name => 'Robert' }, 'replace_row replaces the data';
	$model->set_selection( 2, 3 );
	$model->remove_rows(2);
	is [ $model->row_ids ],      [ 1, 3, 4, 5 ], 'remove_rows';
	is [ $model->selected_ids ], [3],            'a removed row leaves the selection';
	$model->clear_rows;
	is $model->row_count, 0, 'clear_rows';
};

subtest 'a row given again gets a new revision' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	my $first = $model->row_revision(2);
	$model->set_rows( [@PEOPLE] );
	my $second = $model->row_revision(2);
	isnt $second, $first, 'set_rows with the same id';
	$model->remove_rows(2);
	$model->add_rows( [ $PEOPLE[1] ] );
	isnt $model->row_revision(2), $_, 'removed and added again' foreach $first, $second;
};

subtest 'removing a parent and its child in one call' => sub {
	foreach my $order ( [qw(lib x.pm)], [qw(x.pm lib)] ) {
		my $model = model( row_id => 'name', children_key => 'kids' );
		$model->set_rows( [ { name => 'src', kids => [ { name => 'lib', kids => [ { name => 'x.pm' } ] }, { name => 'a.c' } ] }, { name => 'README' } ] );
		$model->remove_rows(@$order);
		is [ $model->row_ids ],            [qw(src a.c README)], "the rest stays, in data order (@$order)";
		is [ $model->children_of('src') ], ['a.c'],              "the parent's children (@$order)";
	}
};

subtest 'trees' => sub {
	my $model = model( row_id => 'name', children_key => 'kids' );
	$model->set_rows( [ { name => 'src', kids => [ { name => 'lib', kids => [ { name => 'x.pm' } ] }, { name => 'a.c' } ] }, { name => 'README' } ] );
	is view($model), 'src+ README', 'children start collapsed';
	$model->set_expanded( 'src', 1 );
	is view($model), 'src- .lib+ .a.c README', 'an expanded row shows its children';
	$model->set_all_expanded(1);
	is view($model),                                            'src- .lib- ..x.pm .a.c README', 'set_all_expanded';
	is [ $model->parent_of('x.pm'), $model->depth_of('x.pm') ], [ 'lib', 2 ],     'parent_of and depth_of';
	is [ $model->children_of('src') ],                          [ 'lib', 'a.c' ], 'children_of';
	is $model->rows, [ { name => 'src', kids => [ { name => 'lib', kids => [ { name => 'x.pm' } ] }, { name => 'a.c' } ] }, { name => 'README' } ], 'rows nests the children again';
	$model->add_rows( [ { name => 'b.c' } ], parent => 'src', index => 1 );
	is view($model), 'src- .lib- ..x.pm .b.c .a.c README', 'add_rows below a parent';
	like dies { $model->update_row( 'src', { kids => [] } ) }, qr/update_row cannot change 'kids'/, 'children change only through rows';
	$model->remove_rows('lib');
	ok !$model->has_row('x.pm'), 'removing a row removes its children';

	my $open = model( row_id => 'name', children_key => 'kids', expand_new => 1 );
	$open->set_rows( [ { name => 'a', kids => [ { name => 'b' } ] } ] );
	is view($open), 'a- .b', 'expand_new opens rows with children';
	like dies { model()->add_rows( [ { name => 'x' } ], parent => 1 ) }, qr/a parent row needs a table with children_key/, 'flat tables have no parents';
};

subtest 'columns' => sub {
	my $calls = 0;
	my $model = model(
		row_id  => 'id',
		columns => [
			{ key => 'name',  mutator => sub ( $value, $row ) { $calls++; uc $value } },
			{ key => 'label', value   => sub ($row) { "$row->{name}/$row->{dept}" } },
			{ key => 'dept' },
		],
	);
	$model->set_rows( [@PEOPLE] );
	is [ $model->display_of( 1, 'name' ), $model->display_of( 1, 'name' ) ], [ 'ANN', 'ANN' ], 'display texts';
	is $calls,                                                               1,                'are kept';
	is $model->value_of( 1, 'label' ),                                       'Ann/Sales',      'a computed value';
	$model->update_row( 1, { dept => 'Ops' } );
	is $model->value_of( 1, 'label' ), 'Ann/Ops', 'is computed again when the row changes';

	like dies { $model->add_column( { key => 'name' } ) }, qr/there is a column 'name' already/, 'keys are unique';
	$model->set_column_visible( dept => 0 );
	is [ map { $_->key } $model->visible_columns ], [qw(name label)], 'hidden columns';
	$model->set_visible_columns(qw(dept name));
	is [ map { $_->key } $model->visible_columns ], [qw(name dept)], 'set_visible_columns keeps the column order';
	$model->move_column( dept => 0 );
	is [ $model->column_keys ], [qw(dept name label)], 'move_column';
	$model->set_sort('name');
	$model->group_by('name');
	$model->set_filter( names => $F->new( column => 'name', op => 'not_empty' ) );
	$model->set_filter( also => $F->new( column => 'name', op => 'contains', value => 'a' ) );
	$model->remove_column('name');
	is [ $model->sort_spec, [ $model->group_by ], [ $model->filter_names ] ], [ [], [], [] ], 'removing a column drops its sort, grouping and filters';
	like dies { $model->column('nope') }, qr/there is no column 'nope'/, 'unknown columns die';
};

subtest 'sorting' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	$model->set_sort( [ age => 'desc' ] );
	is view($model), 'Dan Ann Eve bob Cid', 'descending, blank values last';
	$model->set_sort( [ age => 'asc' ] );
	is view($model), 'bob Eve Ann Dan Cid', 'ascending, blank values still last';
	$model->set_sort( [ dept => 'asc' ], [ name => 'desc' ] );
	is view($model), 'Dan Eve bob Cid Ann', 'several keys';
	$model->set_sort('dept');
	is view($model), 'Dan bob Eve Ann Cid', 'equal rows keep their data order';
	$model->add_rows( [ { id => 6, name => 'Fay', dept => 'HR', age => 41 } ], index => 0 );
	is view($model),      'Fay Dan bob Eve Ann Cid', 'also rows added at an index';
	is $model->sort_spec, [ [ 'dept', 'asc' ] ],     'a key alone is ascending';

	my $custom = model( row_id => 'id', columns => [ { key => 'name', compare => sub ( $a, $b, $ra, $rb ) { length $a <=> length $b || $a cmp $b } } ] );
	$custom->set_rows( [ { id => 1, name => 'ccc' }, { id => 2, name => 'a' }, { id => 3, name => 'bb' } ] );
	$custom->set_sort( [ name => 'desc' ] );
	is view($custom), 'ccc bb a', 'a comparator of your own, reversed for descending';

	my $natural = model( row_id => 'name', columns => [ { key => 'name', compare => 'natural' } ] );
	$natural->set_rows( [ map { { name => $_ } } qw(file10 file9 File1) ] );
	$natural->set_sort('name');
	is view($natural), 'File1 file9 file10', 'natural order';

	is $model->cycle_sort('age'), 1,                    'cycle_sort: the first click sorts ascending';
	is $model->sort_spec,         [ [ 'age', 'asc' ] ], '... and alone';
	$model->cycle_sort( 'name', 1 );
	is $model->sort_spec, [ [ 'age', 'asc' ], [ 'name', 'asc' ] ], 'adding a column';
	$model->cycle_sort( 'age', 1 );
	is $model->sort_spec, [ [ 'age', 'desc' ], [ 'name', 'asc' ] ], 'cycling one keeps its place';
	$model->cycle_sort( 'age', 1 );
	is $model->sort_spec, [ [ 'name', 'asc' ] ], 'the third click removes it';
	like dies { $model->set_sort( [ age => 'up' ] ) }, qr/sort direction must be one of asc, desc, got 'up'/, 'bad direction';
	like dies { $model->set_sort( 'age', 'age' ) },    qr/the column 'age' is in the sort twice/,             'a column twice';
};

subtest 'filters and search' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	$model->set_filter( adults => $F->new( column => 'age', op => '>=', value => 18 ) );
	is view($model), 'Ann Dan Eve', 'a filter';
	$model->set_filter( it => sub ($row) { $row->{dept} eq 'IT' } );
	is view($model),             'Eve',           'filters combine';
	is [ $model->filter_names ], [qw(adults it)], 'filter_names';
	$model->remove_filter('adults');
	is view($model), 'bob Eve', 'remove_filter';
	$model->clear_filters;
	$model->search('S');
	is view($model), 'Ann Cid', 'search looks at every visible column, case-insensitive';
	ok $model->is_filtered, 'is_filtered';
	like dies { $model->set_filter( bad => $F->new( column => 'age', op => '>', value => 'x' ) ) }, qr/op '>' on a number column needs numbers/,   'filters are checked';
	like dies { $model->set_filter( bad => 'age > 3' ) }, qr/a filter must be a Term::Fabulous::Widget::Table::Filter, a code reference or undef/, 'and must be filters';

	my $tree = model( row_id => 'name', children_key => 'kids' );
	$tree->set_rows( [ { name => 'src', kids => [ { name => 'lib', kids => [ { name => 'x.pm' } ] }, { name => 'a.c' } ] }, { name => 'README' } ] );
	$tree->search('x.pm');
	is view($tree),                 'src+',              'the ancestors of a match pass';
	is $tree->expand_to_matches,    1,                   'expand_to_matches opens them';
	is view($tree),                 'src- .lib- ..x.pm', 'so the match shows; other children are filtered out';
	is [ $tree->filtered_row_ids ], [qw(src lib x.pm)],  'filtered_row_ids';
};

subtest 'groups' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	$model->group_by('dept');
	is view($model), '[HR:1] Dan [IT:2] bob Eve [Sales:2] Ann Cid', 'groups in ascending order of their value';
	$model->set_sort( [ dept => 'desc' ], [ name => 'asc' ] );
	is view($model), '[Sales:2] Ann Cid [IT:2] bob Eve [HR:1] Dan', 'the sort orders the groups too';
	$model->set_group_collapsed( ['IT'], 1 );
	is view($model), '[Sales:2] Ann Cid [IT:2>] [HR:1] Dan', 'a collapsed group';
	ok $model->is_group_collapsed('IT'), 'is_group_collapsed';
	$model->set_filter( adults => $F->new( column => 'age', op => '>=', value => 18 ) );
	is view($model), '[Sales:1] Ann [IT:1>] [HR:1] Dan', 'counts follow the filters';
	$model->clear_filters;
	$model->set_all_groups_collapsed(0);
	$model->group_by( 'dept', 'age' );
	is view($model), '[Sales:2] [34:1] Ann [:1] Cid [IT:2] [17:1] bob [23:1] Eve [HR:1] [50:1] Dan', 'groups in groups';
	my ($inner) = grep { $_->{kind} eq 'group' && $_->{depth} == 1 } $model->lines;
	is $inner->{path}, [ 'Sales', 34 ], 'a group knows its path';
	$model->set_all_groups_collapsed(1);
	is view($model), '[Sales:2>] [IT:2>] [HR:1>]', 'set_all_groups_collapsed';
	$model->set_group_collapsed( ['IT'], 0 );
	is view($model), '[Sales:2>] [IT:2] [17:1>] [23:1>] [HR:1>]', 'inner groups were collapsed too';
};

subtest 'pages and the cursor' => sub {
	my $model = model( row_id => 'id', page_size => 2 );
	$model->set_rows( [@PEOPLE] );
	is [ $model->page_count, $model->page, $model->cursor ], [ 3, 1, key_of(1) ], 'the cursor starts on the first line';
	is view( $model, $model->page_lines ),                   'Ann bob',           'page_lines';
	$model->set_page(3);
	is [ view( $model, $model->page_lines ), $model->cursor ], [ 'Eve', key_of(5) ], 'turning the page moves the cursor onto it';
	$model->set_cursor( key_of(2) );
	is $model->page, 1, 'moving the cursor turns the page';
	$model->set_sort( [ age => 'desc' ] );
	is [ $model->page, view( $model, $model->page_lines ) ], [ 2, 'Eve bob' ], 'after a sort the page follows the cursor';
	$model->set_page_size(4);
	is [ $model->page, $model->page_count ], [ 1, 2 ], 'and after a page size change';
	is $model->set_page(9),                  1,        'pages are kept within the count';
	is $model->page,                         2,        'the last page';
	like dies { $model->set_page(0) },           qr/a page must be a whole number from 1/, 'pages count from 1';
	like dies { $model->set_cursor('r\0nope') }, qr/the cursor needs a line of the view/,  'the cursor needs a line';

	$model->set_page_size(0);
	$model->set_cursor( key_of(3) );
	$model->remove_rows(3);
	is $model->cursor, key_of(2), 'a removed cursor row on the last line: the line now last (sorted by age)';
	$model->set_cursor( key_of(1) );
	$model->remove_rows(1);
	is $model->cursor, key_of(5), 'a removed cursor row: the line that took its place';
	$model->group_by('dept');
	$model->set_cursor( key_of(2) );
	$model->set_group_collapsed( ['IT'], 1 );
	is $model->cursor, Term::Fabulous::Widget::Table::Model::group_key( $model->group_key_of('IT') ), 'a cursor row in a closed group: its group';
	$model->clear_rows;
	is $model->cursor, undef, 'no lines, no cursor';
};

subtest 'selection' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	is [ $model->select( 3, 1 ) ],           [ [ 1, 3 ], [] ], 'select returns what it added';
	is [ $model->selected_ids ],             [ 1, 3 ], 'in data order';
	is [ $model->toggle_selected(3) ],       [ [], [3] ], 'toggle_selected';
	is [ $model->set_selection( 2, 4 ) ],    [ [ 2, 4 ], [1] ], 'set_selection';
	is [ $model->deselect(4) ],              [ [], [4] ], 'deselect';
	is [ $model->select(2) ],                [ [], [] ],  'selecting a selected row changes nothing';
	is [ $model->set_selection( 5, 1, 3 ) ], [ [ 1, 3, 5 ], [2] ], 'added and removed ids come in data order';
	is scalar( $model->selected_ids ),       3, 'selected_ids counts in scalar context';
	like dies { $model->select(42) }, qr/there is no row with the id '42'/, 'unknown ids die';
};

subtest 'selection in data order after the rows change' => sub {
	my $model = model( row_id => 'id' );
	$model->set_rows( [@PEOPLE] );
	$model->select( 1, 5 );
	$model->remove_rows(3);
	$model->add_rows( [ { id => 9, name => 'Ida' } ], index => 0 );
	is [ $model->select( 5, 4, 9, 4 ) ], [ [ 9, 4 ], [] ], 'select after a removal and an insertion';
	is [ $model->selected_ids ],         [ 9, 1, 4, 5 ],   'selected_ids';
	is [ $model->deselect( 5, 9, 2 ) ],  [ [], [ 9, 5 ] ], 'deselect';
	like dies { $model->deselect( 1, 42 ) }, qr/there is no row with the id '42'/, 'deselect checks the ids';
	is [ $model->selected_ids ], [ 1, 4 ], 'and changes nothing when it dies';
	$model->set_rows( [ reverse @PEOPLE ] );
	is [ $model->select(5) ], [ [5], [] ], 'select after set_rows';
	is [ $model->selected_ids ], [ 5, 4, 1 ], 'in the new data order';
};

done_testing;
