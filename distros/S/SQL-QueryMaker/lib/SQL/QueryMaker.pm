package SQL::QueryMaker;
use 5.008_001;
use strict;
use warnings;
use utf8;
use Carp ();
use Exporter qw(import);
use Scalar::Util qw(blessed);

our $VERSION = '0.03';

our @EXPORT = qw(sql_op sql_raw);

{
    no strict "refs";

    for (qw(and or)) {
        my $fn = "sql_$_";
        my $op = uc $_;

        *{__PACKAGE__ . "::$fn"} = sub {
            # fetch args
            my $args = pop;
            my $column = shift;
            if (ref $args eq 'HASH') {
                Carp::croak("cannot specify the column name as another argument when the conditions are listed using hashref")
                    if defined $column;
                my @conds;
                for my $column (keys %$args) {
                    my $value = $args->{$column};
                    if (blessed($value) && $value->can('bind_column')) {
                        $value->bind_column($column);
                    } else {
                        $value = sql_eq($column, $value);
                    }
                    push @conds, $value;
                }
                $args = \@conds;
            } else {
                Carp::croak("arguments to `$op` must be contained in an arrayref or a hashref")
                    if ref $args ne 'ARRAY';
            }
            # build and return the compiler
            return SQL::QueryMaker->_new($column, sub {
                my ($column, $quote_cb) = @_;
                return $op eq 'AND' ? '0=1' : '1=1'
                    if @$args == 0;
                my @term;
                for my $arg (@$args) {
                    if (blessed($arg) && $arg->can('as_sql')) {
                        my ($term, $bind) = $arg->as_sql($column, $quote_cb);
                        push @term, "($term)";
                    } else {
                        Carp::croak("no column binding for $fn")
                            unless defined $column;
                        push @term, '(' . $quote_cb->($column) . ' = ?)';
                    }
                }
                my $term = join " $op ", @term;
                return $term;
            }, do {
                my @bind;
                for my $arg (@$args) {
                    if (blessed($arg) && $arg->can('as_sql')) {
                        push @bind, $arg->bind();
                    } else {
                        push @bind, $arg;
                    }
                }
                \@bind;
            });
        };

        push @EXPORT, $fn;
    }

    for (qw(in not_in)) {
        my $fn = "sql_$_";
        my $op = uc $_;
        $op =~ s/_/ /g;

        *{__PACKAGE__ . "::$fn"} = sub {
            # fetch args
            my $args = pop;
            Carp::croak("arguments to `$op` must be contained in an arrayref")
                if ref $args ne 'ARRAY';
            my $column = shift;
            # build and return the compiler
            return SQL::QueryMaker->_new($column, sub {
                my ($column, $quote_cb) = @_;
                Carp::croak("no column binding for $fn")
                    unless defined $column;
                return $op eq 'IN' ? '0=1' : '1=1'
                    if @$args == 0;
                my @term;
                for my $arg (@$args) {
                    if (blessed($arg) && $arg->can('as_sql')) {
                        my $term = $arg->as_sql(undef, $quote_cb);
                        push @term, $term eq '?' ? $term : "($term)"; # emit parens only when necessary
                    } else {
                        push @term, '?';
                    }
                }
                my $term = $quote_cb->($column) . " $op (" . join(',', @term) . ')';
                return $term;
            }, do {
                my @bind;
                for my $arg (@$args) {
                    if (blessed($arg) && $arg->can('as_sql')) {
                        push @bind, $arg->bind();
                    } else {
                        push @bind, $arg;
                    }
                }
                \@bind;
            });
        };

        push @EXPORT, $fn;
    }

    my %FNOP = (
        'is_null' => 'IS NULL',
        'is_not_null' => 'IS NOT NULL',
        'eq' => '= ?',
        'ne' => '!= ?',
        'lt' => '< ?',
        'gt' => '> ?',
        'le' => '<= ?',
        'ge' => '>= ?',
        'like' => 'LIKE ?',
        'between' => 'BETWEEN ? AND ?',
        'not_between' => 'NOT BETWEEN ? AND ?',
        'not' => 'NOT @',
    );
    for (keys %FNOP) {
        my $fn = "sql_$_";
        my ($num_args, $builder) = _compile_builder($FNOP{$_});

        *{__PACKAGE__ . "::$fn"} = sub {
            # fetch args
            my $column = @_ > $num_args ? shift : undef;
            Carp::croak("the operator expects $num_args parameters, but got " . scalar(@_))
                if $num_args != @_;
            return _sql_op($fn, $builder, $column, [ @_ ]);
        };

        push @EXPORT, $fn;
    }
}

sub sql_op {
    my $args = pop;
    my $expr = pop;
    my ($num_args, $builder) = _compile_builder($expr);
    Carp::croak("the operator expects $num_args but got " . scalar(@$args))
        if $num_args != @$args;
    return _sql_op("sql_op", $builder, shift, $args);
}

sub _sql_op {
    my ($fn, $builder, $column, $args) = @_;
    return SQL::QueryMaker->_new($column, sub {
        my ($column, $quote_cb) = @_;
        Carp::croak("no column binding for $fn(args...)")
            unless defined $column;
        my $term = $builder->($quote_cb->($column));
        return $term;
    }, $args);
}

sub sql_raw {
    my ($sql, @bind) = @_;
    return SQL::QueryMaker->_new(undef, sub {
        return $sql;
    }, \@bind);
}

sub _compile_builder {
    my $expr = shift;
    # substitute the column character
    $expr = "\@ $expr"
        if $expr !~ /\@/;

    my $num_args = @{[ $expr =~ /\?/g ]};
    my @expr = split /\@/, $expr, -1;
    my $builder = sub {
        return join $_[0], @expr;
    };
    return ($num_args, $builder);
}

sub _new {
    my ($class, $column, $as_sql, $bind) = @_;
    for my $b (@$bind) {
        Carp::croak("cannot bind an arrayref or an hashref")
            if ref $b && ! blessed($b);
    }
    return bless {
        column => $column,
        as_sql => $as_sql,
        bind   => $bind,
    }, $class;
}

sub bind_column {
    my ($self, $column) = @_;
    if (defined $column) {
        Carp::croak('cannot rebind column for \`' . $self->{column} . "` to: `$column`")
            if defined $self->{column};
    }
    $self->{column} = $column;
}

sub as_sql {
    my ($self, $supplied_colname, $quote_cb) = @_;
    $self->bind_column($supplied_colname)
        if defined $supplied_colname;
    $quote_cb ||= \&quote_identifier;
    return $self->{as_sql}->($self->{column}, $quote_cb);
}

sub bind {
    my $self = shift;
    return @{$self->{bind}};
}

sub quote_identifier {
    my $label = shift;
    return join '.', map { "`$_`" } split /\./, $label;
}

1;
__END__

=head1 NAME

SQL::QueryMaker - helper functions for SQL query generation

=head1 SYNOPSIS

    my $query = sql_eq(foo => $v);
    $query->as_sql;                 # `foo`=?
    $query->bind;                   # ($v)

    my $query = sql_lt(foo => $v);
    $query->as_sql;                 # `foo`<?
    $query->bind;                   # ($v)

    my $query = sql_in(foo => [
        $v1, $v2, $v3,
    ]);
    $query->as_sql;                 # `foo` IN (?,?,?)
    $query->bind;                   # ($v1,$v2,$v3)

    my $query = sql_and(foo => [
        sql_ge($min),
        sql_lt($max)
    ]);
    $query->as_sql;                 # `foo`>=? AND `foo`<?
    $query->bind;                   # ($min,$max)

    my $query = sql_and([
        sql_eq(foo => $v1),
        sql_eq(bar => $v2)
    ];
    $query->as_sql;                 # `foo`=? AND `bar`=?
    $query->bind;                   # ($v1,$v2)

    my $query = sql_and([
        foo => $v1,
        bar => sql_lt($v2),
    ]);
    $query->as_sql;                 # `foo`=? AND `bar`<?
    $query->bind;                   # ($v1,$v2)

=head1 DESCRIPTION

This module concentrates on providing an expressive, concise way to declare SQL
expressions by exporting carefully-designed functions.
It is possible to use the module to generate SQL query conditions and pass them
as arguments to other more versatile query builders such as L<SQL::Maker>.

The functions exported by the module instantiate comparator objects that build
SQL expressions when their C<as_sql> method are being invoked.
There are two ways to specify the names of the columns to the comparator; to
pass in the names as argument or to specify then as an argument to the
C<as_sql> method.

=head1 FUNCTIONS

=head2 C<< sql_eq([$column,] $value) >>

=head2 C<< sql_ne([$column,] $value) >>

=head2 C<< sql_lt([$column,] $value) >>

=head2 C<< sql_gt([$column,] $value) >>

=head2 C<< sql_le([$column,] $value) >>

=head2 C<< sql_ge([$column,] $value) >>

=head2 C<< sql_like([$column,] $value) >>

=head2 C<< sql_is_null([$column]) >>

=head2 C<< sql_is_not_null([$column]) >>

=head2 C<< sql_not([$column]) >>

=head2 C<< sql_between([$column,] $min_value, $max_value) >>

=head2 C<< sql_not_between([$column,] $min_value, $max_value) >>

=head2 C<< sql_in([$column,] \@values) >>

=head2 C<< sql_not_in([$column,] \@values) >>

Instantiates a comparator object that tests a column against given value(s).

=head2 C<< sql_and([$column,] \@conditions) >>

=head2 C<< sql_or([$ column,] \@conditions) >>

Aggregates given comparator objects into a logical expression.

If specified, the column name is pushed down to the arguments when the
C<as_sql> method is being called, as show in the second example below.

    sql_and([                   # => `foo`=? AND `bar`<?
        sql_eq("foo" => $v1),
        sql_lt("bar" => $v2)
    ])

    sql_and("foo" => [          # => `foo`>=$min OR `foo`<$max
        sql_ge($min),
        sql_lt($max),
    ])

=head2 C<< sql_and(\%conditions) >>

=head2 C<< sql_or(\%conditions) >>

Aggregates given pairs of column names and comparators into a logical
expression.

The value part is composed of as the argument to the C<=> operator if it is
not a blessed reference.

    my $query = sql_and({
        foo => 'abc',
        bar => sql_lt(123),
    });
    $query->as_sql;             # => `foo`=? AND bar<?
    $query->bind;               # => ('abc', 123)


=head2 C<< sql_op([$column,] $op_sql, \@bind_values) >>

Generates a comparator object that tests a column using the given SQL and
values.  C<<@>> in the given SQL are replaced by the column name (specified
either by the argument to the function or later by the call to the C<<as_sql>>
method), and C<<?>> are substituted by the given bind values.

=head2 C<< sql_raw($sql, @bind_values) >>

Generates a comparator object from raw SQL and bind values.  C<<?>> in the
given SQL are replaced by the bind values.

=head2 C<< $obj->as_sql() >>

=head2 C<< $obj->as_sql($column_name) >>

=head2 C<< $obj->as_sql($column_name, $quote_identifier_cb) >>

Compiles given comparator object and returns an SQL expression.
Corresponding bind values should be obtained by calling the C<bind> method.

The function optionally accepts a column name to which the comparator object
should be bound; an error is thrown if the comparator object is already bound
to another column.

The function also accepts a callback for quoting the identifiers.  If omitted,
the identifiers are quoted using C<`> after being splitted using C<.>; i.e. a
column designated as C<foo.bar> is quoted as C<`foo`.`bar`>.

=head2 C<< $obj->bind() >>

Returns a list of bind values corresponding to the SQL expression returned by
the C<as_sql> method.

=head1 CHEAT SHEET

    IN:        sql_eq('foo' => 'bar')
    OUT QUERY: '`foo` = ?'
    OUT BIND:  ('bar')

    IN:        sql_ne('foo' => 'bar')
    OUT QUERY: '`foo` != ?'
    OUT BIND:  ('bar')

    IN:        sql_in('foo' => ['bar', 'baz'])
    OUT QUERY: '`foo` IN (?,?)'
    OUT BIND:  ('bar','baz')

    IN:        sql_and([sql_eq('foo' => 'bar'), sql_eq('baz' => 123)])
    OUT QUERY: '(`foo` = ?) AND (`baz` = ?)'
    OUT BIND:  ('bar',123)

    IN:        sql_and('foo' => [sql_ge(3), sql_lt(5)])
    OUT QUERY: '(`foo` >= ?) AND (`foo` < ?)'
    OUT BIND:  (3,5)

    IN:        sql_or([sql_eq('foo' => 'bar'), sql_eq('baz' => 123)])
    OUT QUERY: '(`foo` = ?) OR (`baz` = ?)'
    OUT BIND:  ('bar',123)

    IN:        sql_or('foo' => ['bar', 'baz'])
    OUT QUERY: '(`foo` = ?) OR (`foo` = ?)'
    OUT BIND:  ('bar','baz')

    IN:        sql_is_null('foo')
    OUT QUERY: '`foo` IS NULL'
    OUT BIND:  ()

    IN:        sql_is_not_null('foo')
    OUT QUERY: '`foo` IS NOT NULL'
    OUT BIND:  ()

    IN:        sql_between('foo', 1, 2)
    OUT QUERY: '`foo` BETWEEN ? AND ?'
    OUT BIND:  (1,2)

    IN:        sql_not('foo')
    OUT QUERY: 'NOT `foo`'
    OUT BIND:  ()

    IN:        sql_op('apples', 'MATCH (@) AGAINST (?)', ['oranges'])
    OUT QUERY: 'MATCH (`apples`) AGAINST (?)'
    OUT BIND:  ('oranges')

    IN:        sql_raw('SELECT * FROM t WHERE id=?',123)
    OUT QUERY: 'SELECT * FROM t WHERE id=?'
    OUT BIND:  (123)

    IN:        sql_in('foo', => [123,sql_raw('SELECT id FROM t WHERE cat=?',5)])
    OUT QUERY: '`foo` IN (?,(SELECT id FROM t WHERE cat=?))'
    OUT BIND:  (123,5)

=head1 AUTHOR

Kazuho Oku

=head1 SEE ALSO

L<SQL::Abstract>
L<SQL::Maker>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, or under the MIT License.

=cut
