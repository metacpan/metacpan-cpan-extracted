use 5.006;
use strict;
use warnings;

package SQL::Concrete;
$SQL::Concrete::VERSION = '1.003';
# ABSTRACT: render SQL from fragments and placeholders from data structures

use Exporter::Tidy
	core    => [ qw( sql_render ) ],
	util    => [ qw( sql ) ],
	clauses => [ qw( sql_values sql_set sql_select ) ],
	CLAUSES => [ qw( VALUES SET SELECT ) ],
	all     => [ qw( :core :util :CLAUSES ) ],
	_map    => { VALUES => 'sql_values', SET => 'sql_set', SELECT => 'sql_select' },
	noncore => [ qw( :util :clauses :CLAUSES ) ]; # used internally by SQL::Concrete::Dollars

sub sql_render { SQL::Concrete::Renderer->new->render( @_ ) }
sub sql        { my @stuff = @_; bless sub { $_[0]->render_sql( @stuff ) }, __PACKAGE__ }
sub sql_set    { my @stuff = @_; bless sub { $_[0]->render_set( @stuff ) }, __PACKAGE__ }
sub sql_values { my @stuff = @_; bless sub { $_[0]->render_values( @stuff ) }, __PACKAGE__ }
sub sql_select { my @stuff = @_; bless sub { $_[0]->render_select( @stuff ) }, __PACKAGE__ }

package SQL::Concrete::Renderer;
$SQL::Concrete::Renderer::VERSION = '1.003';
use Object::Tiny::Lvalue qw( alias_id prev_item bind );

# our code references are blessed into this package
# so that we can distinguish them from other code references
sub _CODE_() { 'SQL::Concrete' }

sub new { my $class = shift; bless { @_ }, $class }

sub render {
	my $self = shift;
	local $self->{'bind'} = [];
	local $self->{'alias_id'} = 0;
	my $sql = $self->render_sql( @_ );
	return ( $sql, @{ $self->bind } );
}

sub render_sql {
	my $self = shift;

	my $sql = '';
	my $bind = $self->bind;
	local $self->{'prev_item'};

	for my $item ( @_ ) {
		my $type = ref $item;

		my $append
			= ( not $type )         ? $self->prev_item = $item
			: ( 'SCALAR' eq $type ) ? $self->render_bind( $$item )
			: ( 'ARRAY'  eq $type ) ? ( @$item ? join ', ', $self->bind_or_render_values( @$item ) : $self->error( 'empty array' ) )
			: ( _CODE_   eq $type ) ? $item->( $self )
			: ( 'HASH'   eq $type ) ? ( keys %$item ? undef : '1=1' ) # further handled below
			: $self->error( "unrecognized $type value in interpolation" );

		if ( not defined $append ) { # 'twas a non-empty hash
			$append = join ' AND ', map {
				my $lft = $_;
				my $rgt = $item->{ $lft };
				my $type = ref $rgt;
				my $term
					= ( not defined $rgt )  ? $lft . ' IS NULL'
					: ( not $type )         ? join( '=', $lft, $self->bind_or_render_values( $rgt ) )
					: ( _CODE_  eq $type )  ? $lft . '=' . $rgt->( $self )
					: ( 'ARRAY' eq $type )  ? do {
						my $list = @$rgt && join ', ', $self->bind_or_render_values( @$rgt );
						@$rgt ? "$lft IN ($list)" : '1 IN (0)';
					}
					: $self->error( "unrecognized $type value for key '$lft' in hash" );
				$term;
			} sort keys %$item;
			$append = "($append)" if keys %$item > 1;
		}

		$sql .= '1 IN (1)', next if '1 IN (0)' eq $append and $sql =~ s/\bNOT\s*\z//i;
		$sql .= ' ' if $sql =~ /\S/ and $append !~ /\A\s/ and $sql !~ /=\z/;
		$sql .= $append;
	}

	return $sql;
}

sub bind_or_render_values {
	my $self = shift;
	map {
		my $type = ref;
		$self->error( "unrecognized $type value in aggregate" ) if $type and _CODE_ ne $type;
		$type ? $_->( $self ) : $self->render_bind( $_ );
	} @_;
}

sub render_bind { push @{ $_[0]{'bind'} }, $_[1]; '?' }

sub render_set {
	my $self = shift;
	$self->error( 'empty SET' ) if not @_;
	my %h = @_;
	my @k = sort keys %h;
	my @v = $self->bind_or_render_values( @h{ @k } );
	my $list = join ', ', map { "$k[$_]=$v[$_]" } 0 .. $#k;
	"SET $list";
}

sub render_values {
	my $self = shift;
	my ( $item ) = @_;
	my $type = ref $item;
	my $columns = '';
	my @value
		= 'ARRAY'  eq $type ? $self->bind_or_render_values( @$item )
		: 'HASH'   eq $type ? do {
			my @key = sort keys %$item;
			$columns = join ', ', @key;
			$columns = "($columns) ";
			$self->bind_or_render_values( @$item{ @key } );
		}
		: $self->error( "unrecognized $type value in VALUES" );
	my $list = join ', ', @value;
	"${columns}VALUES($list)";
}

sub render_select {
	my $self = shift;
	my @alias = ref $_[0] ? () : shift @_;

	$self->error( 'empty SELECT' ) if not @_;

	my $row0  = shift @_;
	my $type0 = ref $row0;

	my @select;

	if ( 'ARRAY' eq $type0 ) {
		$self->error( 'empty first row in SELECT' ) if not @$row0; # improve?
		@select = map { join ', ', $self->bind_or_render_values( @$_ ) } $row0, @_;
	}
	elsif ( 'HASH' eq $type0 ) {
		$self->error( 'empty first row in SELECT' ) if not keys %$row0; # improve?
		my @k = sort keys %$row0;
		my @v = $self->bind_or_render_values( @$row0{ @k } );
		@select = (
			( join ', ', map { "$v[$_] AS $k[$_]" } 0 .. $#k ),
			map { join ', ', $self->bind_or_render_values( @$_{ @k } ) } @_,
		);
	}
	else { $self->error( "unrecognized first row '$row0' in SELECT" ) }

	my $sql = join ' UNION ALL ', map "SELECT $_", @select;
	$sql = "($sql)";

	if ( @alias ) {
		$sql .= ' AS ';
		$sql .= defined $alias[0] ? $alias[0] : 'tbl'.$self->alias_id++;
	}

	$sql;
}

sub error {
	my $self = shift;
	my $prev = $self->prev_item;
	push @_, " (somewhere past '$prev')" if defined $prev;
	require Carp;
	local $Carp::Internal{ (_CODE_) } = 1;
	local $Carp::Internal{ (__PACKAGE__) } = 1;
	Carp::croak( 'SQL::Concrete: ', @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Concrete - render SQL from fragments and placeholders from data structures

=head1 VERSION

version 1.003

=head1 SYNOPSIS

 use SQL::Concrete ':all';

 my ( $sql, @bind ) = sql_render 'INSERT INTO table', VALUES \%item;

 my ( $sql, @bind ) = sql_render 'UPDATE table', SET( %item ), 'WHERE y <>', \2;

 # same thing:
 my ( $sql, @bind ) = sql_render 'DELETE FROM table WHERE x =', \$x, 'AND y IN', \@y;
 my ( $sql, @bind ) = sql_render 'DELETE FROM table WHERE', { x => $x, y => \@y };

=head1 DESCRIPTION

This module converts SQL fragments interleaved with variable references and
some keywords into one regular SQL string along with a list of bind values,
suitable for passing to L<DBI>.

It is an antithesis of sorts to L<SQL::Abstract>: you are expected to write
most of any query as regular SQL. The job of this module is to manage your
placeholders for you rather than hide the SQL, and it can infer them from data
structures you usually already have. Without it, passing the data from such
data structures to L<DBI> manually would mean laboriously destructuring them
into a plain list of bind values, then carefully ensuring the correspondence
of placeholders with the order of bind values every time you modify the query.

This module does do I<some> SQL generation, but it makes no attempt to invent
conventions to express all possible SQL constructs. The aim is only to make
common obvious cases easier to read and write. For anything beyond that you
are expected to fall back to verbatim SQL.

This makes database code easier to read as well as easier to write, while
easily providing ready access to all SQL features, even without SQL::Concrete
having to have specific support for almost any of them.

=over 2

=item SQL, unparametrized:

 name LIKE "%son" AND (age >= 10 AND age <= 20)

=item DBI with placeholders:

 'name LIKE ? AND (age >= ? AND age <= ?)', '%son', 10, 20

=item SQL::Abstract, trying to express it all:

 { name => { like => '%son' }, age => [ -and => { '>=', 10 }, { '<=', 20 } ] }

=item SQL::Concrete, lacking syntactic shortcuts for this task:

 'name LIKE', \'%son', 'AND (age >=', \10, 'AND', 'age <=', \20, ')'

=back

=head1 INTERFACE

The recommended way to use SQL::Concrete is via L<DBIx::Simple>, which provides
an excellent alternative to plain DBI access:

 use DBIx::Simple::Concrete;
 # ...
 my $rows = $db->cquery( '
     SELECT title
     FROM threads
     WHERE date >', \$date, '
     AND', { subject => \@subjects }, '
 ' )->arrays;

The C<cquery> method (provided by L<DBIx::Simple::Concrete>) integrates
L</sql_render> directly into L<DBIx::Simple>.

=head2 C<sql_render>

This function converts its arguments into SQL constructs, joins them together
with whitespace as necessary, and returns a single query with placeholders,
plus a corresponding list of bind values.

It converts arguments according to their type as follows:

=over 4

=item B<plain scalar>

A verbatim SQL fragment.

 ()  'SELECT *', 'FROM', 'mytable'
 ->  'SELECT * FROM mytable'

=item B<scalar reference>

A single placeholder with a corresponding bind value:

 ()  'x=', \10
 ->  'x=?', 10

=item B<array reference>

A comma-separated list of placeholders and a corresponding list of bind values.

 ()  [1, 2, 3, 4]
 ->  '?, ?, ?, ?', 1, 2, 3, 4

=item B<hash reference>

A conditional expression in which each key specifies the left-hand side of
a term, its value specifies the right-hand side, and the type of the value
specifies the SQL operator, as follows:

=over 4

=item B<plain, defined scalar>

A simple C<=> comparison plus a single bind value:

 ()  { foo => 1 }
 ->  'foo = ?', 1

=item B<array reference>

An C<IN> test with a list of bind values:

 ()  { foo => [1, 2, 3] }
 ->  'foo IN (?, ?, ?)', 1, 2, 3

=item B<undefined value>

An C<IS NULL> test:

 ()  { foo => undef }
 ->  'foo IS NULL'

=back

Multiple terms are combined using C<AND> and surrounded with parentheses:

 ()  { foo => 1, quux => [2, 3] }
 ->  '(foo = ? AND quux IN (?, ?))', 1, 2, 3

=back

=head2 C<SET>

This function takes pairs of column names and values and converts them to
a C<SET> clause for an C<UPDATE> statement:

 ()  'UPDATE article', SET( body => 'hi', user => 3 ), 'WHERE', { id => 7 }
 ->  'UPDATE article SET body=?, user=? WHERE id=?', 'hi', 3, 7

=head2 C<VALUES>

This function takes a reference to either a hash or an array and converts it to
a C<VALUES> clause for an C<INSERT> statement:

 ()  'INSERT INTO article', VALUES({ body => 'hi', user => 3 })
 ->  'INSERT INTO article (body, user) VALUES(?, ?)', 'hi', 3

=head2 C<SELECT>

This function takes a list of references to either all hashes or all arrays and
converts it to a C<UNION> of C<SELECT> clauses that can be used as an inline
table reference:

 ()  SELECT [1, 2], [3, 4]
 ->  '(SELECT ?, ? UNION ALL SELECT ?, ?)', 1, 2, 3, 4

 ()  SELECT { a => 1, b => 2 }, { b => 4, a => 3 }
 ->  '(SELECT ? AS a, ? AS b UNION ALL SELECT ?, ?)', 1, 2, 3, 4

It optionally accepts a name for the table reference as its first argument:

 ()  SELECT nonsense => [1, 2, 3, 4]
 ->  '(SELECT ?, ?, ?, ?) AS nonsense', 1, 2, 3, 4

You can pass an undefined value to ask it to autogenerate a name this will be
unique to this query:

 ()  SELECT undef, [1, 2, 3, 4]
 ->  '(SELECT ?, ?, ?, ?) AS tbl0', 1, 2, 3, 4

=head2 C<sql>

This function lets you inject verbatim SQL fragments into your SQL instead of
placeholders. It takes the same arguments as L</sql_render> but returns one
single scalar value that you can use in place of any normal scalar that would
otherwise become a bind value:

 ()  'UPDATE article', SET( body => 'hi', user => 3, updated => sql('NOW()') )
 ->  'UPDATE article SET body=?, updated=NOW(), user=?', 'hi', 3

=head1 EXPORTS

The following export tags are available:

=over 4

=item C<:core>

Exports C<sql_render>.

=item C<:util>

Exports C<sql>.

=item C<:clauses>

Exports C<sql_set>, C<sql_values>, and C<sql_select>, which are aliases for
C<SET>, C<VALUES>, and C<SELECT>, respectively.

=item C<:CLAUSES>

Exports C<VALUES>, C<SET>, and C<SELECT>.

=item C<:all>

Exports everything from the C<:core>, C<:util>, and C<:CLAUSES> tags.

=back

Naturally you can also export any of these functions individually.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
