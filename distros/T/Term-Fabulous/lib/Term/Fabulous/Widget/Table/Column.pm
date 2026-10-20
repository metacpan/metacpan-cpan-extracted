package Term::Fabulous::Widget::Table::Column;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

class Term::Fabulous::Widget::Table::Column :strict(params) {
	use Term::Fabulous::Check qw(boolean describe one_of sizing string);
	use Term::Fabulous::Widget::Table::Style qw(style_hash);
	use Term::Fabulous::Widget::Table::Value qw(is_blank number_of date_epoch compare_values natural_compare);

	my @TYPES      = qw(string number date);
	my @ALIGNS     = qw(left center right);
	my @WRAPS      = qw(words newlines none);
	my @FILTER_ONS = qw(value display);
	my %COMPARATOR = (
		string  => sub ( $left, $right ) { compare_values( string => $left, $right ) },
		natural => \&natural_compare,
		number  => sub ( $left, $right ) { compare_values( number => $left, $right ) },
		date    => sub ( $left, $right ) { compare_values( date   => $left, $right ) },
	);

	# Whether a raw value can be ordered by a named comparator; the others
	# sort last.
	my %READABLE = (
		string  => sub ($value) { is_blank($value)           ? 0 : 1 },
		natural => sub ($value) { is_blank($value)           ? 0 : 1 },
		number  => sub ($value) { defined number_of($value)  ? 1 : 0 },
		date    => sub ($value) { defined date_epoch($value) ? 1 : 0 },
	);

	field $key          :param :reader;
	field $title        :param :reader = undef;
	field $type         :param :reader = 'string';
	field $value        :param = undef;
	field $mutator      :param = undef;
	field $align        :param :reader = undef;
	field $header_align :param :reader = undef;
	field $width        :param = 'fit';
	field $wrap         :param :reader = 'words';
	field $sortable     :param :reader = 1;
	field $compare      :param = undef;
	field $filterable   :param :reader = 1;
	field $filter_on    :param :reader = undef;
	field $cell         :param :reader = undef;
	field $update_cell  :param :reader = undef;
	field $header       :param :reader = undef;
	field $cell_style   :param :reader = undef;
	field $style        :param = undef;
	field $header_style :param = undef;
	field $visible      :param :reader = 1;

	field @_mutators;
	field $_comparator;    # code reference for a named comparator, undef for one of the user's
	field %_params;    # what the column was made with, for with()

	ADJUST {
		%_params = (
			key          => $key,          title      => $title,      type        => $type,
			value        => $value,        mutator    => $mutator,    align       => $align,
			header_align => $header_align, width      => $width,      wrap        => $wrap,
			sortable     => $sortable,     compare    => $compare,    filterable  => $filterable,
			filter_on    => $filter_on,    cell       => $cell,       update_cell => $update_cell,
			header       => $header,       cell_style => $cell_style, style       => $style,
			header_style => $header_style, visible    => $visible,
		);

		die "Term::Fabulous::Widget::Table::Column: key must be a non-empty string, got " . describe($key)
			unless defined $key && !ref $key && length $key;
		$title = string( $self, title => $title // $key );
		my $owner = "Term::Fabulous::Widget::Table::Column '$key'";
		one_of( $owner, type => $type, @TYPES );
		$align        //= $type eq 'number' ? 'right' : 'left';
		$header_align //= $align;
		foreach my $setting ( [ align => $align ], [ header_align => $header_align ] ) {
			one_of( $owner, @$setting, @ALIGNS );
		}
		$width = sizing( $self, 'width', $width );
		one_of( $owner, wrap => $wrap, @WRAPS );
		$sortable   = boolean( $self, sortable   => $sortable );
		$filterable = boolean( $self, filterable => $filterable );
		$visible    = boolean( $self, visible    => $visible );
		$filter_on //= $type eq 'string' ? 'display' : 'value';
		one_of( $owner, filter_on => $filter_on, @FILTER_ONS );

		$self->_check_code( value => $value );
		@_mutators = ref $mutator eq 'ARRAY' ? @$mutator : defined $mutator ? ($mutator) : ();
		$self->_check_code( "mutator", $_ ) foreach @_mutators;
		$self->_check_code( $_->[0], $_->[1] ) foreach [ cell => $cell ], [ update_cell => $update_cell ], [ header => $header ], [ cell_style => $cell_style ];
		die "Term::Fabulous::Widget::Table::Column '$key': update_cell needs a cell" if defined $update_cell && !defined $cell;

		$compare //= $type;
		if ( ref $compare eq 'CODE' ) {
			$_comparator = undef;
		}
		else {
			die "Term::Fabulous::Widget::Table::Column '$key': compare must be a code reference or one of 'string', 'natural', 'number', 'date', got " . describe($compare)
				unless defined $compare && !ref $compare && $COMPARATOR{$compare};
			$_comparator = $compare;
		}

		$style        = style_hash( $self, "column '$key' style",        column => $style );
		$header_style = style_hash( $self, "column '$key' header_style", header => $header_style );
	}

	method _check_code ( $name, $code ) {
		return if !defined $code || ref $code eq 'CODE';
		die "Term::Fabulous::Widget::Table::Column '$key': $name must be a code reference, got " . describe($code);
	}

	# A new column with some parameters changed.
	method with (%changes) {
		return Term::Fabulous::Widget::Table::Column->new( %_params, %changes );
	}

	# The parameters the column was made with.
	method params () {
		return %_params;
	}

	method width () {
		return {%$width};
	}

	method style () {
		return {%$style};
	}

	method header_style () {
		return {%$header_style};
	}

	method mutators () {
		return @_mutators;
	}

	method has_mutators () {
		return @_mutators ? 1 : 0;
	}

	method computes_value () {
		return defined $value ? 1 : 0;
	}

	method value_of ($row) {
		return defined $value ? $value->($row) : $row->{$key};
	}

	# The text a cell shows: the raw value after every mutator.
	method display_of ( $raw, $row ) {
		my $shown = $raw;
		$shown = $_->( $shown, $row ) foreach @_mutators;
		return defined $shown ? "$shown" : '';
	}

	method has_custom_compare () {
		return defined $_comparator ? 0 : 1;
	}

	method sorts_numerically () {
		return defined $_comparator && ( $_comparator eq 'number' || $_comparator eq 'date' ) ? 1 : 0;
	}

	# What a named comparator orders a raw value by: a number (number,
	# date) or a string (string, natural) that compares with <=> or cmp as
	# the comparator would; undef for a value it cannot read, which sorts
	# last. Natural keys write every digit run as its length and its
	# digits, so "9" sorts before "10".
	method sort_key ($raw) {
		die "Term::Fabulous::Widget::Table::Column '$key': a column with a compare code reference has no sort keys" unless defined $_comparator;
		return undef unless $READABLE{$_comparator}->($raw);
		return number_of($raw) if $_comparator eq 'number';
		return date_epoch($raw) if $_comparator eq 'date';
		my $text = fc "$raw";
		return $text if $_comparator eq 'string';
		$text =~ s/([0-9]+)/ my $digits = $1 =~ s{\A0+(?=[0-9])}{}r; sprintf( '%05d', length $digits ) . $digits /ge;
		return $text;
	}

	# Orders two rows by this column in a direction (1 ascending, -1
	# descending). Values a named comparator cannot read sort last either
	# way; a comparator of your own sees every value.
	method order ( $left, $right, $left_row, $right_row, $direction ) {
		return $direction * $compare->( $left, $right, $left_row, $right_row ) unless defined $_comparator;
		my $readable = $READABLE{$_comparator};
		my ( $left_ok, $right_ok ) = ( $readable->($left), $readable->($right) );
		return $right_ok - $left_ok unless $left_ok && $right_ok;
		return $direction * $COMPARATOR{$_comparator}->( $left, $right );
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Table::Column - What a table column shows and how

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Mutator qw(datetime number);

	my $table = Term::Fabulous::Widget::Table->new(
		id      => 'orders',
		columns => [
			{ key => 'id',      title => '#',        type => 'number', width => 'fixed(6)' },
			{ key => 'client',  title => 'Client',   width => 'grow', compare => 'natural' },
			{ key => 'placed',  title => 'Placed',   type => 'date', mutator => datetime('%d %b %H:%M') },
			{ key => 'total',   title => 'Total',    type => 'number', mutator => number( decimals => 2 ),
			  cell_style => sub ($cell) { $cell->{value} < 0 ? { text_color => '#e06c75' } : {} } },
			{ key => 'items',   title => 'Items',    value => sub ($row) { scalar @{ $row->{lines} } }, type => 'number' },
			{ key => 'note',    title => 'Note',     width => 'fit(0, 30)', sortable => 0, visible => 0 },
		],
	);

	# Columns are values: change one by making a new one.
	$table->update_column( total => title => 'Sum' );
	my $column = $table->column('placed');
	say $column->title, ' is a ', $column->type, ' column';

=head1 DESCRIPTION

A column of a L<Term::Fabulous::Widget::Table> decides, for every row,
which value is the cell's I<raw value>, what text it shows, how it is
aligned, sized, sorted and filtered, and which widget shows it. You
describe columns as hash references in the table's C<columns> parameter
(or to L<Term::Fabulous::Widget::Table/add_column>); the table makes a
Column object of each. A Column is immutable: to change one, use
L<Term::Fabulous::Widget::Table/update_column>, which builds a new one
with L</with>. Which columns are visible is decided by the table (see
L<Term::Fabulous::Manual::Tables/Choosing the visible columns>);
C<visible> is only where a new column starts.

In a KDL layout file, a column is a C<column> node inside the table's
node; see L<Term::Fabulous::Widget::Table/KDL PROPERTIES>.

=head2 Values, display text and cells

For every row the column computes:

=over

=item the raw value

C<< $column->value_of($row) >>: what the C<value> code reference
returns for the row's data, or the row's entry under the column key.
Sorting uses it, and so do filters unless they say otherwise.

=item the display text

The raw value after every C<mutator>, as a string (C<undef> becomes
C<''>). This is what the cell shows, and what filters with
C<< on => 'display' >> and the table's search compare.

=item the cell widget

A L<Term::Fabulous::Widget::Text> with the display text, aligned,
wrapped and colored as the column and the styles say; or, with a
C<cell> code reference, any widget it returns.

=back

=head1 PARAMETERS

All parameters but C<key> are optional; unknown parameters and invalid
values die.

=over

=item C<key>

Required. A non-empty string that names the column, unique in its
table. It is also where the raw value comes from when there is no
C<value>.

=item C<title>

The text of the header cell, also shown in the column chooser (where an
empty title shows the key instead). Default: the key.

=item C<type>

C<'string'> (the default), C<'number'> or C<'date'>. It decides the
default alignment, the default comparator and how filters compare the
column's cells (see L<Term::Fabulous::Widget::Table::Filter/What a
condition compares>). Date values may be epoch seconds, date strings
such as C<'2024-05-03 14:30'>, or objects with an C<epoch> method (see
L<Term::Fabulous::Widget::Table::Value/date_epoch>).

=item C<value>

A code reference C<< sub ($row) { ... } >> that returns the raw value
from a copy of the row's data, for computed columns. Default: the row's
entry under C<key>.

=item C<mutator>

A code reference C<< sub ( $value, $row ) { ... } >>, or an array
reference of them, that turns the raw value into the display text; the
mutators run in order, each on the result of the one before. See
L<Term::Fabulous::Widget::Table::Mutator> for ready-made ones (dates,
numbers, sizes, ...). Default: none, the raw value is shown as it is.

=item C<align>

C<'left'>, C<'center'> or C<'right'>: where the content sits in the
cell. Default: C<'right'> for number columns, C<'left'> otherwise.

=item C<header_align>

The same for the header cell. Default: C<align>.

=item C<width>

How wide the column is, as a sizing string or a hash from the
C<sizing_*> functions of L<Clay::XS> (see
L<Term::Fabulous::Check/sizing>):

=for highlighter language=text

	'fit'           as wide as its widest cell (the default)
	'fit(8)'        at least 8 columns
	'fit(0, 30)'    at most 30 columns; longer text wraps
	'fixed(12)'     exactly 12 columns; longer text wraps
	'grow'          takes a share of the room the table has left over
	'grow(10, 40)'  the same, between 10 and 40 columns
	'percent(25)'   a quarter of the table's width

The width includes the cell padding. Header cells, the filter field and
every cell of the column are sized together, so the column is as wide as
the widest of them (within the limits). A C<grow> or C<percent> column
needs a table with a width of its own, and stops the table from
scrolling sideways: when the table is too narrow, the table's C<fit> and
C<grow> columns get narrower, down to their longest word, and their text
wraps; see L<Term::Fabulous::Manual::Tables/Column widths>.

=item C<wrap>

C<'words'> (the default), C<'newlines'> or C<'none'>: how the text of a
default cell breaks into lines when the column is narrower than the text
(see L<Term::Fabulous::Widget::Text/wrap_mode>). Rows grow to the height
of their tallest cell. In a table with a C<grow> or C<percent> column, a
line with C<'newlines'> or C<'none'> keeps its width while the other
columns can still get narrower; then it is cut off inside the cell
padding, a single long word too. Other tables scroll sideways instead.

=item C<sortable>

A boolean, default 1: whether the user may sort by the column (clicking
its header). The table's L<C<sort_by>|Term::Fabulous::Widget::Table/sort_by>
method still sorts by any column.

=item C<compare>

How two raw values are ordered: C<'string'> (case-insensitive),
C<'natural'> (digit runs as numbers: I<file9> before I<file10>),
C<'number'> or C<'date'> - with these, values that cannot be read
(blank cells, words in a number column) sort last in both directions -
or a code reference C<< sub ( $a, $b, $row_a, $row_b ) { ... } >>
returning a negative number, 0 or a positive number for ascending order
(the table reverses it for descending order; it sees every value,
blank ones included). Default: the column's C<type>.

=item C<filterable>

A boolean, default 1: whether the table's filter row has a field for
the column.

=item C<filter_on>

C<'display'> or C<'value'>: what the filter row's expression for this
column compares. Default: C<'display'> for string columns (users type
what they see), C<'value'> for number and date columns.

=item C<cell>

A code reference C<< sub ($cell) { ... } >> that returns the widget
shown in a cell, any widget (a Box with several children, a Button, a
Checkbox, a PixelCanvas). C<$cell> is a hash reference with the keys
C<value> (the raw value), C<display> (the display text), C<row> (a copy
of the row's data), C<id> (the row's id), C<column> (this Column) and
C<table>. The table builds the widget when the row first shows and
again when the row's data or the column changes, unless there is an
C<update_cell>. Default: a Text widget.

=item C<update_cell>

A code reference C<< sub ( $widget, $cell ) { ... } >> that brings a
widget C<cell> made up to date with new data, instead of building a new
one. Use it for input widgets, so that the focus and what the user is
typing survive a change of the row (for example one the input itself
made). Only with C<cell>.

=item C<header>

A code reference C<< sub ($column) { ... } >> that returns the widget
of the header cell, in place of the title. The sort marker still
follows it. Default: the title in bold. See
L<Term::Fabulous::Manual::Tables/Widgets as column titles>.

=item C<cell_style>

A code reference C<< sub ($cell) { ... } >>, called with the same hash
as C<cell>, that returns a style hash (or C<undef>) for the cell:
conditional formatting such as red negative numbers. See
L<Term::Fabulous::Manual::TableStyles/STYLES AND BORDERS>.

=item C<style>

A style hash for every cell of the column: C<text_color>,
C<background_color>, C<bold>, C<italic>, C<underline>, C<border_color>
and the lines C<border_left>, C<border_right> and C<row_lines> (between
the cells of the column).

=item C<header_style>

A style hash for the column's header cell: C<text_color>,
C<background_color>, C<bold>, C<italic>, C<underline>,
C<border_color>.

=item C<visible>

A boolean, default 1: whether the column is shown when it is added to
the table.

=back

=head1 METHODS

The parameters have readers of the same names: C<key>, C<title>,
C<type>, C<align>, C<header_align>, C<wrap>, C<sortable>,
C<filterable>, C<filter_on>, C<cell>, C<update_cell>, C<header>,
C<cell_style>, C<visible>; C<width>, C<style> and C<header_style>
return copies, C<mutators> the list of mutators.

=head2 value_of

=for highlighter language=perl

	my $raw = $column->value_of($row);

The raw value of the column in a row's data.

=head2 display_of

	my $text = $column->display_of( $raw, $row );

The display text of a raw value: the value after the mutators, as a
string.

=head2 has_mutators

1 if the column has at least one C<mutator>, 0 otherwise; without one,
the display text is the raw value as a string.

=head2 computes_value

1 if the column has a C<value> code reference, 0 if the raw value is the
row's entry under the column key.

=head2 order

	my $order = $column->order( $left, $right, $left_row, $right_row, $direction );

Orders two raw values for a sort in C<$direction> (1 ascending, -1
descending); used by the table.

=head2 has_custom_compare

1 if C<compare> is a code reference, 0 for a named comparator
(C<'string'>, C<'natural'>, C<'number'> or C<'date'>).

=head2 sorts_numerically

1 if the named comparator is C<'number'> or C<'date'>, so that
L</sort_key> returns numbers; 0 for C<'string'>, C<'natural'> and a
code reference.

=head2 sort_key

	my $key = $column->sort_key($raw);

What the named comparator orders a raw value by: the number for
C<'number'>, the epoch seconds for C<'date'>, the case-folded text for
C<'string'>, and for C<'natural'> the case-folded text with every run of
digits written as its length (five digits) followed by the digits
without leading zeros. Keys compare with C<< <=> >> when
L</sorts_numerically> is 1 and with C<cmp> otherwise, in the order the
comparator gives. Returns C<undef> for a value the comparator cannot
read (blank, or not a number or a date); the table sorts these last.
Dies for a column whose C<compare> is a code reference.

=head2 with

	my $renamed = $column->with( title => 'Sum' );

A new column made with the parameters of this one and the changes.

=head2 params

The parameters the column was made with, as a list of pairs.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::Table::Mutator>,
L<Term::Fabulous::Widget::Table::Filter>, L<Term::Fabulous::Manual::Tables/COLUMNS>,
L<Term::Fabulous::Cookbook::TableStyles/Size, align and wrap columns (widths, wrapping, widget titles)>.

=cut
