package Term::Fabulous::Widget::Table::Filter;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Widget::Table::Filter :strict(params) {
	use Feature::Compat::Try;
	use List::Util ();    # all and any are methods of this class
	use Scalar::Util qw(blessed);
	use Term::Fabulous::Check qw(describe one_of optional);
	use Term::Fabulous::Widget::Table::Value qw(is_blank number_of date_epoch date_interval);

	my %TEXT_OP    = map { $_ => 1 } qw(contains not_contains equals not_equals starts_with ends_with matches);
	my %BLANK_OP   = map { $_ => 1 } qw(empty not_empty);
	my %COMPARE_OP = map { $_ => 1 } ( '=', '!=', '<', '<=', '>', '>=', 'between', 'in' );
	my %ALIAS      = ( '==' => '=', eq => '=', ne => '!=', lt => '<', le => '<=', gt => '>', ge => '>=' );
	my @TYPES      = qw(string number date);
	my @ONS        = qw(value display);

	my $NUMBER = qr/[-+]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][-+]?[0-9]+)?/;

	# A condition on one column, a test, or a combination of filters.
	field $column         :param :reader = undef;
	field $op             :param :reader = undef;
	field $value          :param = undef;
	field $on             :param :reader = 'value';
	field $type           :param :reader = undef;
	field $case_sensitive :param :reader = 0;
	field $test           :param :reader = undef;
	field $combine        :param :reader = undef;    # all, any or not
	field $filters        :param = undef;    # the filters combine joins

	# What the comparison operand turned into: a number, [ first, after )
	# epoch spans, a compiled pattern or folded text; built on first use
	# for the column's type.
	field %_operand_for_type;

	ADJUST {
		die "Term::Fabulous::Widget::Table::Filter: give 'op', 'test' or a combination ('all', 'any', 'not'), not several"
			if 1 < grep { defined } $op, $test, $combine;
		$self->_check_combination if defined $combine;
		$self->_check_test if defined $test;
		$self->_check_condition if defined $op;
		die "Term::Fabulous::Widget::Table::Filter: a filter needs 'op' (with 'column'), 'test' or a combination"
			unless defined $op || defined $test || defined $combine;
		one_of( $self, on => $on, @ONS );
		optional( \&one_of, $self, type => $type, @TYPES );
		$case_sensitive = $case_sensitive ? 1 : 0;
	}

	method _check_combination () {
		die "Term::Fabulous::Widget::Table::Filter: internal: unknown combination '$combine'" unless $combine =~ /\A(?:all|any|not)\z/;
		die "Term::Fabulous::Widget::Table::Filter: $combine takes filters, not a column" if defined $column;
		foreach my $filter (@$filters) {
			die "Term::Fabulous::Widget::Table::Filter: $combine takes Term::Fabulous::Widget::Table::Filter objects or code references, got " . describe($filter)
				unless blessed $filter && $filter->isa('Term::Fabulous::Widget::Table::Filter');
		}
		die "Term::Fabulous::Widget::Table::Filter: not takes exactly one filter" if $combine eq 'not' && @$filters != 1;
		return;
	}

	method _check_test () {
		die "Term::Fabulous::Widget::Table::Filter: test must be a code reference, got " . describe($test) unless ref $test eq 'CODE';
		return;
	}

	method _check_condition () {
		$op = $ALIAS{$op} // $op;
		die "Term::Fabulous::Widget::Table::Filter: unknown op " . describe($op) . " (known: " . join( ', ', sort( keys %TEXT_OP, keys %BLANK_OP, keys %COMPARE_OP ) ) . ")"
			unless $TEXT_OP{$op} || $BLANK_OP{$op} || $COMPARE_OP{$op};
		die "Term::Fabulous::Widget::Table::Filter: op '$op' needs a column" unless defined $column && !ref $column && length $column;
		return if $BLANK_OP{$op};
		die "Term::Fabulous::Widget::Table::Filter: op '$op' needs a value" unless defined $value;
		if ( $op eq 'between' ) {
			die "Term::Fabulous::Widget::Table::Filter: op 'between' needs [ from, to ] as its value, got " . describe($value)
				unless ref $value eq 'ARRAY' && @$value == 2 && !grep { !defined || ref } @$value;
			$value = [@$value];
		}
		elsif ( $op eq 'in' ) {
			die "Term::Fabulous::Widget::Table::Filter: op 'in' needs an array reference of values, got " . describe($value)
				unless ref $value eq 'ARRAY' && !grep { !defined || ref } @$value;
			$value = [@$value];
		}
		elsif ( $op eq 'matches' ) {
			die "Term::Fabulous::Widget::Table::Filter: op 'matches' needs a pattern (qr// or a string), got " . describe($value)
				if ref $value && ref $value ne 'Regexp';
			_compile_pattern( $value, $case_sensitive );
		}
		else {
			die "Term::Fabulous::Widget::Table::Filter: op '$op' needs a plain value, got " . describe($value) if ref $value;
		}
		$self->_operand($type) if defined $type && $COMPARE_OP{$op};    # dies now for a value the type cannot read
		return;
	}

	# Dies when a column the filter compares is unknown to $source or an
	# operand cannot be read as the type of its column; the table checks
	# every filter it is given.
	method check ($source) {
		$_->check($source) foreach $self->filters;
		return $self unless defined $column;
		die "Term::Fabulous::Widget::Table::Filter: there is no column '$column'" unless $source->has_column($column);
		$self->_operand( $type // $source->type_of($column) ) if defined $op && $COMPARE_OP{$op};
		return $self;
	}

	# A qr// pattern brings its own flags; a string is compiled,
	# case-insensitively unless asked otherwise.
	sub _compile_pattern ( $pattern, $case_sensitive ) {
		return $pattern if ref $pattern eq 'Regexp';
		try {
			return $case_sensitive ? qr/$pattern/ : qr/$pattern/i;
		}
		catch ($error) {
			$error =~ s/ at \S+ line \d+\.?\n?\z//;
			die "Term::Fabulous::Widget::Table::Filter: invalid pattern '$pattern': $error\n";
		}
	}

	# ---------------------------------------------------------------------
	# Combinations
	# ---------------------------------------------------------------------

	sub _as_filters (@filters) {
		return map { ref $_ eq 'CODE' ? Term::Fabulous::Widget::Table::Filter->new( test => $_ ) : $_ } @filters;
	}

	method all :common (@filters) {
		return $class->new( combine => 'all', filters => [ _as_filters(@filters) ] );
	}

	method any :common (@filters) {
		return $class->new( combine => 'any', filters => [ _as_filters(@filters) ] );
	}

	method not :common ($filter) {
		return $class->new( combine => 'not', filters => [ _as_filters($filter) ] );
	}

	method filters () {
		return defined $filters ? @$filters : ();
	}

	method value () {
		return ref $value eq 'ARRAY' ? [@$value] : $value;
	}

	# The columns the filter reads, for the table to check that they exist.
	method columns () {
		return $column if defined $column;
		return map { $_->columns } $self->filters;
	}

	# ---------------------------------------------------------------------
	# Matching
	# ---------------------------------------------------------------------

	# $row is the row's data; $source answers value_of($row, $key),
	# display_of($row, $key) and type_of($key).
	method matches ( $row, $source ) {
		return ( List::Util::all { $_->matches( $row, $source ) } @$filters ) ? 1 : 0 if defined $combine && $combine eq 'all';
		return ( List::Util::any { $_->matches( $row, $source ) } @$filters ) ? 1 : 0 if defined $combine && $combine eq 'any';
		return $filters->[0]->matches( $row, $source )                        ? 0 : 1 if defined $combine;
		return $test->($row)                                                  ? 1 : 0 if defined $test && !defined $column;

		my $cell = $on eq 'display' ? $source->display_of( $row, $column ) : $source->value_of( $row, $column );
		return $test->( $cell, $row ) ? 1 : 0 if defined $test;
		return $self->_matches_cell( $cell, $type // $source->type_of($column) );
	}

	method _matches_cell ( $cell, $cell_type ) {
		return is_blank($cell) ? 1 : 0 if $op eq 'empty';
		return is_blank($cell) ? 0 : 1 if $op eq 'not_empty';
		return $self->_matches_text( $cell // '' ) if $TEXT_OP{$op};

		my $operand = $self->_operand($cell_type);
		return $self->_matches_string( $cell, $operand ) if $cell_type eq 'string';
		return $self->_matches_number( number_of($cell), $operand ) if $cell_type eq 'number';
		return $self->_matches_date( date_epoch($cell), $operand );
	}

	method _matches_text ($cell) {
		return "$cell" =~ _compile_pattern( $value, $case_sensitive ) ? 1 : 0 if $op eq 'matches';
		my ( $text, $wanted ) = $case_sensitive ? ( "$cell", $value ) : ( fc("$cell"), fc($value) );
		return index( $text, $wanted ) >= 0                  ? 1 : 0 if $op eq 'contains';
		return index( $text, $wanted ) < 0                   ? 1 : 0 if $op eq 'not_contains';
		return $text eq $wanted                              ? 1 : 0 if $op eq 'equals';
		return $text ne $wanted                              ? 1 : 0 if $op eq 'not_equals';
		return substr( $text, 0, length $wanted ) eq $wanted ? 1 : 0 if $op eq 'starts_with';
		return 1 if $wanted eq '';    # ends_with
		return length($wanted) <= length($text) && substr( $text, -length($wanted) ) eq $wanted ? 1 : 0;
	}

	# The operand as the comparisons of a column type need it; dies for a
	# value that type cannot read.
	method _operand ($cell_type) {
		return $_operand_for_type{$cell_type} //= do {
			my @values = ref $value eq 'ARRAY' ? @$value : ($value);
			my $read
				= $cell_type eq 'number' ? sub ($item) { number_of($item) // die "Term::Fabulous::Widget::Table::Filter: op '$op' on a number column needs numbers, got '$item'\n" }
				: $cell_type eq 'date'
				? sub ($item) { _date_span($item) // die "Term::Fabulous::Widget::Table::Filter: op '$op' on a date column needs dates (2024-05-03, 2024-05-03 14:30, epoch seconds), got '$item'\n" }
				: sub ($item) { $case_sensitive ? "$item" : fc("$item") };
			[ map { $read->($_) } @values ];
		};
	}

	# [ first, after ) of a date operand: a date string's span, or the one
	# second an epoch number or object names.
	sub _date_span ($item) {
		my $interval = date_interval($item);
		return $interval if defined $interval;
		my $epoch = date_epoch($item) // return undef;
		return [ $epoch, $epoch + 1 ];
	}

	method _matches_string ( $cell, $operand ) {
		return 0 if is_blank($cell);
		my $text = $case_sensitive ? "$cell" : fc("$cell");
		return ( List::Util::any { $text eq $_ } @$operand )    ? 1 : 0 if $op eq 'in';
		return $operand->[0] le $text && $text le $operand->[1] ? 1 : 0 if $op eq 'between';
		return _compare( $text cmp $operand->[0], $op );
	}

	method _matches_number ( $number, $operand ) {
		return 0 unless defined $number;
		return ( List::Util::any { $number == $_ } @$operand )      ? 1 : 0 if $op eq 'in';
		return $operand->[0] <= $number && $number <= $operand->[1] ? 1 : 0 if $op eq 'between';
		return _compare( $number <=> $operand->[0], $op );
	}

	# A date compares with a span: equal inside it, less before its first
	# second, greater from the first second after it.
	method _matches_date ( $epoch, $spans ) {
		return 0 unless defined $epoch;
		my $inside = sub ($span) { $span->[0] <= $epoch && $epoch < $span->[1] };
		return ( List::Util::any { $inside->($_) } @$spans )       ? 1 : 0 if $op eq 'in';
		return $spans->[0][0] <= $epoch && $epoch < $spans->[1][1] ? 1 : 0 if $op eq 'between';
		my $span = $spans->[0];
		return _compare( $epoch < $span->[0] ? -1 : $epoch >= $span->[1] ? 1 : 0, $op );
	}

	sub _compare ( $order, $op ) {
		return $order == 0 ? 1 : 0 if $op eq '=';
		return $order != 0 ? 1 : 0 if $op eq '!=';
		return $order < 0  ? 1 : 0 if $op eq '<';
		return $order <= 0 ? 1 : 0 if $op eq '<=';
		return $order > 0  ? 1 : 0 if $op eq '>';
		return $order >= 0 ? 1 : 0;    # >=
	}

	# ---------------------------------------------------------------------
	# Filter expressions, as typed into a filter field
	# ---------------------------------------------------------------------

	method parse :common ( $expression, %options ) {
		my @unknown = grep { !/\A(?:column|type|on|case_sensitive)\z/ } sort keys %options;
		die "Term::Fabulous::Widget::Table::Filter: parse does not accept @unknown (known: case_sensitive, column, on, type)" if @unknown;
		die "Term::Fabulous::Widget::Table::Filter: parse needs a column" unless defined $options{column};
		my $type = $options{type} // 'string';
		one_of( $class, 'parse type' => $type, @TYPES );
		die "Term::Fabulous::Widget::Table::Filter: parse needs a string, got " . describe($expression) if ref $expression || !defined $expression;

		my $text = $expression =~ s/\A\s+|\s+\z//gr;
		return undef unless length $text;
		my %common = ( column => $options{column}, type => $type, on => $options{on} // 'value', case_sensitive => $options{case_sensitive} // 0 );
		return $class->new( %common, op => 'empty' ) if $text eq '=';
		return $class->new( %common, op => 'not_empty' ) if $text eq '!=';
		my ( $op, $value ) = $type eq 'string' ? _parse_text($text) : _parse_ordered( $type, $text );
		return $class->new( %common, op => $op, value => $value );
	}

	sub _parse_text ($text) {
		return ( matches      => $1 ) if $text =~ m{\A/(.+)/\z}s;
		return ( not_equals   => $1 ) if $text =~ /\A!=\s*(.+)\z/s;
		return ( equals       => $1 ) if $text =~ /\A=\s*(.+)\z/s;
		return ( not_contains => $1 ) if $text =~ /\A!\s*(.+)\z/s;
		return ( equals       => $1 ) if $text =~ /\A\^(.+)\$\z/s;
		return ( starts_with  => $1 ) if $text =~ /\A\^(.+)\z/s;
		return ( ends_with    => $1 ) if $text =~ /\A(.+)\$\z/s;
		return ( contains     => $text );
	}

	sub _parse_ordered ( $type, $text ) {
		my $reads = $type eq 'number' ? sub ($item) { $item =~ /\A$NUMBER\z/ } : sub ($item) { defined date_interval($item) };
		if ( my ( $from, $to ) = $text =~ /\A(.+?)\s*\.\.\s*(.+)\z/s ) {
			return ( between => [ $from, $to ] ) if $reads->($from) && $reads->($to);
		}
		elsif ( my ( $op, $operand ) = $text =~ /\A(<=|>=|!=|<|>|=)?\s*(.+)\z/s ) {
			return ( $op // '=', $operand ) if $reads->($operand);
		}
		my $examples = $type eq 'number' ? '5, >5, >=5, <5, <=5, !=5 or 5..10' : '2024-05-03, >2024-05, <=2024-05-03 14:30 or 2024-01..2024-03';
		die "Term::Fabulous::Widget::Table::Filter: '$text' is not a $type filter (use $examples)\n";
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Table::Filter - Conditions that decide which rows a table shows

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table::Filter;
	my $F = 'Term::Fabulous::Widget::Table::Filter';

	# Conditions on one column:
	$table->filter( adults   => $F->new( column => 'age',  op => '>=', value => 18 ) );
	$table->filter( name     => $F->new( column => 'name', op => 'contains', value => 'ann' ) );
	$table->filter( spring   => $F->new( column => 'joined', op => 'between', value => [ '2024-03', '2024-05' ] ) );
	$table->filter( shown_as => $F->new( column => 'size', op => 'starts_with', value => '1.5', on => 'display' ) );

	# Any test of your own, on a value or on the whole row:
	$table->filter( even  => $F->new( column => 'id', test => sub ( $value, $row ) { $value % 2 == 0 } ) );
	$table->filter( mine  => sub ($row) { $row->{owner} eq $ENV{USER} } );    # a code reference is a row test

	# Combinations:
	$table->filter( active => $F->any(
		$F->new( column => 'status', op => 'in', value => [ 'open', 'pending' ] ),
		$F->not( $F->new( column => 'closed', op => 'not_empty' ) ),
	) );

	# What a user types into a filter field:
	my $filter = $F->parse( '>=2024-05', column => 'joined', type => 'date' );

=head1 DESCRIPTION

A filter is a condition on a row. L<Term::Fabulous::Widget::Table>
shows the rows that match all of its filters (see
L<Term::Fabulous::Manual::TableRows/FILTERING>). Filters are immutable
objects; build one with L</new> or L</parse> and combine them with
L</all>, L</any> and L</not>. Give them to the table with
L<Term::Fabulous::Widget::Table/filter>.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-table-filter-perl.svg" alt="A table of invoices filtered to three rows by the fourth of five filters, with a line that names the active filter and counts the rows"></p>

=end html

The picture shows a table filtered by a combination of conditions; the
program is in
L<Term::Fabulous::Cookbook::TableRows/Filter rows from Perl (numbers, dates, text, raw or shown values)>.

=head2 What a condition compares

A condition on a column compares the cell of each row with an operand
(C<value>). By default it reads the cell's raw value, what the column's
C<value> option gives (the row's entry under the column key); with
C<< on => 'display' >> it reads the text the column shows instead, the
value after the column's mutators. Use C<display> to filter by what the
user sees, for example a formatted date, and C<value> to filter by what
the data says, for example the epoch seconds behind it.

How the cell and the operand are compared depends on the type: the
filter's C<type>, or else the column's C<type>:

=over

=item C<string>

Text comparison, case-insensitive (with C<fc>) unless
C<case_sensitive> is true. The comparison ops order text the way C<cmp>
does.

=item C<number>

Both sides are read as numbers (see
L<Term::Fabulous::Widget::Table::Value/number_of>). An operand that is
not a number dies when the filter is made or first used.

=item C<date>

The cell is read as a date (epoch seconds, a date string, or an object
with an C<epoch> method; see
L<Term::Fabulous::Widget::Table::Value/date_epoch>). The operand is a
span of time: a date string covers what it names (C<2024-05> is all of
May 2024, C<2024-05-03> that whole day, see
L<Term::Fabulous::Widget::Table::Value/date_interval>), epoch seconds
cover one second. A date is I<equal> to a span when it lies inside it,
I<less> when it lies before it and I<greater> when it lies after it.
So C<< op => '=', value => '2024-05-03' >> matches every time of that
day, C<< '<=' >> everything up to its end, C<< '>' >> everything from
the next day on.

=back

Cells that are blank (C<undef> or C<''>) or that cannot be read as the
type match none of the comparison ops, not even C<!=>; use C<empty> and
C<not_empty> for them. The text ops read every cell as text, blank cells
as C<''>.

=head1 CONSTRUCTORS

=head2 new

	my $filter = Term::Fabulous::Widget::Table::Filter->new(%parameters);

One of three kinds, chosen by the parameters; unknown parameters and
mixed kinds die.

A I<condition> takes C<column> and C<op>, and C<value> for every op but
C<empty> and C<not_empty>:

=over

=item C<column>

The key of the column whose cells are compared. The table checks that
the column exists when the filter is set.

=item C<op>

The text ops (they read every cell as text):

=for highlighter language=text

	contains       the text contains the value
	not_contains   it does not
	equals         the text is the value
	not_equals     it is not
	starts_with    the text starts with the value
	ends_with      the text ends with the value
	matches        the text matches a pattern: a qr// (used as it is,
	               with its own flags) or a string with a regular
	               expression (case-insensitive unless case_sensitive);
	               an invalid pattern dies

The comparison ops (they compare as the type says):

	=   ==  eq     equal
	!=  ne         not equal
	<   lt         less
	<=  le         less or equal
	>   gt         greater
	>=  ge         greater or equal
	between        from value->[0] to value->[1], both included
	in             equal to one of the values in an array reference

And for blank cells:

	empty          the cell is undef or ''
	not_empty      it is not

=item C<value>

The operand: a plain value, an array reference of two for C<between>,
of any number for C<in>, or a pattern for C<matches>. Copied.

=item C<on>

C<'value'> (the default) or C<'display'>; see L</What a condition
compares>.

=item C<type>

C<'string'>, C<'number'> or C<'date'>, or C<undef> (the default) for
the type of the column.

=item C<case_sensitive>

A boolean, default 0: whether text comparisons tell upper and lower
case apart.

=back

A I<test> takes C<test>, a code reference, and optionally C<column> and
C<on>. With a column, it is called as C<< $test->( $cell, $row ) >>
for every row, with the cell (its raw value or its display text, as
C<on> says) and a copy of the row's data; without one, as
C<< $test->($row) >>. A true return value is a match. A code reference
given to L<Term::Fabulous::Widget::Table/filter> is a row test.

The I<combinations> are made with L</all>, L</any> and L</not>.

=head2 all

=for highlighter language=perl

	my $filter = $F->all( $f1, $f2, sub ($row) { ... } );

Matches rows that match every filter given (code references are row
tests). An empty C<all> matches every row.

=head2 any

	my $filter = $F->any( $f1, $f2 );

Matches rows that match at least one of the filters. An empty C<any>
matches no row.

=head2 not

	my $filter = $F->not($f1);

Matches rows that do not match the filter.

=head2 parse

	my $filter = $F->parse( $text, column => 'age', type => 'number' );

Makes a condition from a I<filter expression>, the short notation a
user types into a filter field of a table (see
L<Term::Fabulous::Widget::Table/filter_row>). Returns C<undef> for an
empty expression (no filter) and dies for one it cannot read, with a
message that shows the notation. Options: C<column> (required),
C<type> (C<'string'>, the default, C<'number'> or C<'date'>), C<on> and
C<case_sensitive> (as for L</new>). Spaces around the expression, and
between an operator and its value, are ignored. Dates are read in local
time; a C<T> may stand for the space before the time, and a C<Z> after
the time reads it as UTC. Epoch seconds are not a date expression. The
notation:

=for highlighter language=text

	Text columns
	  ann          contains "ann"
	  !ann         does not contain "ann"
	  =Ann Lee     is "Ann Lee"
	  !=Ann Lee    is not "Ann Lee"
	  ^An          starts with "An"
	  Lee$         ends with "Lee"
	  ^Ann Lee$    is "Ann Lee"
	  /^a.*e$/     matches the regular expression

	Number columns
	  42  =42      is 42
	  !=42         is not 42
	  >42  >=42    greater (or equal)
	  <42  <=42    less (or equal)
	  10..20       from 10 to 20

	Date columns: the same as numbers, with dates
	  2024-05-03         that day
	  >=2024-05          from May 2024 on
	  <2024-05-03 14:30  before that minute
	  2024-01..2024-03   from January to the end of March 2024

	Every column
	  =            the cell is empty
	  !=           the cell is not empty

=head1 METHODS

=head2 matches

=for highlighter language=perl

	my $yes = $filter->matches( $row, $source );

True when the row matches. C<$row> is the row's data (a hash
reference); C<$source> is an object with the methods
C<< value_of( $row, $key ) >>, C<< display_of( $row, $key ) >> and
C<< type_of($key) >> - the table passes itself. You rarely call this
yourself.

=head2 check

	$filter->check($source);

Dies when the filter compares a column C<$source> does not have
(C<< $source->has_column($key) >>) or has an operand that cannot be
read as the type of its column (C<< $source->type_of($key) >>), for
example C<< op => '>', value => 'abc' >> on a number column. Returns
the filter. The table method
L<filter|Term::Fabulous::Widget::Table/filter> calls it for every
filter it is given, so a bad filter dies there and not while the table
is drawn.

The readers below return the parameters the filter was made with.

=head2 column

The key of the column the filter compares (a condition, or a test with
a column), or C<undef>.

=head2 op

The op of a condition, with aliases resolved (C<'=='> and C<'eq'> are
C<'='>, C<'ne'> is C<'!='>, ...), or C<undef> for other filters.

=head2 value

The operand of a condition (a copy when it is an array reference), or
C<undef>.

=head2 on

C<'value'> or C<'display'>.

=head2 type

C<'string'>, C<'number'> or C<'date'>, or C<undef> for the type of the
column.

=head2 case_sensitive

1 if text comparisons tell upper and lower case apart, 0 otherwise.

=head2 test

The code reference of a test, or C<undef> for other filters.

=head2 combine

C<'all'>, C<'any'> or C<'not'> for a combination, C<undef> for other
filters.

=head2 filters

The filters of a combination, as a list (empty for other filters).

=head2 columns

The keys of all columns the filter (and every filter it combines)
compares, as a list.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::Table::Value>,
L<Term::Fabulous::Manual::TableRows/FILTERING>,
L<Term::Fabulous::Cookbook::TableRows/Let the user filter rows (filter row and search box)>.

=cut
