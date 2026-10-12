use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use POSIX ();

# Before anything reads the clock: Test2 seeds srand from the local date,
# and the C library of Windows, which has no tzset, settles the time zone
# at its first localtime.
BEGIN {
	$ENV{TZ} = 'UTC';
	POSIX::tzset() unless $^O eq 'MSWin32';
}

use Test2::V0;

use Term::Fabulous::Widget::Table::Filter;

my $F = 'Term::Fabulous::Widget::Table::Filter';

# What filters read: the raw values, display texts in brackets, the types.
package Source {    ## no critic (Modules::RequireFilenameMatchesPackage) a stand-in table model
	my %type = ( name => 'string', age => 'number', joined => 'date' );
	sub new        ($class)              { return bless {}, $class }
	sub value_of   ( $self, $row, $key ) { return $row->{$key} }
	sub display_of ( $self, $row, $key ) { return defined $row->{$key} ? "<$row->{$key}>" : '' }
	sub type_of    ( $self, $key )       { return $type{$key} }
	sub has_column ( $self, $key )       { return exists $type{$key} }
}

my $source = Source->new;
my @rows   = (
	{ name => 'Ann Lee', age => 34,    joined => '2024-05-03 10:00' },
	{ name => 'bob',     age => 17,    joined => 1704067199 },    # 2023-12-31 23:59:59
	{ name => '',        age => undef, joined => undef },
	{ name => 'Cy',      age => 'n/a', joined => 'later' },
);

# Which rows match, as a string of 0 and 1.
sub matches ($filter) {
	$filter->check($source);
	return join '', map { $filter->matches( $_, $source ) } @rows;
}

subtest 'text ops' => sub {
	is matches( $F->new( column => 'name', op => 'contains', value => 'LEE' ) ),                      '1000', 'contains, case-insensitive';
	is matches( $F->new( column => 'name', op => 'contains', value => 'LEE', case_sensitive => 1 ) ), '0000', 'case-sensitive';
	is matches( $F->new( column => 'name', op => 'not_contains', value => 'b' ) ),     '1011', 'not_contains';
	is matches( $F->new( column => 'name', op => 'equals',       value => 'BOB' ) ),   '0100', 'equals';
	is matches( $F->new( column => 'name', op => 'not_equals',   value => 'bob' ) ),   '1011', 'not_equals';
	is matches( $F->new( column => 'name', op => 'starts_with',  value => 'an' ) ),    '1000', 'starts_with';
	is matches( $F->new( column => 'name', op => 'ends_with',    value => 'y' ) ),     '0001', 'ends_with';
	is matches( $F->new( column => 'name', op => 'matches',      value => '^[ab]' ) ), '1100', 'matches a string pattern';
	is matches( $F->new( column => 'name', op => 'matches',      value => qr/O/ ) ),   '0000', 'a qr// one keeps its flags';
	is matches( $F->new( column => 'name', op => 'matches',      value => qr/O/i ) ),  '0100', 'such as /i';
	is matches( $F->new( column => 'name', op => 'empty' ) ),                                       '0010', 'empty';
	is matches( $F->new( column => 'name', op => 'not_empty' ) ),                                   '1101', 'not_empty';
	is matches( $F->new( column => 'name', op => 'starts_with', value => '<a', on => 'display' ) ), '1000', 'on the display text';
};

subtest 'number ops' => sub {
	is matches( $F->new( column => 'age', op => '>=',       value => 18 ) ),         '1000', '>=';
	is matches( $F->new( column => 'age', op => '<',        value => 30 ) ),         '0100', '<';
	is matches( $F->new( column => 'age', op => '!=',       value => 34 ) ),         '0100', '!= skips blank and unreadable cells';
	is matches( $F->new( column => 'age', op => 'between',  value => [ 10, 40 ] ) ), '1100', 'between';
	is matches( $F->new( column => 'age', op => 'in',       value => [ 17, 99 ] ) ), '0100', 'in';
	is matches( $F->new( column => 'age', op => 'gt',       value => 20 ) ),         '1000', 'gt is >';
	is matches( $F->new( column => 'age', op => 'contains', value => '/' ) ),        '0001', 'text ops read numbers as text';
};

subtest 'date ops' => sub {
	is matches( $F->new( column => 'joined', op => '=',       value => '2024-05-03' ) ),             '1000', 'on a day';
	is matches( $F->new( column => 'joined', op => '<',       value => '2024' ) ),                   '0100', 'before a year';
	is matches( $F->new( column => 'joined', op => '<=',      value => '2023-12' ) ),                '0100', 'up to the end of a month';
	is matches( $F->new( column => 'joined', op => '>',       value => '2023-12-31' ) ),             '1000', 'after a day';
	is matches( $F->new( column => 'joined', op => '>=',      value => 1704067199 ) ),               '1100', 'from epoch seconds';
	is matches( $F->new( column => 'joined', op => 'between', value => [ '2023-12', '2024-04' ] ) ), '0100', 'between months';
};

subtest 'tests and combinations' => sub {
	is matches( $F->new( test   => sub ($row) { length $row->{name} == 2 } ) ),                         '0001', 'a row test';
	is matches( $F->new( column => 'age', test => sub ( $value, $row ) { ( $value // '' ) =~ /7/ } ) ), '0100', 'a cell test';
	my $young = $F->new( column => 'age', op => '<', value => 18 );
	is matches( $F->any( $young, sub ($row) { $row->{name} eq '' } ) ),              '0110',         'any';
	is matches( $F->all( $young, $F->new( column => 'name', op => 'not_empty' ) ) ), '0100',         'all';
	is matches( $F->not($young) ),                                                   '1011',         'not';
	is matches( $F->all ),                                                           '1111',         'an empty all matches everything';
	is [ $F->all( $young, $F->new( column => 'name', op => 'empty' ) )->columns ],   [qw(age name)], 'columns lists every column compared';
};

subtest 'parse' => sub {
	my $parsed = sub ( $text, $column, $type ) {
		my $filter = $F->parse( $text, column => $column, type => $type ) // return undef;
		return [ $filter->op, $filter->value ];
	};
	is $parsed->( 'ann',               name   => 'string' ), [ contains     => 'ann' ],                    'text: contains';
	is $parsed->( '!ann',              name   => 'string' ), [ not_contains => 'ann' ],                    'not';
	is $parsed->( '=Ann Lee',          name   => 'string' ), [ equals       => 'Ann Lee' ],                'equals';
	is $parsed->( '!=x',               name   => 'string' ), [ not_equals   => 'x' ],                      'not equals';
	is $parsed->( '^An',               name   => 'string' ), [ starts_with  => 'An' ],                     'starts with';
	is $parsed->( 'Lee$',              name   => 'string' ), [ ends_with    => 'Lee' ],                    'ends with';
	is $parsed->( '^Ann$',             name   => 'string' ), [ equals       => 'Ann' ],                    'anchored both ends';
	is $parsed->( '/a.e/',             name   => 'string' ), [ matches      => 'a.e' ],                    'pattern';
	is $parsed->( ' >= 18 ',           age    => 'number' ), [ '>='         => 18 ],                       'number comparison, spaces ignored';
	is $parsed->( '42',                age    => 'number' ), [ '='          => 42 ],                       'a number alone is equal';
	is $parsed->( '1.5..-2',           age    => 'number' ), [ between      => [ 1.5, -2 ] ],              'a range';
	is $parsed->( '<2024-05-03 14:30', joined => 'date' ),   [ '<'          => '2024-05-03 14:30' ],       'a date comparison';
	is $parsed->( '2024-01..2024-03',  joined => 'date' ),   [ between      => [ '2024-01', '2024-03' ] ], 'a date range';
	is $parsed->( '=',                 age    => 'number' ), [ empty        => undef ],                    'empty';
	is $parsed->( '!=',                name   => 'string' ), [ not_empty    => undef ],                    'not empty';
	is $parsed->( '   ', name => 'string' ), undef, 'blank: no filter';
	like dies { $F->parse( 'abc', column => 'age', type => 'number' ) },   qr/'abc' is not a number filter \(use 5, >5/,     'a number filter that is none';
	like dies { $F->parse( '>may', column => 'joined', type => 'date' ) }, qr/'>may' is not a date filter \(use 2024-05-03/, 'a date filter that is none';
	like dies { $F->parse( '/(/', column => 'name' ) },                    qr/invalid pattern '\('/,                         'an invalid pattern';
	like dies { $F->parse( 'x', type => 'string' ) },                      qr/parse needs a column/,                         'no column';
};

subtest 'invalid filters' => sub {
	like dies { $F->new( column => 'age', op => 'like', value => 1 ) },                  qr/unknown op 'like' \(known: !=, </,                 'unknown op';
	like dies { $F->new( op => 'contains', value => 'x' ) },                             qr/op 'contains' needs a column/,                     'no column';
	like dies { $F->new( column => 'age', op => '>' ) },                                 qr/op '>' needs a value/,                             'no value';
	like dies { $F->new( column => 'age', op => 'between', value => 3 ) },               qr/op 'between' needs \[ from, to \]/,                'between without a pair';
	like dies { $F->new( column => 'age', op => '>', value => 'x', type => 'number' ) }, qr/op '>' on a number column needs numbers, got 'x'/, 'a known type checks the value at once';
	like dies { $F->new( column => 'age', op => '>', value => 'x' )->check($source) },   qr/op '>' on a number column needs numbers, got 'x'/, 'check checks against the column type';
	like dies { $F->new( column => 'size', op => 'empty' )->check($source) },            qr/there is no column 'size'/,                        'check finds unknown columns';
	like dies {
		$F->new( column => 'age', op => '>', value => 1, test => sub { 1 } )
	}, qr/give 'op', 'test' or a combination/, 'op and test';
	like dies { $F->new( on     => 'value' ) },                           qr/a filter needs 'op'/,                         'nothing to do';
	like dies { $F->new( column => 'age', op => 'empty', on => 'raw' ) }, qr/on must be one of display, value, got 'raw'/, 'on';
	like dies { $F->any('x') }, qr/any takes Term::Fabulous::Widget::Table::Filter objects or code references, got 'x'/, 'combination of junk';
};

done_testing;
