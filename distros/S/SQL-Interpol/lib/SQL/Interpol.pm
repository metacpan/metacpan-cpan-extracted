use 5.006;
use strict;
use warnings;

package SQL::Interpol;
$SQL::Interpol::VERSION = '1.103';
# ABSTRACT: interpolate Perl variables into SQL statements

use Exporter::Tidy all => [ qw( sql_interp sql ) ];

sub sql { bless [ @_ ], __PACKAGE__ }

sub sql_interp {
    my $p = SQL::Interpol::Parser->new;
    my $sql = $p->parse( @_ );
    my $bind = $p->bind;
    return ( $sql, @$bind );
}


package SQL::Interpol::Parser;
$SQL::Interpol::Parser::VERSION = '1.103';
use Object::Tiny::Lvalue qw( alias_id bind );

use Carp ();

my $IDENT = '[a-zA-Z_][a-zA-Z0-9_\$\.]*';
use constant VALID => { ARRAY => 1, SCALAR => 1, 'SQL::Interpol' => 1, '' => 1 };

sub _error { Carp::croak 'SQL::Interpol error: ', @_ }

sub new {
    my $class = shift;
    $class->SUPER::new( alias_id => 0, bind => [] );
}

sub parse {
    my $self = shift;

    my $sql = '';
    my $bind = $self->bind;

    my ( $item, $prev );
    my $error = sub {
        my $where = defined $prev ? " following '$prev'" : '';
        _error "Unrecognized element '$item'$where";
    };

    while ( @_ ) {
        $item = shift @_;
        my $type = ref $item;
        my $append;

        if ( 'SQL::Interpol' eq $type ) {
            unshift @_, @$item;
            next;
        }

        if ( not $type ) {
            $prev = $append = $item;
        }
        elsif ( $sql =~ s/(\s*$IDENT\s+(NOT\s+)?IN)\s*$//oi ) {
            my @value
                = 'SCALAR' eq $type ? $$item
                : 'ARRAY'  eq $type ? @$item
                : 'REF'    eq $type && 'ARRAY' eq ref $$item ? @$$item
                : $error->();
            my $list = @value && join ', ', $self->bind_or_parse_values( @value );
            $append = @value ? "$1 ($list)" : $2 ? '1=1' : '1=0';
        }
        elsif ( $sql =~ /\b(REPLACE|INSERT)[\w\s]*\sINTO\s*$IDENT\s*$/oi ) {
            my @value
                = 'SCALAR' eq $type ? $$item
                : 'ARRAY'  eq $type ? @$item
                : 'HASH'   eq $type ? do {
                    my @key = sort keys %$item;
                    my $list = join ', ', @key;
                    $append = "($list) ";
                    @$item{ @key };
                }
                : $error->();
            my $list = @value ? join ', ', $self->bind_or_parse_values( @value ) : '';
            $append .= "VALUES($list)";
        }
        elsif ( 'SCALAR' eq $type ) {
            push @$bind, $$item;
            $append = '?';
        }
        elsif ( 'HASH' eq $type ) {  # e.g. WHERE {x = 3, y = 4}
            if ( $sql =~ /\b(?:ON\s+DUPLICATE\s+KEY\s+UPDATE|SET)\s*$/i ) {
                _error 'Hash has zero elements.' if not keys %$item;
                my @k = sort keys %$item;
                my @v = $self->bind_or_parse_values( @$item{ @k } );
                $append = join ', ', map "$k[$_]=$v[$_]", 0 .. $#k;
            }
            elsif ( not keys %$item ) {
                $append = '1=1';
            }
            else {
                my $cond = join ' AND ', map {
                    my $expr = $_;
                    my $eval = $item->{ $expr };
                    ( not defined $eval )  ? "$expr IS NULL"
                    : 'ARRAY' ne ref $eval ? map { "$expr=$_" } $self->bind_or_parse_values( $eval )
                    : do {
                        @$eval ? do {
                            my $list = join ', ', $self->bind_or_parse_values( @$eval );
                            "$expr IN ($list)";
                        } : '1=0';
                    }
                } sort keys %$item;
                $cond = "($cond)" if keys %$item > 1;
                $append = $cond;
            }
        }
        elsif ( 'ARRAY' eq $type ) {  # result set
            _error 'table reference has zero rows' if not @$item; # improve?

            # e.g. [[1,2],[3,4]] or [{a=>1,b=>2},{a=>3,b=>4}].
            my $do_alias = $sql =~ /(?:\bFROM|JOIN)\s*$/i && ( $_[0] || '' ) !~ /\s*AS\b/i;

            my $row0  = $item->[0];
            my $type0 = ref $row0;

            if ( 'ARRAY' eq $type0 ) {
                _error 'table reference has zero columns' if not @$row0; # improve?
                $append = join ' UNION ALL ', map {
                    'SELECT ' . join ', ', $self->bind_or_parse_values( @$_ );
                } @$item;
            }
            elsif ( 'HASH' eq $type0 ) {
                _error 'table reference has zero columns' if not keys %$row0; # improve?
                my @k = sort keys %$row0;
                $append = join ' UNION ALL ', do {
                    my @v = $self->bind_or_parse_values( @$row0{ @k } );
                    'SELECT ' . join ', ', map "$v[$_] AS $k[$_]", 0 .. $#k;
                }, map {
                    'SELECT ' . join ', ', $self->bind_or_parse_values( @$_{ @k } );
                } @$item[ 1 .. $#$item ];
            }
            else { $error->() }

            $append  = "($append)";
            $append .= ' AS tbl' . $self->alias_id++ if $do_alias;
        }
        else { $error->() }

        next if not defined $append;
        $sql .= ' ' if $sql =~ /\S/ and $append !~ /\A\s/;
        $sql .= $append;
    }

    return $sql;
}

# interpolate values from aggregate variable (hashref or arrayref)
sub bind_or_parse_values {
    my $self = shift;
    map {
        my $type = ref;
        _error "unrecognized $type value in aggregate" unless VALID->{ $type };
        $type ? $self->parse( $_ ) : ( '?', push @{ $self->bind }, $_ )[0];
    } @_;
}

undef *VALID;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Interpol - interpolate Perl variables into SQL statements

=head1 VERSION

version 1.103

=head1 SYNOPSIS

  use SQL::Interpol ':all';

  my ($sql, @bind) = sql_interp 'INSERT INTO table', \%item;
  my ($sql, @bind) = sql_interp 'UPDATE table SET',  \%item, 'WHERE y <> ', \2;
  my ($sql, @bind) = sql_interp 'DELETE FROM table WHERE y = ', \2;

  # These two select syntax produce the same result
  my ($sql, @bind) = sql_interp 'SELECT * FROM table WHERE x = ', \$s, 'AND y IN', \@v;
  my ($sql, @bind) = sql_interp 'SELECT * FROM table WHERE', {x => $s, y => \@v};

=head1 DESCRIPTION

This module converts SQL fragments interleaved with variable references into
one regular SQL string along with a list of bind values, suitable for passing
to DBI. This makes database code easier to read as well as easier to write,
while easily providing ready access to all SQL features.

SQL::Interpol is a drop-in replacement for most of L<SQL::Interp>.
(Some features have been removed; please refer to the changelog.)

=head1 INTERFACE

The recommended way to use SQL::Interpol is via its L<DBIx::Simple> integration,
which provides an excellent alternative to plain DBI access:

  use DBIx::Simple::Interpol;
  # ...
  my $rows = $db->iquery( '
      SELECT title
      FROM threads
      WHERE date >', \$x, '
      AND subject IN', \@subjects, '
  ' )->arrays;

The C<iquery> method integrates L</sql_interp> directly into L<DBIx::Simple>.
Note that this requires loading L<DBIx::Simple::Interpol> instead of (or after)
L<DBIx::Simple>, as its native integration will use L<SQL::Interp> otherwise.

=head2 C<sql_interp>

  ($sql, @bind) = sql_interp @params;

This function rearranges the list of elements it is passed, returning it as an
SQL string with placeholders plus a corresponding list of bind values, suitable
for passing to DBI.

The interpolation list can contain elements of these types:

=over 4

=item B<SQL>

A plain string containing an SQL fragment such as C<SELECT * FROM mytable WHERE>.

=item B<Variable reference>

A scalarref, arrayref, or hashref referring to data to interpolate between the SQL.

=item B<Another interpolation list>

An interpolation list can be nested inside another interpolation list.
This is possible with the L</sql> function.

=back

=head3 Interpolation Examples

The following variable names will be used in the below examples:

 $sref  = \3;                      # scalarref
 $aref  = [1, 2];                  # arrayref
 $href  = {m => 1, n => undef};    # hashref
 $hv = {v => $v, s => $$s};        # hashref containing arrayref
 $vv = [$v, $v];                   # arrayref of arrayref
 $vh = [$h, $h];                   # arrayref of hashref

Let C<$x> stand for any of these.

=head3 Default scalarref behavior

A scalarref becomes a single bind value:

  IN:  'foo', $sref, 'bar'
  OUT: 'foo ? bar', $$sref

=head3 Default hashref behavior

A hashref becomes a logical C<AND>:

  IN:  'WHERE', $href
  OUT: 'WHERE (m=? AND n IS NULL)', $h->{m},

  IN:  'WHERE', $hv
  OUT: 'WHERE (v IN (?, ?) AND s = ?)', @$v, $$s

=head3 Default arrayref of (hashref or arrayref) behavior

I<This is not commonly used.>

  IN:  $vv
  OUT: '(SELECT ?, ? UNION ALL SELECT ?, ?)',
          map {@$_} @$v

  IN:  $vh
  OUT: '(SELECT ? as m, ? as n UNION ALL
            SELECT ?, ?)',
          $vh->[0]->{m}, $vh->[0]->{n},
          $vh->[1]->{m}, $vh->[1]->{n}

  # Typical usage:
  IN: $x
  IN: $x, 'UNION [ALL|DISTINCT]', $x
  IN: 'INSERT INTO mytable', $x
  IN: 'SELECT * FROM mytable WHERE x IN', $x

=head3 Context ('IN', $x)

A scalarref or arrayref can used to form an C<IN> clause. As a convenience,
a reference to an arrayref is also accepted. This way, you can simply provide
a reference to a value which may be a single-valued scalar or a multi-valued
arrayref:

  IN:  'WHERE x IN', $aref
  OUT: 'WHERE x IN (?, ?)', @$aref

  IN:  'WHERE x IN', $sref
  OUT: 'WHERE x IN (?)', $$sref

  IN:  'WHERE x IN', []
  OUT: 'WHERE 1=0'

  IN:  'WHERE x NOT IN', []
  OUT: 'WHERE 1=1'

=head3 Context ('INSERT INTO tablename', $x)

  IN:  'INSERT INTO mytable', $href
  OUT: 'INSERT INTO mytable (m, n) VALUES(?, ?)', $href->{m}, $href->{n}

  IN:  'INSERT INTO mytable', $aref
  OUT: 'INSERT INTO mytable VALUES(?, ?)', @$aref;

  IN:  'INSERT INTO mytable', $sref
  OUT: 'INSERT INTO mytable VALUES(?)', $$sref;

MySQL's C<REPLACE INTO> is supported the same way.

=head3 Context ('SET', $x)

  IN:  'UPDATE mytable SET', $href
  OUT: 'UPDATE mytable SET m = ?, n = ?', $href->{m}, $href->{n}

MySQL's C<ON DUPLICATE KEY UPDATE> is supported the same way.

=head3 Context ('FROM | JOIN', $x)

I<This is not commonly used.>

  IN:  'SELECT * FROM', $vv
  OUT: 'SELECT * FROM
       (SELECT ?, ? UNION ALL SELECT ?, ?) as t001',
       map {@$_} @$v

  IN:  'SELECT * FROM', $vh
  OUT: 'SELECT * FROM
       (SELECT ? as m, ? as n UNION ALL SELECT ?, ?) as temp001',
       $vh->[0]->{m}, $vh->[0]->{n},
       $vh->[1]->{m}, $vh->[1]->{n}

  IN:  'SELECT * FROM', $vv, 'AS t'
  OUT: 'SELECT * FROM
       (SELECT ?, ? UNION ALL SELECT ?, ?) AS t',
       map {@$_} @$v

  # Example usage (where $x and $y are table references):
  'SELECT * FROM', $x, 'JOIN', $y

=head3 Other Rules

Whitespace is automatically added between parameters:

 IN:  'UPDATE', 'mytable SET', {x => 2}, 'WHERE y IN', \@colors;
 OUT: 'UPDATE mytable SET x = ? WHERE y in (?, ?)', 2, @colors

Variables must be passed as references; otherwise, they will
processed as SQL fragments and interpolated verbatim into the
result SQL string, negating the security and performance benefits
of binding values.

In contrast, any scalar values I<inside> an arrayref or hashref are by
default treated as binding variables, not SQL.  The contained
elements may be also be L</sql>.

=head2 C<sql>

  sql_interp 'INSERT INTO mytable',
      {x => $x, y => sql('CURRENT_TIMESTAMP')};
  # OUT: 'INSERT INTO mytable (x, y) VALUES(?, CURRENT_TIMESTAMP)', $x

This function is useful if you want to use raw SQL as the value in an arrayref or hashref.

=head1 PHILOSOPHY

B<The query language is SQL.> There are other modules, such as
L<SQL::Abstract>, that hide SQL behind method calls and/or Perl
data structures (hashes and arrays). The former may be undesirable in some
cases since it replaces one language with another and hides the full
capabilities and expressiveness of your database's native SQL language. The
latter may load too much meaning into the syntax of C<{}>, C<[]> and C<\>, thereby
rendering the meaning less clear:

  SQL::Abstract example:
  %where = (lname => {like => '%son'},
            age   => {'>=', 10, '<=', 20})
  Plain SQL:
  "lname LIKE '%son' AND (age >= 10 AND age <= 20)"

In contrast, SQL::Interpol does not abstract away your SQL but rather makes it
easier to interpolate Perl variables into it. Now, SQL::Interpol I<does> overload
some meaning into C<{}>, C<[]> and C<\>, but the aim is to make common obvious
cases easier to read and write E<mdash> and leave the rest to raw SQL.

This also means SQL::Interpol does not need to support every last feature of each
particular dialect of SQL: if you need one of these, just use plain SQL.

=head1 LIMITATIONS

Some types of interpolation are context-sensitive and involve examination of
your SQL fragments. The examination could fail on obscure syntax, but it is
generally robust. Look at the examples to see the types of interpolation that
are accepted. If needed, you can disable context sensitivity by inserting a
null-string before a variable.

 "SET", "", \$x

A few things are just not possible with the C<'WHERE', \%hashref>
syntax, so in such case, use a more direct syntax:

  # ok--direct syntax
  sql_interp '...WHERE', {x => $x, y => $y}, 'AND y = z';
  # bad--trying to impose a hashref but keys must be scalars and be unique
  sql_interp '...WHERE',
      {sql($x) => sql('x'), y => $y, y => sql('z')};

In the cases where this module parses or generates SQL fragments, this module
should work for many databases, but is known to work well on MySQL and
PostgreSQL.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

Documentation by David Manura and Mark Stosberg.

=head1 COPYRIGHT AND LICENSE

This documentation is
copyright (c) 2003E<ndash>2005 by David Manura
and
copyright (c) 2006E<ndash>2012 by Mark Stosberg.

This software is copyright (c) 2014 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
