package Term::Fabulous::Widget::Table::Model;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Table::Column;
use Term::Fabulous::Widget::Table::Filter;

class Term::Fabulous::Widget::Table::Model :strict(params) {
	use List::Util qw(any first max min uniq);
	use POSIX ();
	use Scalar::Util qw(blessed refaddr);
	use Term::Fabulous::Check qw(describe one_of);
	use Term::Fabulous::Widget::Table::Value qw(is_blank);

	# A line of the view is a data row or a group header. Its key names it
	# across rebuilds: "r" or "g", a NUL, then the row id or the group key.
	use constant { ROW_PREFIX => "r\0", GROUP_PREFIX => "g\0" };

	field $row_id       :param :reader = undef;    # a key, a code reference, or undef for ids of our own
	field $children_key :param :reader = undef;    # the key of nested rows, or undef for flat data
	field $page_size    :param :reader = 0;
	field $expand_new   :param = 0;    # whether rows added with children start expanded

	# Columns, in order, and the keys of the hidden ones.
	field @_columns;
	field %_column_by_key;
	field %_hidden;

	# Rows by id: { id, data, parent, children => [ ids ], revision }; the
	# data order is the order of @_roots and of every children list.
	field %_row;
	field @_roots;
	field $_next_id = 1;
	field %_rank;    # row id => its place in data order; empty until asked for

	# Per row id: a copy of the data for callbacks, raw values and display
	# texts by column key. Dropped when the row or the column changes.
	field %_copy;
	field %_raw;
	field %_display;
	field %_id_of_copy;    # refaddr of a copy => row id
	field %_search_text;    # row id => the folded display texts of the visible columns

	# How the rows are shown.
	field @_sort;    # [ key, 1 or -1 ]
	field %_filter;    # name => Filter
	field @_filter_names;    # in the order they were set
	field $_search = '';
	field @_group_by;    # column keys, outermost first
	field %_collapsed_group;    # group key => 1
	field %_expanded;    # row id => 1
	field $_page = 1;

	# Selection and cursor.
	field %_selected;
	field $_cursor;    # a line key, or undef
	field $_cursor_index;    # the cursor's place in the view before the last change
	field $_anchor;    # the line key a range selection extends from

	# The computed view, undef when anything it depends on changed.
	field $_view;

	# Counts every change of the data, the columns or the view state, so
	# the table can tell whether its widgets are up to date.
	field $revision         :reader = 0;
	field $columns_revision :reader = 0;

	ADJUST {
		die "Term::Fabulous::Widget::Table::Model: row_id must be a column key or a code reference, got " . describe($row_id)
			if defined $row_id && !( ref $row_id eq 'CODE' || ( !ref $row_id && length $row_id ) );
		die "Term::Fabulous::Widget::Table::Model: children_key must be a non-empty string, got " . describe($children_key)
			if defined $children_key && ( ref $children_key || !length $children_key );
		$page_size  = _page_size($page_size);
		$expand_new = $expand_new ? 1 : 0;
	}

	# How rows are read can change only while there are none.
	method _check_no_rows ($what) {
		die "Term::Fabulous::Widget::Table::Model: $what can only be changed while there are no rows" if %_row;
		return;
	}

	method set_row_id ($new) {
		$self->_check_no_rows('row_id');
		die "Term::Fabulous::Widget::Table::Model: row_id must be a column key or a code reference, got " . describe($new)
			if defined $new && !( ref $new eq 'CODE' || ( !ref $new && length $new ) );
		$row_id = $new;
		return $row_id;
	}

	method set_children_key ($new) {
		$self->_check_no_rows('children_key');
		die "Term::Fabulous::Widget::Table::Model: children_key must be a non-empty string, got " . describe($new)
			if defined $new && ( ref $new || !length $new );
		$children_key = $new;
		$self->_changed;
		return $children_key;
	}

	method expand_new (@new) {
		return $expand_new unless @new;
		$expand_new = $new[0] ? 1 : 0;
		return $expand_new;
	}

	sub _page_size ($size) {
		die "Term::Fabulous::Widget::Table::Model: page_size must be a non-negative integer (0 for no pages), got " . describe($size)
			unless defined $size && !ref $size && $size =~ /\A[0-9]+\z/;
		return $size + 0;
	}

	# A change the view depends on.
	method _changed () {
		$revision++;
		$_cursor_index = $_view->{index_of}{$_cursor} if defined $_view && defined $_cursor;
		undef $_view;
		return;
	}

	# A change of what is shown of the view (page, selection, cursor).
	method _touched () {
		$revision++;
		return;
	}

	# =====================================================================
	# Columns
	# =====================================================================

	method _column_from ($spec) {
		return $spec if blessed $spec && $spec->isa('Term::Fabulous::Widget::Table::Column');
		die "Term::Fabulous::Widget::Table::Model: a column must be a hash reference of column parameters or a Term::Fabulous::Widget::Table::Column, got " . describe($spec)
			unless ref $spec eq 'HASH';
		return Term::Fabulous::Widget::Table::Column->new(%$spec);
	}

	method _columns_changed ( $keys = undef ) {
		$columns_revision++;
		if ( defined $keys ) {
			delete $_->@{@$keys} foreach values %_raw, values %_display;
		}
		else {
			%_raw = %_display = ();
		}
		%_search_text = ();
		$self->_changed;
		return;
	}

	method has_column ($key) {
		return defined $key && exists $_column_by_key{$key} ? 1 : 0;
	}

	method column ($key) {
		return $_column_by_key{ $key // '' } // die "Term::Fabulous::Widget::Table::Model: there is no column " . describe($key);
	}

	method columns () {
		return @_columns;
	}

	method column_keys () {
		return map { $_->key } @_columns;
	}

	method visible_columns () {
		return grep { !$_hidden{ $_->key } } @_columns;
	}

	method type_of ($key) {
		return $self->column($key)->type;
	}

	method add_column ( $spec, $index = undef ) {
		my $column = $self->_column_from($spec);
		die "Term::Fabulous::Widget::Table::Model: there is a column '" . $column->key . "' already" if exists $_column_by_key{ $column->key };
		$index //= scalar @_columns;
		_check_index( 'column index', $index, scalar @_columns );
		splice @_columns, $index, 0, $column;
		$_column_by_key{ $column->key } = $column;
		$_hidden{ $column->key }        = 1 unless $column->visible;
		$self->_columns_changed( [ $column->key ] );
		return $column;
	}

	method replace_column ($column) {
		my $key   = $column->key;
		my $index = $self->_column_index($key);
		$_columns[$index] = $_column_by_key{$key} = $column;
		$self->_columns_changed( [$key] );
		return $column;
	}

	method remove_column ($key) {
		my $index = $self->_column_index($key);
		splice @_columns, $index, 1;
		delete $_column_by_key{$key};
		delete $_hidden{$key};
		@_sort     = grep { $_->[0] ne $key } @_sort;
		@_group_by = grep { $_ ne $key } @_group_by;
		my @comparing = grep {
			my $name = $_;
			any { $_ eq $key } $_filter{$name}->columns
		} @_filter_names;
		$self->remove_filter($_) foreach @comparing;
		$self->_columns_changed( [$key] );
		return;
	}

	method move_column ( $key, $index ) {
		my $from = $self->_column_index($key);
		_check_index( 'column index', $index, $#_columns );
		my ($column) = splice @_columns, $from, 1;
		splice @_columns, $index, 0, $column;
		$self->_columns_changed( [] );
		return;
	}

	method _column_index ($key) {
		$self->column($key);
		return first { $_columns[$_]->key eq $key } 0 .. $#_columns;
	}

	sub _check_index ( $what, $index, $last ) {
		die "Term::Fabulous::Widget::Table::Model: $what must be an integer from 0 to $last, got " . describe($index)
			unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/ && $index <= $last;
		return;
	}

	method is_column_visible ($key) {
		$self->column($key);
		return $_hidden{$key} ? 0 : 1;
	}

	method set_column_visible ( $key, $visible ) {
		$self->column($key);
		return if ( $_hidden{$key} ? 0 : 1 ) == ( $visible ? 1 : 0 );
		$visible ? delete $_hidden{$key} : ( $_hidden{$key} = 1 );
		$self->_columns_changed( [] );
		return;
	}

	method set_visible_columns (@keys) {
		$self->column($_) foreach @keys;
		my %shown  = map { $_ => 1 } @keys;
		my %hidden = map { $_ => 1 } grep { !$shown{$_} } $self->column_keys;
		return if join( "\0", sort keys %hidden ) eq join( "\0", sort keys %_hidden );
		%_hidden = %hidden;
		$self->_columns_changed( [] );
		return;
	}

	# =====================================================================
	# Rows
	# =====================================================================

	method _id_for ($data) {
		return $_next_id++ unless defined $row_id;
		my $id = ref $row_id ? $row_id->( {%$data} ) : $data->{$row_id};
		die "Term::Fabulous::Widget::Table::Model: a row has no id (row_id " . ( ref $row_id ? 'returned' : "key '$row_id' holds" ) . " " . describe($id) . ")"
			unless defined $id && !ref $id && length $id;
		return $id;
	}

	# Splits input rows into records (children first taken out of the
	# data) without storing anything: ( [ top-level ids ], { id => record } ).
	# $taken holds the ids that are in use already.
	method _records_for ( $rows, $parent, $taken ) {
		die "Term::Fabulous::Widget::Table::Model: rows must be an array reference of hash references, got " . describe($rows)
			unless ref $rows eq 'ARRAY';
		my ( @records, %by_id );
		my $collect;
		$collect = sub ( $list, $parent_id ) {
			my @ids;
			foreach my $row (@$list) {
				die "Term::Fabulous::Widget::Table::Model: a row must be a hash reference, got " . describe($row) unless ref $row eq 'HASH';
				my %data   = %$row;
				my $nested = defined $children_key ? delete $data{$children_key} : undef;
				die "Term::Fabulous::Widget::Table::Model: the '$children_key' of a row must be an array reference of rows, got " . describe($nested)
					if defined $nested && ref $nested ne 'ARRAY';
				my $id = $self->_id_for( \%data );
				die "Term::Fabulous::Widget::Table::Model: two rows have the id '$id'" if exists $by_id{$id} || exists $taken->{$id};

				# A record starts at the model's revision, which is above the
				# revision of every earlier row with its id (a row's change
				# counts in both), so the table refreshes what it showed.
				my $record = { id => $id, data => \%data, parent => $parent_id, children => [], revision => $revision };
				$by_id{$id} = $record;
				push @records, $record;
				push @ids,     $id;
				$record->{children} = $collect->( $nested, $id ) if defined $nested;
			}
			return \@ids;
		};
		my $top_ids = $collect->( $rows, $parent );
		undef $collect;
		return ( $top_ids, \%by_id );
	}

	method set_rows ($rows) {
		my ( $top_ids, $by_id ) = $self->_records_for( $rows, undef, {} );    # the new rows replace all
		%_row      = %$by_id;
		@_roots    = @$top_ids;
		%_copy     = %_raw = %_display = %_id_of_copy = %_search_text = ();
		%_expanded = $expand_new ? map { $_->{id} => 1 } grep { @{ $_->{children} } } values %_row : ();
		%_selected = map               { $_       => 1 } grep { exists $_row{$_} } keys %_selected;
		%_rank     = ();
		$self->_changed;
		return $top_ids;
	}

	method add_rows ( $rows, %options ) {
		my @unknown = grep { $_ ne 'parent' && $_ ne 'index' } sort keys %options;
		die "Term::Fabulous::Widget::Table::Model: add_rows does not accept @unknown (known: index, parent)" if @unknown;
		my $parent = $options{parent};
		die "Term::Fabulous::Widget::Table::Model: a parent row needs a table with children_key (tree data)" if defined $parent && !defined $children_key;
		my $siblings = defined $parent ? $self->_record($parent)->{children} : \@_roots;
		my $index    = $options{index} // scalar @$siblings;
		_check_index( 'row index', $index, scalar @$siblings );

		my ( $top_ids, $by_id ) = $self->_records_for( $rows, $parent, \%_row );
		@_row{ keys %$by_id } = values %$by_id;
		splice @$siblings, $index, 0, @$top_ids;
		if ($expand_new) {
			$_expanded{ $_->{id} } = 1 foreach grep { @{ $_->{children} } } values %$by_id;
		}
		%_rank = ();
		$self->_changed;
		return @$top_ids;
	}

	method _record ($id) {
		return $_row{ $id // '' } // die "Term::Fabulous::Widget::Table::Model: there is no row with the id " . describe($id);
	}

	method has_row ($id) {
		return defined $id && exists $_row{$id} ? 1 : 0;
	}

	method _row_changed ($record) {
		my $id = $record->{id};
		$record->{revision}++;
		my $copy = delete $_copy{$id};
		delete $_id_of_copy{ refaddr $copy } if defined $copy;
		delete $_raw{$id};
		delete $_display{$id};
		delete $_search_text{$id};
		$self->_changed;
		return;
	}

	method update_row ( $id, $changes ) {
		my $record = $self->_record($id);
		die "Term::Fabulous::Widget::Table::Model: update_row needs a hash reference of changes, got " . describe($changes) unless ref $changes eq 'HASH';
		die "Term::Fabulous::Widget::Table::Model: update_row cannot change '$children_key'; add or remove the child rows instead"
			if defined $children_key && exists $changes->{$children_key};
		my %data = ( %{ $record->{data} }, %$changes );
		$self->_check_kept_id( $id, \%data );
		$record->{data} = \%data;
		$self->_row_changed($record);
		return;
	}

	method replace_row ( $id, $data ) {
		my $record = $self->_record($id);
		die "Term::Fabulous::Widget::Table::Model: replace_row needs a hash reference, got " . describe($data) unless ref $data eq 'HASH';
		my %copy = %$data;
		delete $copy{$children_key} if defined $children_key;
		$self->_check_kept_id( $id, \%copy );
		$record->{data} = \%copy;
		$self->_row_changed($record);
		return;
	}

	# A row keeps its id: data that would give it another one dies.
	method _check_kept_id ( $id, $data ) {
		return unless defined $row_id;
		my $new = ref $row_id ? $row_id->( {%$data} ) : $data->{$row_id};
		die "Term::Fabulous::Widget::Table::Model: the change would give row '$id' the id " . describe($new) . "; ids cannot change"
			unless defined $new && !ref $new && "$new" eq "$id";
		return;
	}

	method set_value ( $id, $key, $value ) {
		return $self->update_row( $id, { $key => $value } );
	}

	# Every sibling list loses its removed rows in one pass, then the rows
	# and their descendants are forgotten.
	method remove_rows (@ids) {
		my @records = map { $self->_record($_) } @ids;
		my %gone    = map { $_->{id} => 1 } @records;
		my %lists   = map { my $siblings = $self->_siblings_of($_); ( refaddr $siblings => $siblings ) } @records;
		@$_ = grep { !$gone{$_} } @$_ foreach values %lists;
		foreach my $record (@records) {
			$self->_forget($record) if exists $_row{ $record->{id} };    # not removed with an ancestor
		}
		%_rank = ();
		$self->_changed;
		return;
	}

	# The list of ids a row is in: its parent's children or the top level.
	method _siblings_of ($record) {
		return defined $record->{parent} ? $_row{ $record->{parent} }{children} : \@_roots;
	}

	method _forget ($record) {
		$self->_forget( $_row{$_} ) foreach @{ $record->{children} };
		my $id = $record->{id};
		delete $_row{$id};
		delete $_expanded{$id};
		delete $_selected{$id};
		my $copy = delete $_copy{$id};
		delete $_id_of_copy{ refaddr $copy } if defined $copy;
		delete $_raw{$id};
		delete $_display{$id};
		delete $_search_text{$id};
		return;
	}

	method clear_rows () {
		%_row   = %_copy = %_raw = %_display = %_id_of_copy = %_search_text = %_expanded = %_selected = %_rank = ();
		@_roots = ();
		$self->_changed;
		return;
	}

	method row_count () {
		return scalar keys %_row;
	}

	# Every row id, depth-first in data order.
	method row_ids () {
		my @ids;
		my $walk;
		$walk = sub ($list) {
			foreach my $id (@$list) {
				push @ids, $id;
				$walk->( $_row{$id}{children} );
			}
		};
		$walk->( \@_roots );
		undef $walk;
		return @ids;
	}

	method row ($id) {
		return { %{ $self->_record($id)->{data} } };
	}

	method row_revision ($id) {
		return $self->_record($id)->{revision};
	}

	# The rows as given to set_rows: copies, with the children nested back.
	method rows () {
		my $nest;
		$nest = sub ($ids) {
			return [
				map {
					my $record = $_row{$_};
					my %data   = %{ $record->{data} };
					$data{$children_key} = $nest->( $record->{children} ) if defined $children_key && @{ $record->{children} };
					\%data;
				} @$ids
			];
		};
		my $rows = $nest->( \@_roots );
		undef $nest;
		return $rows;
	}

	method parent_of ($id) {
		return $self->_record($id)->{parent};
	}

	method children_of ($id) {
		return @{ $self->_record($id)->{children} };
	}

	method depth_of ($id) {
		my $depth = 0;
		for ( my $parent = $self->_record($id)->{parent}; defined $parent; $parent = $_row{$parent}{parent} ) {
			$depth++;
		}
		return $depth;
	}

	# The copy of a row's data the callbacks get; the same copy until the
	# row changes.
	method data_of ($id) {
		return $_copy{$id} //= do {
			my $copy = { %{ $self->_record($id)->{data} } };
			$_id_of_copy{ refaddr $copy } = $id;
			$copy;
		};
	}

	# Raw value and display text of a cell, by row id or by the copy of a
	# row's data (for filters). What code computes (a column's value code,
	# its mutators) is kept until the row or the column changes; a plain
	# entry of the data is read directly. A hash the table did not hand out
	# is read without the cache.
	method _id_of_row ($row) {
		return ref $row ? $_id_of_copy{ refaddr $row } : $row;
	}

	method value_of ( $row, $key ) {
		my $column = $_column_by_key{ $key // '' } // $self->column($key);
		my $id     = $self->_id_of_row($row);
		return $column->value_of($row) unless defined $id;
		my $record = $_row{$id} // $self->_record($id);
		return $record->{data}{$key} unless $column->computes_value;
		my $cache = $_raw{$id} //= {};
		return $cache->{$key} if exists $cache->{$key};
		return $cache->{$key} = $column->value_of( $self->data_of($id) );
	}

	method display_of ( $row, $key ) {
		my $column = $_column_by_key{ $key // '' } // $self->column($key);
		my $id     = $self->_id_of_row($row);
		return $column->display_of( $column->value_of($row), $row ) unless defined $id;
		unless ( $column->has_mutators ) {
			my $raw = $self->value_of( $id, $key );
			return defined $raw ? "$raw" : '';
		}
		my $cache = $_display{$id} //= {};
		return $cache->{$key} if exists $cache->{$key};
		return $cache->{$key} = $column->display_of( $self->value_of( $id, $key ), $self->data_of($id) );
	}

	# =====================================================================
	# Sorting
	# =====================================================================

	# [ [ key, 'asc' or 'desc' ], ... ]
	method sort_spec () {
		return [ map { [ $_->[0], $_->[1] > 0 ? 'asc' : 'desc' ] } @_sort ];
	}

	method set_sort (@spec) {
		my ( @sort, %seen );
		foreach my $entry (@spec) {
			my ( $key, $direction ) = ref $entry eq 'ARRAY' ? @$entry : ( $entry, 'asc' );
			$self->column($key);
			one_of( $self, 'sort direction', $direction, qw(asc desc) );
			die "Term::Fabulous::Widget::Table::Model: the column '$key' is in the sort twice" if $seen{$key}++;
			push @sort, [ $key, $direction eq 'asc' ? 1 : -1 ];
		}
		return 0 if _same_sort( \@sort, \@_sort );
		@_sort = @sort;
		$self->_changed;
		return 1;
	}

	sub _same_sort ( $left, $right ) {
		return join( "\0", map { @$_ } @$left ) eq join( "\0", map { @$_ } @$right ) ? 1 : 0;
	}

	# What a click on a header does: ascending, descending, unsorted. With
	# $add, the column is added to (or cycled within) the sort; without,
	# it becomes the only sort key.
	method cycle_sort ( $key, $add = 0 ) {
		$self->column($key);
		my ($current) = grep { $_->[0] eq $key } @_sort;
		my $next      = !defined $current ? 1 : $current->[1] > 0 ? -1 : 0;
		my @sort      = $add ? ( grep { $_->[0] ne $key } @_sort ) : ();
		if ($next) {
			my $position = $add && defined $current ? ( first { $_sort[$_][0] eq $key } 0 .. $#_sort ) : scalar @sort;
			splice @sort, $position, 0, [ $key, $next ];
		}
		return $self->set_sort( map { [ $_->[0], $_->[1] > 0 ? 'asc' : 'desc' ] } @sort );
	}

	# Orders sibling rows by the sort, then by data order. Named comparators
	# order by sort keys computed once per row; a comparator of the user's
	# is called for every comparison.
	method _sorted (@ids) {
		return @ids unless @_sort && @ids > 1;
		my @plans;
		foreach my $entry (@_sort) {
			my ( $key, $direction ) = @$entry;
			my $column = $self->column($key);
			if ( $column->has_custom_compare ) {
				push @plans, [ 'custom', $column, $key, $direction ];
				next;
			}
			my %sort_key = map { $_ => $column->sort_key( $self->value_of( $_, $key ) ) } @ids;
			push @plans, [ $column->sorts_numerically ? 'number' : 'text', \%sort_key, $key, $direction ];
		}
		my %order;
		@order{@ids} = 0 .. $#ids;    # the ids come in data order
		my @sorted = sort {
			my $result = 0;
			foreach my $plan (@plans) {
				my ( $kind, $what, $key, $direction ) = @$plan;
				if ( $kind eq 'custom' ) {
					$result = $what->order( $self->value_of( $a, $key ), $self->value_of( $b, $key ), $self->data_of($a), $self->data_of($b), $direction );
				}
				else {
					my ( $left, $right ) = ( $what->{$a}, $what->{$b} );
					$result
						= !defined $left || !defined $right ? ( defined $left ? -1 : defined $right ? 1 : 0 )
						: $kind eq 'number'                 ? $direction * ( $left <=> $right )
						:                                     $direction * ( $left cmp $right );
				}
				last if $result;
			}
			$result || $order{$a} <=> $order{$b};
		} @ids;
		return @sorted;
	}

	# =====================================================================
	# Filtering
	# =====================================================================

	method set_filter ( $name, $filter ) {
		die "Term::Fabulous::Widget::Table::Model: a filter name must be a non-empty string, got " . describe($name)
			unless defined $name && !ref $name && length $name;
		return $self->remove_filter($name) unless defined $filter;
		$filter = Term::Fabulous::Widget::Table::Filter->new( test => $filter ) if ref $filter eq 'CODE';
		die "Term::Fabulous::Widget::Table::Model: a filter must be a Term::Fabulous::Widget::Table::Filter, a code reference or undef, got " . describe($filter)
			unless blessed $filter && $filter->isa('Term::Fabulous::Widget::Table::Filter');
		$filter->check($self);
		push @_filter_names, $name unless exists $_filter{$name};
		$_filter{$name} = $filter;
		$self->_changed;
		return 1;
	}

	method remove_filter ($name) {
		return 0 unless defined $name && exists $_filter{$name};
		delete $_filter{$name};
		@_filter_names = grep { $_ ne $name } @_filter_names;
		$self->_changed;
		return 1;
	}

	method clear_filters () {
		return 0 unless @_filter_names || length $_search;
		%_filter       = ();
		@_filter_names = ();
		$_search       = '';
		$self->_changed;
		return 1;
	}

	method filter ($name) {
		return $_filter{ $name // '' };
	}

	method filter_names () {
		return @_filter_names;
	}

	method search (@new) {
		return $_search unless @new;
		my ($text) = @new;
		$text //= '';
		die "Term::Fabulous::Widget::Table::Model: search needs a string, got " . describe($text) if ref $text;
		return $_search if $text eq $_search;
		$_search = $text;
		$self->_changed;
		return $_search;
	}

	method is_filtered () {
		return @_filter_names || length $_search ? 1 : 0;
	}

	# Whether a row matches every filter and the search; $searched are the
	# keys of the columns the search looks at, $wanted the folded search.
	method _matches ( $id, $searched, $wanted ) {
		if (@_filter_names) {
			my $row = $self->data_of($id);
			foreach my $name (@_filter_names) {
				return 0 unless $_filter{$name}->matches( $row, $self );
			}
		}
		return 1 unless length $wanted;
		my $text = $_search_text{$id} //= fc join "\0", map { $self->display_of( $id, $_ ) } @$searched;
		return index( $text, $wanted ) >= 0 ? 1 : 0;
	}

	# The rows a filter lets through: those that match, and their
	# ancestors, so a matching row is never cut off from its tree.
	method _passing () {
		return { map { $_ => 1 } keys %_row } unless $self->is_filtered;
		my @searched = map { $_->key } $self->visible_columns;
		my $wanted   = fc $_search;
		my %passing;
		foreach my $id ( grep { $self->_matches( $_, \@searched, $wanted ) } keys %_row ) {
			for ( my $node = $id; defined $node && !$passing{$node}; $node = $_row{$node}{parent} ) {
				$passing{$node} = 1;
			}
		}
		return \%passing;
	}

	# Expands every row that leads to a matching row, so a filter shows
	# what it found. Returns whether anything was expanded.
	method expand_to_matches () {
		return 0 unless $self->is_filtered && defined $children_key;
		my $passing = $self->_passing;
		my @closed  = grep {
			!$_expanded{$_}
				&& ( any { $passing->{$_} } @{ $_row{$_}{children} } )
		} keys %$passing;
		return 0 unless @closed;
		$_expanded{$_} = 1 foreach @closed;
		$self->_changed;
		return 1;
	}

	# =====================================================================
	# Grouping
	# =====================================================================

	method group_by (@keys) {
		return @_group_by unless @keys;
		@keys = () if @keys == 1 && !defined $keys[0];
		$self->column($_) foreach @keys;
		my %seen;
		die "Term::Fabulous::Widget::Table::Model: group_by names a column twice" if grep { $seen{$_}++ } @keys;
		@_group_by = @keys;
		$self->_changed;
		return @_group_by;
	}

	# A group key: the values of its path, each as defined-ness and text.
	sub _group_key (@values) {
		return join "\0", map { defined $_ ? "d$_" : 'u' } @values;
	}

	method group_key_of (@path) {
		return _group_key(@path);
	}

	method is_group_collapsed (@path) {
		return $_collapsed_group{ _group_key(@path) } ? 1 : 0;
	}

	method set_group_collapsed ( $path, $collapsed ) {
		die "Term::Fabulous::Widget::Table::Model: a group path must be an array reference of group values" unless ref $path eq 'ARRAY';
		my $key = _group_key(@$path);
		return 0 if ( $_collapsed_group{$key} ? 1 : 0 ) == ( $collapsed ? 1 : 0 );
		$collapsed ? ( $_collapsed_group{$key} = 1 ) : delete $_collapsed_group{$key};
		$self->_changed;
		return 1;
	}

	method set_all_groups_collapsed ($collapsed) {
		%_collapsed_group = $collapsed ? map { $_ => 1 } $self->_all_group_keys : ();
		$self->_changed;
		return;
	}

	# =====================================================================
	# Tree
	# =====================================================================

	method is_expanded ($id) {
		$self->_record($id);
		return $_expanded{$id} ? 1 : 0;
	}

	method set_expanded ( $id, $expanded ) {
		$self->_record($id);
		return 0 if ( $_expanded{$id} ? 1 : 0 ) == ( $expanded ? 1 : 0 );
		$expanded ? ( $_expanded{$id} = 1 ) : delete $_expanded{$id};
		$self->_changed;
		return 1;
	}

	method set_all_expanded ($expanded) {
		%_expanded = $expanded ? map { $_->{id} => 1 } grep { @{ $_->{children} } } values %_row : ();
		$self->_changed;
		return;
	}

	# =====================================================================
	# The view: filtered, sorted, grouped, flattened, paged
	# =====================================================================

	# The view, computed when it is needed after a change. A new view
	# settles the cursor and the page: the cursor stays on a line of the
	# view and the page is the cursor's page.
	method _view () {
		return $_view if defined $_view;
		$_view = $self->_compute_view;
		$self->_settle_cursor;
		return $_view;
	}

	# The view: every passing row in order, grouped and sorted once; the
	# lines are what of it is open, the filtered ids all of it.
	method _compute_view () {
		my $tree = $self->_ordered_tree;
		my ( @lines, @filtered );
		my $walk_rows;
		$walk_rows = sub ( $ids, $depth, $shown ) {
			foreach my $id (@$ids) {
				push @filtered, $id;
				my $children = $tree->{children}{$id};
				my $open     = @$children && $_expanded{$id} ? 1 : 0;
				push @lines, { kind => 'row', key => ROW_PREFIX . $id, id => $id, depth => $depth, has_children => @$children ? 1 : 0, expanded => $open } if $shown;
				$walk_rows->( $children, $depth + 1, $shown && $open );
			}
		};
		my $walk_groups;
		$walk_groups = sub ( $groups, $shown ) {
			foreach my $group (@$groups) {
				my $collapsed = $_collapsed_group{ $group->{group_key} } ? 1 : 0;
				if ($shown) {
					my %line = %$group;
					delete @line{qw(groups rows)};
					push @lines, { %line, kind => 'group', key => GROUP_PREFIX . $group->{group_key}, expanded => $collapsed ? 0 : 1 };
				}
				defined $group->{groups} ? $walk_groups->( $group->{groups}, $shown && !$collapsed ) : $walk_rows->( $group->{rows}, 0, $shown && !$collapsed );
			}
		};
		defined $tree->{groups} ? $walk_groups->( $tree->{groups}, 1 ) : $walk_rows->( $tree->{rows}, 0, 1 );
		undef $walk_rows;
		undef $walk_groups;

		my $pages    = $page_size ? max( 1, POSIX::ceil( @lines / $page_size ) ) : 1;
		my %index_of = map { $lines[$_]{key} => $_ } 0 .. $#lines;
		return { lines => \@lines, index_of => \%index_of, filtered => \@filtered, page_count => $pages };
	}

	# The passing rows, ordered: { children => { id => [ sorted passing
	# child ids ] }, and groups => [ group ... ] or rows => [ sorted
	# top-level ids ] }. A group has the keys of a group line (see Lines)
	# and groups or rows of its own.
	method _ordered_tree () {
		my $passing = $self->_passing;
		my %children;
		my $sort_children;
		$sort_children = sub ($ids) {
			foreach my $id (@$ids) {
				$children{$id} = [ $self->_sorted( grep { $passing->{$_} } @{ $_row{$id}{children} } ) ];
				$sort_children->( $children{$id} );
			}
		};
		my $count = sub ($ids) {
			my $total = 0;
			my @todo  = @$ids;
			while ( defined( my $id = shift @todo ) ) {
				$total++;
				push @todo, @{ $children{$id} };
			}
			return $total;
		};
		my $group_level;
		$group_level = sub ( $ids, $level, @path ) {
			if ( $level > $#_group_by ) {
				my @rows = $self->_sorted(@$ids);
				$sort_children->( \@rows );
				return { rows => \@rows };
			}
			my @groups;
			foreach my $group ( $self->_groups( $ids, $level ) ) {
				my @group_path = ( @path, $group->{value} );
				my $inside     = $group_level->( $group->{ids}, $level + 1, @group_path );
				push @groups, { %$group, %$inside, group_key => _group_key(@group_path), path => \@group_path, depth => $level };
			}
			return { groups => \@groups };
		};
		my $tree = $group_level->( [ grep { $passing->{$_} } @_roots ], 0 );
		undef $group_level;
		undef $sort_children;

		# Counts need the children sorted (they are the passing ones).
		my $add_counts;
		$add_counts = sub ($groups) {
			foreach my $group (@$groups) {
				$group->{count} = $count->( $group->{ids} );
				$add_counts->( $group->{groups} ) if defined $group->{groups};
			}
		};
		$add_counts->( $tree->{groups} ) if defined $tree->{groups};
		undef $add_counts;
		$tree->{children} = \%children;
		return $tree;
	}

	# The keys of every group, collapsed or not, inside collapsed ones too.
	method _all_group_keys () {
		my $tree = $self->_ordered_tree;
		my @keys;
		my @todo = @{ $tree->{groups} // [] };
		while ( defined( my $group = shift @todo ) ) {
			push @keys, $group->{group_key};
			push @todo, @{ $group->{groups} // [] };
		}
		return @keys;
	}

	# The groups of some top-level rows at a grouping level, ordered by
	# their value: ascending, or as the sort orders the group column. Each
	# is { column, value, display, ids }.
	method _groups ( $ids, $level ) {
		my $key    = $_group_by[$level];
		my $column = $self->column($key);
		my ( @order, %group_of );
		foreach my $id (@$ids) {
			my $value     = $self->value_of( $id, $key );
			my $group_key = _group_key($value);
			push @order, $group_key unless $group_of{$group_key};
			$group_of{$group_key} //= { column => $key, value => $value, display => $self->display_of( $id, $key ), ids => [], first => $id };
			push @{ $group_of{$group_key}{ids} }, $id;
		}
		my ($sorted)  = grep { $_->[0] eq $key } @_sort;
		my $direction = defined $sorted ? $sorted->[1] : 1;
		my @groups    = map { $group_of{$_} } @order;
		@groups = sort { $column->order( $a->{value}, $b->{value}, $self->data_of( $a->{first} ), $self->data_of( $b->{first} ), $direction ) } @groups;
		delete $_->{first} foreach @groups;
		return @groups;
	}

	method lines () {
		return map { +{%$_} } @{ $self->_view->{lines} };
	}

	method line_count () {
		return scalar @{ $self->_view->{lines} };
	}

	method line ($key) {
		my $index = $self->_view->{index_of}{ $key // '' } // return undef;
		return { %{ $self->_view->{lines}[$index] } };
	}

	method line_index ($key) {
		return $self->_view->{index_of}{ $key // '' };
	}

	method filtered_row_ids () {
		return @{ $self->_view->{filtered} };
	}

	sub row_key   ($id)  { return ROW_PREFIX . $id }
	sub group_key ($key) { return GROUP_PREFIX . $key }

	sub id_of_key ($key) {
		return defined $key && index( $key, ROW_PREFIX ) == 0 ? substr( $key, length ROW_PREFIX ) : undef;
	}

	# =====================================================================
	# Pages
	# =====================================================================

	method set_page_size ($size) {
		$size = _page_size($size);
		return 0 if $size == $page_size;
		$page_size = $size;
		$self->_changed;    # the page follows the cursor
		return 1;
	}

	method page_count () {
		return $self->_view->{page_count};
	}

	method page () {
		$self->_view;
		return $_page;
	}

	# Turns to a page (kept within the pages) and puts the cursor on its
	# first line. Returns whether the page changed.
	method set_page ($page) {
		die "Term::Fabulous::Widget::Table::Model: a page must be a whole number from 1, got " . describe($page)
			unless defined $page && !ref $page && $page =~ /\A[0-9]+\z/ && $page >= 1;
		$page = min( $page + 0, $self->page_count );
		return 0 if $page == $self->page;
		$_page = $page;
		my ($first) = $self->_lines_of_page($_page);
		$_cursor = $first->{key};
		$self->_touched;
		return 1;
	}

	# The lines of the current page.
	method page_lines () {
		return map { +{%$_} } $self->_lines_of_page( $self->page );
	}

	method _lines_of_page ($page) {
		my @lines = @{ $self->_view->{lines} };
		return @lines unless $page_size;
		my $first = ( $page - 1 ) * $page_size;
		my $last  = min( $first + $page_size, scalar @lines ) - 1;
		return @lines[ $first .. $last ];
	}

	method page_of_line ($key) {
		my $index = $self->line_index($key) // return undef;
		return $page_size ? 1 + int( $index / $page_size ) : 1;
	}

	# Turns to the page of the cursor; returns whether the page changed.
	method _show_cursor_page () {
		my $page = $self->page_of_line($_cursor) // return 0;
		return 0 if $page == $self->page;
		$_page = $page;
		return 1;
	}

	# =====================================================================
	# Selection
	# =====================================================================

	method selected_ids () {
		return $self->_in_data_order( keys %_selected );
	}

	# Sorts row ids by data order (row_ids), whose ranks are kept until
	# rows are set, added or removed.
	method _in_data_order (@ids) {
		unless (%_rank) {
			my @order = $self->row_ids;
			@_rank{@order} = 0 .. $#order;
		}
		my @sorted = sort { $_rank{$a} <=> $_rank{$b} } @ids;
		return @sorted;
	}

	method is_selected ($id) {
		return defined $id && $_selected{$id} ? 1 : 0;
	}

	# Sets the selection; returns ( [ added ], [ removed ] ), both in data
	# order.
	method set_selection (@ids) {
		$self->_record($_) foreach @ids;
		my %new     = map  { $_ => 1 } @ids;
		my @added   = grep { !$_selected{$_} } keys %new;
		my @removed = grep { !$new{$_} } keys %_selected;
		return ( [], [] ) unless @added || @removed;
		%_selected = %new;
		$revision++;
		return ( [ $self->_in_data_order(@added) ], [ $self->_in_data_order(@removed) ] );
	}

	# Like set_selection, select and deselect return ( [ added ], [ removed ] )
	# with the ids as strings, but sort only the rows they change.
	method select (@ids) {
		$self->_record($_) foreach @ids;
		my @added = grep { !$_selected{$_} } uniq map { "$_" } @ids;
		return ( [], [] ) unless @added;
		@_selected{@added} = (1) x @added;
		$revision++;
		return ( [ $self->_in_data_order(@added) ], [] );
	}

	method deselect (@ids) {
		$self->_record($_) foreach @ids;
		my @removed = grep { $_selected{$_} } uniq map { "$_" } @ids;
		return ( [], [] ) unless @removed;
		delete @_selected{@removed};
		$revision++;
		return ( [], [ $self->_in_data_order(@removed) ] );
	}

	method toggle_selected ($id) {
		return $self->is_selected($id) ? $self->deselect($id) : $self->select($id);
	}

	# =====================================================================
	# Cursor
	# =====================================================================

	method cursor () {
		$self->_view;
		return $_cursor;
	}

	method anchor () {
		return $_anchor;
	}

	method set_anchor ($key) {
		$_anchor = $key;
		return;
	}

	# Puts the cursor on a line of the view, and turns to its page.
	# Returns whether it moved.
	method set_cursor ($key) {
		die "Term::Fabulous::Widget::Table::Model: the cursor needs a line of the view, got " . describe($key)
			unless defined $key && defined $self->line_index($key);
		my $before = $self->cursor;
		$_cursor = $key;
		my $turned = $self->_show_cursor_page;
		my $moved  = !defined $before || $before ne $key ? 1 : 0;
		$self->_touched if $moved || $turned;
		return $moved;
	}

	# The cursor stays on a line of the view: when its line is gone
	# (filtered out, below a collapsed row or group, removed) it moves to
	# the line that now stands for it - the nearest shown ancestor, or its
	# group - or to the first line of the page. Only an empty view has no
	# cursor. The page is the cursor's page.
	method _settle_cursor () {
		unless ( @{ $_view->{lines} } ) {
			( $_cursor, $_page ) = ( undef, 1 );
			return;
		}
		$_page   = max( 1, min( $_page, $_view->{page_count} ) );
		$_cursor = $self->_stand_in_for_cursor unless defined $_cursor && defined $_view->{index_of}{$_cursor};
		$_page   = $self->page_of_line($_cursor);
		return;
	}

	method _stand_in_for_cursor () {
		my $view = $_view;
		my $id   = id_of_key($_cursor);
		if ( defined $id && exists $_row{$id} ) {
			for ( my $node = $_row{$id}{parent}; defined $node; $node = $_row{$node}{parent} ) {
				return ROW_PREFIX . $node if defined $view->{index_of}{ ROW_PREFIX . $node };
			}
			my @groups = grep { $_->{kind} eq 'group' && $self->_group_holds( $_, $id ) } @{ $view->{lines} };
			return $groups[-1]{key} if @groups;
		}
		my $lines = $view->{lines};
		return $lines->[ min( $_cursor_index // 0, $#$lines ) ]{key};
	}

	method _group_holds ( $group, $id ) {
		my $top = $id;
		$top = $_row{$top}{parent} while defined $_row{$top}{parent};
		my @path = map { $self->value_of( $top, $_ ) } @_group_by[ 0 .. $#{ $group->{path} } ];
		return _group_key(@path) eq $group->{group_key} ? 1 : 0;
	}

	# The line key $steps lines from the cursor (negative: up), kept within
	# the lines of the whole view; undef when there is no cursor (the view
	# is empty).
	method line_after_cursor ($steps) {
		my $lines  = $self->_view->{lines};
		my $cursor = $self->cursor // return undef;
		my $index  = $self->line_index($cursor) + $steps;
		return $lines->[ max( 0, min( $#$lines, $index ) ) ]{key};
	}

	method first_line_key () {
		my $lines = $self->_view->{lines};
		return @$lines ? $lines->[0]{key} : undef;
	}

	method last_line_key () {
		my $lines = $self->_view->{lines};
		return @$lines ? $lines->[-1]{key} : undef;
	}

	# The keys of the lines from one line to another, both included, in
	# view order.
	method line_keys_between ( $from, $to ) {
		my ( $first, $last ) = map { $self->line_index($_) // die "Term::Fabulous::Widget::Table::Model: no line " . describe($_) } $from, $to;
		( $first, $last ) = ( $last, $first ) if $first > $last;
		return map { $_->{key} } @{ $self->_view->{lines} }[ $first .. $last ];
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Model - The rows of a table and how it shows them

=head1 SYNOPSIS

	my $model = $table->model;    # every table has one

	say $model->row_count, ' rows, ', scalar( $model->filtered_row_ids ), ' match';
	foreach my $line ( $model->page_lines ) {
		say $line->{kind} eq 'group'
			? "group $line->{display} ($line->{count})"
			: ( '  ' x $line->{depth} ) . $model->display_of( $line->{id}, 'name' );
	}

=head1 DESCRIPTION

The model holds everything a L<Term::Fabulous::Widget::Table> knows
apart from its widgets: the columns, the rows (a list, or a tree), the
sort, the filters, the grouping, which groups and tree rows are open,
the pages, the selection and the cursor. From these it computes the
I<view>: the lines the table shows, in order, each a data row or a
group header. It has no widgets and no colors, so it can be used and
tested on its own.

Programs normally use the table's methods (see
L<Term::Fabulous::Widget::Table>), which change the model, keep the
widgets up to date and fire the events. The model is reachable as
C<< $table->model >> for reading, for example the view's lines; change
it through the table, or the table's widgets will not follow until the
next change through the table.

=head2 Lines

L</lines> and L</page_lines> return the view as hash references:

=over

=item a row

C<< { kind => 'row', key, id, depth, has_children, expanded } >>:
C<id> is the row id, C<depth> its level in the tree (0 for top-level
rows), C<has_children> whether it has child rows that pass the filters,
C<expanded> whether they are shown.

=item a group header

C<< { kind => 'group', key, group_key, path, depth, column, value, display, count, ids, expanded } >>:
C<column> is the key of the column grouped by at this level (C<depth>,
from 0), C<value> the raw value the group's rows share and C<display>
its display text, C<path> the values of this group and the groups
around it (outermost first), C<count> the number of rows in the group
(child rows included), C<ids> the top-level row ids in it and
C<expanded> whether the group is open.

=back

C<key> names a line across changes: C<"r\0$id"> for a row,
C<"g\0..."> for a group. C<row_key> and C<id_of_key> (see
L</View>) convert.

=head2 How the view is computed

=over

=item 1.

Rows pass when they match every filter and the search (see
L<Term::Fabulous::Manual::TableRows/FILTERING>); in a tree, the ancestors
of a passing row pass too, so nothing is cut off from its parent.

=item 2.

Top-level rows are split into groups by the value of each C<group_by>
column in turn; groups are ordered by that value, ascending unless the
sort says otherwise for the column.

=item 3.

Rows are sorted within each group and, in a tree, within their parent,
by the sort; rows that compare equal keep their data order.

=item 4.

The lines are listed: each group header, then its contents unless it is
collapsed; each row, then its children if it is expanded.

=item 5.

With a C<page_size>, the lines are cut into pages of that many lines.

=back

The view is computed when it is first needed after a change and kept
until the next one. Raw values and display texts are kept per cell until
the row or the column changes, so mutators run once per cell.

=head1 CONSTRUCTOR

	my $model = Term::Fabulous::Widget::Table::Model->new(
		row_id       => 'id',          # or sub ($row) { ... }, or undef
		children_key => 'children',    # or undef for flat rows
		page_size    => 25,            # 0: one page
		expand_new   => 0,             # rows with children start expanded?
	);

The table makes its model from its own parameters of the same names;
see L<Term::Fabulous::Widget::Table/new>.

=head1 METHODS

The table's methods of the same purpose describe the behavior from the
user's side (see L<Term::Fabulous::Widget::Table/METHODS>). Methods that
take a row id, a column key or a line key die for one that does not
exist, unless they say otherwise; a method that dies changes nothing.
Methods that change something and have no result to report return an
empty list.

=head2 How rows are read

=over

=item C<row_id>

The C<row_id> parameter: a column key, a code reference, or C<undef>
when the model numbers the rows itself (from 1).

=item C<set_row_id($row_id)>

Changes how row ids are read and returns the new C<row_id>. Dies while
there are rows, and for a value that is neither C<undef>, a non-empty
string nor a code reference.

=item C<children_key>

The C<children_key> parameter: the key of the nested rows in the data,
or C<undef> for flat data.

=item C<set_children_key($key)>

Changes the key of the nested rows and returns it. Dies while there are
rows, and for a value that is neither C<undef> nor a non-empty string.

=item C<expand_new>

=item C<expand_new($bool)>

Accessor for the C<expand_new> parameter: whether rows with children
start expanded when they are added (by C<set_rows> or C<add_rows>).
Returns 1 or 0; writing affects only rows added later.

=back

=head2 Columns

=over

=item C<columns>

The L<Term::Fabulous::Widget::Table::Column> objects, in order, hidden
ones included.

=item C<column($key)>

The column with the key. Dies if there is none.

=item C<column_keys>

The keys of all columns, in order.

=item C<has_column($key)>

1 if there is a column with the key, 0 otherwise (also for C<undef>).

=item C<type_of($key)>

The C<type> of a column: C<'string'>, C<'number'> or C<'date'>.

=item C<visible_columns>

The Column objects of the visible columns, in order.

=item C<is_column_visible($key)>

1 if the column is visible, 0 if it is hidden.

=item C<set_column_visible( $key, $visible )>

Shows or hides a column. Does nothing when it is already so.

=item C<set_visible_columns(@keys)>

Shows the columns with these keys and hides all others; the order of
the columns stays. Does nothing when that is what is shown already.

=item C<add_column( $spec, $index )>

Adds a column before the column at C<$index> (from 0), or at the end
without an index, and returns its Column object. C<$spec> is a hash
reference of column parameters or a Column object. The column starts
hidden when its C<visible> is 0. Dies for an invalid C<$spec>, a key
that is in use, or an index that is not an integer from 0 to the number
of columns.

=item C<replace_column($column)>

Puts a Column object in the place of the column with the same key, and
returns it. Whether the column is visible stays as it was. Dies if there
is no column with that key.

=item C<remove_column($key)>

Removes a column. It also leaves the sort and the grouping, and every
filter that compares it is removed.

=item C<move_column( $key, $index )>

Moves a column to C<$index> (from 0) among the columns. Dies for an
index that is not an integer from 0 to the last index.

=back

=head2 Rows

=over

=item C<set_rows(\@rows)>

Replaces all rows and returns an array reference of the top-level ids.
Each row is a hash reference; its entry under C<children_key> (for tree
data) is an array reference of child rows, nested as deep as you like.
The model keeps a shallow copy of each row without that entry. Selected
ids that still exist stay selected; every row with children is expanded
when C<expand_new> is set, none otherwise. Dies when C<\@rows> is not an
array reference of hash references, when a children entry is not an
array reference, when a row has no id (see C<row_id>), or when two rows
have the same id.

=item C<add_rows( \@rows, %options )>

Adds rows (with their children) and returns their top-level ids. The
options are C<parent>, the id of the row they become children of (only
for tree data), and C<index>, the position among their new siblings
(from 0; default: after the last one). Dies for unknown options, a
C<parent> without C<children_key>, an index out of range, and for the
rows as C<set_rows> does; an id that is in use dies too.

=item C<update_row( $id, \%changes )>

Sets some entries of a row's data. Dies when C<\%changes> is not a hash
reference, when it has the C<children_key> entry (add or remove child
rows instead), and when the changed data would give the row another id.

=item C<replace_row( $id, \%data )>

Replaces a row's data with a copy of C<\%data>; a C<children_key> entry
in it is ignored and the row keeps its children. Dies when C<\%data> is
not a hash reference or would give the row another id.

=item C<set_value( $id, $key, $value )>

Sets one entry of a row's data, as C<update_row> does. C<$key> need not
be a column key.

=item C<remove_rows(@ids)>

Removes rows and their children; they also leave the selection. A row
and one of its descendants may both be given, in any order.

=item C<clear_rows>

Removes all rows, the selection and which rows are expanded.

=item C<row($id)>

A copy of a row's data (a new hash reference), without its children.

=item C<rows>

All rows as C<set_rows> takes them: an array reference of copies, with
the children of tree data nested under C<children_key>.

=item C<has_row($id)>

1 if there is a row with the id, 0 otherwise (also for C<undef>).

=item C<row_count>

The number of rows, child rows included.

=item C<row_ids>

The ids of all rows, depth-first in data order.

=item C<parent_of($id)>

The id of a row's parent, or C<undef> for a top-level row.

=item C<children_of($id)>

The ids of a row's children, in data order.

=item C<depth_of($id)>

A row's level in the tree: 0 for a top-level row.

=item C<row_revision($id)>

Goes up by one with every change of a row's data (C<update_row>,
C<replace_row>, C<set_value>); the table refreshes a row's widgets when
it changes. A row that C<set_rows> or C<add_rows> stores starts at the
model's C<revision>, so a row given again with an id the table showed
before (by C<set_rows>, or removed and added again) never has a revision
that row had, and the table shows the new data.

=back

=head2 Cells

=over

=item C<data_of($id)>

The copy of a row's data the column callbacks get: the same hash
reference until the row changes. Do not change it.

=item C<value_of( $row, $key )>

The raw value of a cell (see
L<Term::Fabulous::Widget::Table::Column/value_of>). C<$row> is a row id
or a copy from C<data_of>; any other hash reference is read as a row's
data without using the cache. Dies for an unknown column.

=item C<display_of( $row, $key )>

The display text of a cell, a string (see
L<Term::Fabulous::Widget::Table::Column/display_of>). C<$row> is as for
C<value_of>.

=back

=head2 Sorting

=over

=item C<sort_spec>

The sort as a new array reference of C<[ $key, 'asc' or 'desc' ]>
pairs, the first one sorting first; empty when unsorted.

=item C<set_sort(@spec)>

Replaces the sort. Each entry is a column key (ascending) or an array
reference C<[ $key, 'asc' or 'desc' ]>; no entries unsort. Returns 1
when the sort changed, 0 otherwise. Dies for an unknown column, a
direction other than C<'asc'> or C<'desc'>, or a column named twice.
Whether the column is C<sortable> is not checked.

=item C<cycle_sort( $key, $add )>

Sorts as a click on a header does: a column cycles from ascending to
descending to unsorted. With a false C<$add> the column becomes the only
sort key; with a true one it is added at the end of the sort, or cycled
in its place. Returns 1 when the sort changed, 0 otherwise.

=back

=head2 Filtering

=over

=item C<set_filter( $name, $filter )>

Sets the filter of a name: a L<Term::Fabulous::Widget::Table::Filter>,
or a code reference, which becomes a Filter with that C<test>. A filter
of the same name is replaced and keeps its place; C<undef> removes it
(see C<remove_filter>). The filter is checked against the columns
first (see L<Term::Fabulous::Widget::Table::Filter/check>). Returns 1
(for C<undef>, what C<remove_filter> returns).
Dies for a name that is not a non-empty string, for any other kind of
filter, and when the check dies.

=item C<remove_filter($name)>

Removes the filter of a name. Returns 1 if there was one, 0 otherwise.

=item C<filter($name)>

The Filter of a name, or C<undef>.

=item C<filter_names>

The names of the filters, in the order they were first set.

=item C<clear_filters>

Removes every filter and the search. Returns 1 if there was anything to
remove, 0 otherwise.

=item C<search>

=item C<search($text)>

Accessor for the search text (C<''> for none; writing C<undef> sets
C<''>). A row matches when the text appears, case-insensitively, in the
display text of one of its visible columns. Returns the search text.
Dies for a reference.

=item C<is_filtered>

1 when there is a filter or a search text, 0 otherwise.

=item C<expand_to_matches>

In tree data with a filter or a search, expands every row that has a
passing child, so what the filter found is shown. Returns 1 if a row was
expanded, 0 otherwise.

=back

=head2 Grouping

=over

=item C<group_by>

=item C<group_by(@keys)>

Accessor for the columns the top-level rows are grouped by, outermost
first. C<group_by(undef)> ungroups. Writing returns the new keys and
dies for an unknown column or a column named twice.

=item C<group_key_of(@path)>

The C<group_key> of the group a path names (see L</Lines>).

=item C<is_group_collapsed(@path)>

1 if the group the path names is collapsed, 0 otherwise. The path is the
group's value and those of the groups around it, outermost first, as in
a line's C<path>.

=item C<set_group_collapsed( \@path, $collapsed )>

Collapses or opens the group a path names. The state is kept by path,
so it also applies to a group that only appears later. Returns 1 when
the state changed, 0 otherwise. Dies when C<\@path> is not an array
reference.

=item C<set_all_groups_collapsed($collapsed)>

With a true value, collapses every group the rows that pass the
filters form now, nested groups included; with a false one, opens
every group.

=back

=head2 Tree

=over

=item C<is_expanded($id)>

1 if the row is expanded, 0 otherwise.

=item C<set_expanded( $id, $expanded )>

Expands or collapses a row. Returns 1 when the state changed, 0
otherwise.

=item C<set_all_expanded($expanded)>

Expands every row that has children, or collapses every row.

=back

=head2 View

=over

=item C<lines>

The lines of the whole view (every page), as new hash references (see
L</Lines>).

=item C<line_count>

The number of lines of the whole view.

=item C<line($key)>

The line with the key as a new hash reference, or C<undef> when it is
not in the view.

=item C<line_index($key)>

The position of a line in the whole view (from 0), or C<undef> when it
is not in the view.

=item C<filtered_row_ids>

The ids of every row that passes the filters, in view order; rows
inside collapsed groups and below collapsed rows included.

=back

These are functions, not methods (call them with the package name):

=over

=item C<row_key($id)>

The line key of a row.

=item C<group_key($group_key)>

The line key of a group, from its C<group_key>.

=item C<id_of_key($key)>

The row id of a row's line key, or C<undef> for a group's key or
C<undef>.

=back

=head2 Pages

=over

=item C<page_size>

The number of lines per page; 0 for no pages.

=item C<set_page_size($size)>

Changes the page size; the page becomes the cursor's page. Returns 1
when the size changed, 0 otherwise. Dies for a value that is not a
non-negative integer.

=item C<page_count>

The number of pages, at least 1.

=item C<page>

The current page, from 1.

=item C<set_page($page)>

Turns to a page (at most the last one) and puts the cursor on its first
line. Returns 1 when the page changed, 0 otherwise (the cursor then
stays). Dies for a value that is not a whole number from 1.

=item C<page_lines>

The lines of the current page, as new hash references.

=item C<page_of_line($key)>

The page a line is on, or C<undef> when it is not in the view.

=back

=head2 Selection

=over

=item C<selected_ids>

The ids of the selected rows, depth-first in data order; rows that are
filtered out stay selected.

=item C<is_selected($id)>

1 if the row is selected, 0 otherwise (also for an unknown id).

=item C<set_selection(@ids)>

Selects exactly these rows. Returns C<( \@added, \@removed )>: the ids
that became selected and those that stopped being selected, each in
data order (two empty array references when nothing changed). The model
does not know the table's C<selection> mode; any number of rows may be
selected.

=item C<select(@ids)>

Adds rows to the selection. Returns as C<set_selection> does.

=item C<deselect(@ids)>

Removes rows from the selection. Returns as C<set_selection> does.

=item C<toggle_selected($id)>

Selects a row that is not selected, deselects one that is. Returns as
C<set_selection> does.

=back

=head2 Cursor

The cursor is always on a line of the current page while the view has
lines, and C<undef> when it has none. When its line leaves the view, it
moves to the line that stands for it: the nearest shown ancestor row, or
its group header, or else the first line of the page.

=over

=item C<cursor>

The line key of the cursor, or C<undef> when the view is empty.

=item C<set_cursor($key)>

Puts the cursor on a line and turns to the line's page. Returns 1 when
the cursor moved to another line, 0 otherwise. Dies when the line is not
in the view.

=item C<anchor>

The line key a range selection extends from, or C<undef>.

=item C<set_anchor($key)>

Sets the anchor; the model does not check it.

=item C<line_after_cursor($steps)>

The key of the line C<$steps> lines below the cursor (above for a
negative number), kept within the lines of the whole view; C<undef>
when there is no cursor.

=item C<first_line_key>

=item C<last_line_key>

The key of the first or the last line of the whole view, or C<undef>
when the view is empty.

=item C<line_keys_between( $from, $to )>

The keys of the lines from one line to another, both included, in view
order (C<$from> may come after C<$to>). Dies when a line is not in the
view.

=back

=head2 Changes

=over

=item C<revision>

Counts every change: of the rows, the columns, the sort, the filters,
the grouping, what is open, the page, the selection and the cursor.

=item C<columns_revision>

Counts the changes of the columns: added, replaced, removed, moved,
shown or hidden.

=back

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>.

=cut
