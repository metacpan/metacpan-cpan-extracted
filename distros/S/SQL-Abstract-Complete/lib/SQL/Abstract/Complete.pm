package SQL::Abstract::Complete;
# ABSTRACT: Generate complete SQL from Perl data structures

use 5.008;
use strict;
use warnings;

use SQL::Abstract 1.5;
use Storable 'dclone';

use vars '@ISA';
@ISA = 'SQL::Abstract';

our $VERSION = '1.08'; # VERSION

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);
    $self->{'part_join'} ||= ' ';
    return $self;
}

sub _wipe_space {
    return join( '', map {
        s/\s{2,}/ /g;
        s/^\s+|\s+$//g;
        s/\s+,/,/g;
        $_;
    } @_ );
}

sub _sqlcase {
    return ( $_[0]->{'case'} ) ? $_[1] : uc( ( defined( $_[1] ) ) ? $_[1] : '' );
}

sub select {
    my ( $self, $tables, $columns, $where, $meta ) = @_;
    $columns = ['*'] unless ( $columns and @{$columns} > 0 );
    $tables  = dclone($tables) if ( ref $tables );

    my $columns_sql = $self->_sqlcase('select') . ' ' . _wipe_space(
        ( ref($columns) eq 'SCALAR' ) ? ${$columns}             :
        ( not ref($columns)         ) ? $self->_quote($columns) :
        join( ', ', map {
            ( ref($_) eq 'SCALAR' ) ? ${$_}             :
            ( not ref($_)         ) ? $self->_quote($_) :
            join( ' AS ', map { $self->_quote($_) } ( ref($_) eq 'HASH' ) ? %{$_} : @{$_} );
        } @{$columns} )
    );

    my $core_table;
    my $tables_sql = join(
        $self->{'part_join'},
        map { _wipe_space( join( ' ',
                $self->_sqlcase( shift( @{$_} ) ),
                grep { defined } @{$_} )
            ) } (
            ( ref($tables) eq 'SCALAR' ) ? [ undef, ${$tables}              ] :
            ( not ref($tables)         ) ? [ 'from', $self->_quote($tables) ] :
            map {
                ( ref($_) eq 'SCALAR' ) ? [ undef, ${$_}              ] :
                ( not ref($_)         ) ? [ 'from', $self->_quote($_) ] :
                do {
                    my @parts     = ( ref($_) eq 'HASH' )            ? %{$_}              : @{$_};
                    my $join_type = ( ref( $parts[0] ) eq 'SCALAR' ) ? ${ shift(@parts) } : 'join';

                    my $join_on =
                        ( ref( $parts[-1] ) eq 'SCALAR' )              ? ${ pop(@parts) } :
                        ( ref( $parts[-1] ) eq 'HASH' and @parts > 1 ) ? do {
                            my $join_def = pop(@parts);
                            $join_type = $join_def->{'join'} . ' join' if ( $join_def->{'join'} );

                            ( ref( $join_def->{'using'} || $join_def->{'on'} ) eq 'SCALAR' )
                                ? ${ $join_def->{'using'} || $join_def->{'on'} } :
                            ( $join_def->{'using'} )
                                ? $self->_sqlcase('using') . '(' . $join_def->{'using'} . ')' :
                            ( $join_def->{'on'} )
                                ? $self->_sqlcase('on') . ' ' . $join_def->{'on'} : '';
                        } :
                        ( not ref( $parts[-1] ) and @parts > 1 )
                            ? $self->_sqlcase('using') . '(' . $self->_quote( pop(@parts) ) . ')'
                            : '';

                    my $table_def = shift(@parts);
                    $table_def    =
                        ( not ref($table_def) )         ? $table_def    :
                        ( ref($table_def) eq 'SCALAR' ) ? ${$table_def} :
                        do {
                            $table_def     = [ %{$table_def} ] if ( ref($table_def) eq 'HASH' );
                            my $table_name = shift( @{$table_def} );

                            unless ($core_table) {
                                $core_table = $table_name;
                                $join_type  = 'from';
                            }

                            $self->_quote($table_name) . ( ( @{$table_def} ) ? ' ' . join(
                                ' ',
                                $self->_sqlcase('as'),
                                map { $self->_quote($_) } @{$table_def},
                            ) : '' );
                        };

                    [ $join_type, $table_def, $join_on ];
                };
            } ( ( ref($tables) ) ? @{$tables} : $tables )
        )
    );

    my ( $where_sql, @bind ) = $self->where($where);

    my ( $offset, $rows ) = ( $meta->{'offset'} || 0, $meta->{'rows'} || 0 );
    if ( $meta->{'limit'} ) {
        ( $offset, $rows ) = ( ref( $meta->{'limit'} ) eq 'ARRAY' )
            ? @{ $meta->{'limit'} }
            : ( 0, $meta->{'limit'} );
    }
    $offset = ( $meta->{'page'} - 1 ) * $rows if ( $meta->{'page'} );

    my $sql = join(
        $self->{'part_join'},
        grep { defined and $_ } (
            $columns_sql,
            $tables_sql,
            _wipe_space($where_sql),
            ( ( $meta->{'group_by'} ) ? do {
                (
                    my $group_by = scalar( $self->_order_by( $meta->{'group_by'} ) )
                ) =~ s/\s*ORDER BY/GROUP BY/;
                _wipe_space($group_by);
            } : undef ),
            ( ( $meta->{'having'} ) ? do {
                my ( $having, @having_bind ) = $self->where( $meta->{'having'} );
                $having =~ s/\s*WHERE/HAVING/;
                push( @bind, @having_bind ) if ( scalar(@having_bind) );
                _wipe_space($having);
            } : undef ),
            ( ( $meta->{'order_by'} ) ? _wipe_space( $self->_order_by( $meta->{'order_by'} ) ) : undef ),
            ( $offset or $rows )
                ? $self->_sqlcase('limit') . " $rows " . $self->_sqlcase('offset')  . " $offset"
                : undef,
        ),
    );

    $sql =~ s/^\s+|\s+$//g;
    return ( wantarray() ) ? ( $sql, @bind ) : $sql;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Abstract::Complete - Generate complete SQL from Perl data structures

=head1 VERSION

version 1.08

=for markdown [![test](https://github.com/gryphonshafer/SQL-Abstract-Complete/workflows/test/badge.svg)](https://github.com/gryphonshafer/SQL-Abstract-Complete/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/SQL-Abstract-Complete/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/SQL-Abstract-Complete)

=for test_synopsis my( $sql, @bind, @tables, @fields, %where, %other );

=head1 SYNOPSIS

    use SQL::Abstract::Complete;

    my $sac = SQL::Abstract::Complete->new;

    my ( $sql, @bind ) = $sac->select(
        \@tables, # a table or set of tables and optional aliases
        \@fields, # fields and optional aliases to fetch
        \%where,  # where clause
        \%other,  # order by, group by, having, and pagination
    );

=head1 DESCRIPTION

This module was inspired by the excellent L<SQL::Abstract>, from which in
inherits. However, in trying to use the module, I found that what I really
wanted to do was generate complete SELECT statements including joins and group
by clauses. So, I set out to create a more complete abstract SQL generation
module. (To be fair, L<SQL::Abstract> kept it's first C<$table> argument
inflexible for backwards compatibility reasons.)

This module only changes the select() method and adds a small new wrinkle to
new(). Everything else from L<SQL::Abstract> is inheritted as-is. Consequently,
you should read the L<SQL::Abstract> documentation before continuing.

=head1 FUNCTIONS

=head2 new( 'option' => 'value' )

The C<new()> function takes a list of options and values, and returns
a new B<SQL::Abstract::Complete> object which can then be used to generate SQL.
This function operates in exactly the same way as the same from L<SQL::Abstract>
only it offers one additional option to set:

=over

=item part_join

This is the value that the SELECT statement components will be concatinated
together with. By default, this is set to a single space, meaning the returned
SQL will be all on one line. Setting this to something like C<"\n"> would make
for slightly more human-readable SQL, depending on the human.

=back

=head2 select( \@tables, \@fields, \%where, \%other )

This returns a SQL SELECT statement and associated list of bind values, as
specified by the arguments:

=over

=item \@tables

This is a list of tables, optional aliases, and ways to join any multiple
tables. The first table will be used as the "FROM" part of the statement.
Subsequent tables will be assumed to be joined by use of an inner join unless
otherwise specified.

There are several ways to specify tables, joins, and their respective aliases:

    # SELECT * FROM alpha
    my ( $sql, @bind ) = $sac->select('alpha');
    my ( $sql, @bind ) = $sac->select( ['alpha'] );

    # SELECT * FROM alpha AS a
    ( $sql, @bind ) = $sac->select( \q(FROM alpha AS a) );
    ( $sql, @bind ) = $sac->select( [ \q(FROM alpha AS a) ] );

    # SELECT * FROM alpha AS a JOIN beta AS b USING(id)
    $sac->select(
        [
            [ [ qw( alpha a ) ]       ],
            [ [ qw( beta  b ) ], 'id' ],
        ],
    );
    $sac->select(
        [
            [ [ qw( alpha a ) ] ],
            [ { 'beta' => 'b' }, 'id' ],
        ],
    );

    # SELECT *
    # FROM alpha AS a
    # JOIN beta AS b USING(id)
    # LEFT JOIN something AS s USING(whatever)
    # LEFT JOIN omega AS o USING(last_id)
    # LEFT JOIN stuff AS t ON t.thing_id = b.thing_id
    # LEFT JOIN pi AS p USING(number_id)
    $sac->select(
        [
            [ [ qw( alpha a ) ] ],
            [ { 'beta' => 'b' }, 'id' ],
            \q{ LEFT JOIN something AS s USING(whatever) },
            [ \q{ LEFT JOIN }, { 'omega', 'o' }, 'last_id' ],
            [
                \q{ LEFT JOIN },
                { 'stuff' => 't' },
                \q{ ON t.thing_id = b.thing_id },
            ],
            [
                [ qw( pi p ) ],
                {
                    'join'  => 'left',
                    'using' => 'number_id',
                },
            ],
        ],
    );

=item \@fields

This is a list of the fields (along with optional aliases) to return.
There are several ways to specify fields and their respective aliases:

    # SELECT one, two, three FROM table
    $sac->select(
        'table',
        [ qw( one two three ) ],
    );

    # SELECT one, IF( two > 10, 1, 0 ) AS two_bool, three AS col_three
    # FROM table
    $sac->select(
        'table',
        [
            'one',
            \q{ IF( two > 10, 1, 0 ) AS two_bool },
            { 'three' => 'col_three' },
        ],
    );

=item \%where

This is an optional argument to specify the WHERE clause of the query.
The argument is most often a hashref. This functionality is entirely
inheritted from L<SQL::Abstract>, so read that fine module's documentation
for WHERE details.

=item \%other

This optional argument is where you can specify items like order by, group by,
and having clauses. You can also stipulate pagination of results.

    # SELECT one
    # FROM table
    # GROUP BY two
    # HAVING ( MAX(three) > ? )
    # ORDER BY one, four DESC, five
    # LIMIT 10, 5
    $sac->select(
        'table',
        ['one'],
        undef,
        {
            'group_by' => 'two',
            'having'   => [ { 'MAX(three)' => { '>' => 9 } } ],
            'order_by' => [ 'one', { '-desc' => 'four' }, 'five' ],
            'rows'     => 5,
            'page'     => 3,
        },
    );

The HAVING clause works in the same way as the WHERE clause handling
from L<SQL::Abstract>. (In fact, we're actually calling the same method
from the parent class.) ORDER BY clause handling is also purely inheritted
from L<SQL::Abstract>. The "rows" and "page" pagination functionality is
inspired from L<DBIx::Class> and operates the same way. Alternatively, you can
explicitly set a "limit" value.

=back

=head1 SEE ALSO

L<SQL::Abstract>, L<DBIx::Class>, L<DBIx::Abstract>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/SQL-Abstract-Complete>

=item *

L<MetaCPAN|https://metacpan.org/pod/SQL::Abstract::Complete>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/SQL-Abstract-Complete/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/SQL-Abstract-Complete>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/SQL-Abstract-Complete>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/S/SQL-Abstract-Complete.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
