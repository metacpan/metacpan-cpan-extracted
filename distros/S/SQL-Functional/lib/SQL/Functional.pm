# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package SQL::Functional;
$SQL::Functional::VERSION = '0.3';
use strict;
use warnings;
use SQL::Functional::AndClause;
use SQL::Functional::CountClause;
use SQL::Functional::DeleteClause;
use SQL::Functional::DistinctClause;
use SQL::Functional::FromClause;
use SQL::Functional::FunctionClause;
use SQL::Functional::GroupByClause;
use SQL::Functional::InsertClause;
use SQL::Functional::JoinClause;
use SQL::Functional::LimitClause;
use SQL::Functional::LiteralClause;
use SQL::Functional::MatchClause;
use SQL::Functional::NullClause;
use SQL::Functional::OrClause;
use SQL::Functional::OrderByClause;
use SQL::Functional::PlaceholderClause;
use SQL::Functional::SelectClause;
use SQL::Functional::SetClause;
use SQL::Functional::TableClause;
use SQL::Functional::TruncateClause;
use SQL::Functional::UpdateClause;
use SQL::Functional::ValuesClause;
use SQL::Functional::VerbatimClause;
use SQL::Functional::WhereClause;
use SQL::Functional::WrapClause;
use Exporter;
our @ISA = qw{ Exporter };

our @EXPORT_OK = qw{
    SELECT
    star
    field
    col
    FROM
    WHERE
    match
    match_verbatim
    op
    table
    ORDER_BY
    DESC
    INNER_JOIN
    JOIN
    LEFT_JOIN
    LEFT_OUTER_JOIN
    RIGHT_JOIN
    RIGHT_OUTER_JOIN
    FULL_JOIN
    FULL_OUTER_JOIN
    OUTER_JOIN
    SUBSELECT
    AND
    OR
    INSERT
    INTO
    VALUES
    UPDATE
    SET
    DELETE
    wrap
    IS_NULL
    IS_NOT_NULL
    GROUP_BY
    LIMIT
    TRUNCATE
    DISTINCT
    func
    literal
    COUNT
};
our @EXPORT = @EXPORT_OK;

# ABSTRACT: Create SQL programmatically


sub SELECT ($$@)
{
    my ($fields, @clauses) = @_;
    my @fields;
    my $is_distinct = 0;

    if( ref $fields eq 'ARRAY' ) {
        @fields = map {
            (ref($_) && $_->does( 'SQL::Functional::FieldRole' ))
                ? $_
                : SQL::Functional::FieldClause->new({
                    name => $_,
                });
        } @$fields;
    }
    elsif( ref $fields && $fields->does( 'SQL::Functional::FieldRole' ) ) {
        @fields = ($fields);
    }
    elsif( ref $fields && $fields->isa( 'SQL::Functional::DistinctClause' ) ) {
        @fields = ($fields->fields);
        $is_distinct = 1;
    }
    else {
        @fields = ( SQL::Functional::FieldClause->new({
            name => $fields,
        }) );
    }

    my $clause = SQL::Functional::SelectClause->new(
        fields => \@fields,
        clauses => \@clauses,
        is_distinct => $is_distinct,
    );
    return ($clause->to_string, $clause->get_params);
}

sub star ()
{
    return field( '*' );
}

sub field ($)
{
    my ($name) = @_;
    return SQL::Functional::FieldClause->new({
        name => $name,
    });
}
*col = \&field;

sub table($)
{
    my ($name) = @_;
    my $table = SQL::Functional::TableClause->new({
        name => $name,
    });
    return $table;
}
*INTO = \&table;

sub FROM (@)
{
    my (@tables) = @_;
    my @table_objs = map {
        my $result;
        if( ref $_ ) {
            $result = $_;
        }
        else {
            $result = table $_;
        }

        $result;
    } @tables;

    my $clause = SQL::Functional::FromClause->new({
        tables => \@table_objs
    });

    return $clause;
}

sub WHERE ($)
{
    my ($clause) = @_;
    my @params = $clause->params;

    my $where = SQL::Functional::WhereClause->new({
        params => \@params,
        sub_clause => $clause,
    });
    return $where;
}

sub match($$$)
{
    my ($field, $op, $value) = @_;

    my $field_obj = ref($field)
        ? $field
        : SQL::Functional::FieldClause->new({
            name => $field,
        });
    my $clause_value = 
        ref($value) && $value->does( 'SQL::Functional::Clause' )
        ? $value
        : SQL::Functional::PlaceholderClause->new({
            literal => $value,
        });
    my $clause = SQL::Functional::MatchClause->new({
        field => $field_obj,
        op => $op,
        value => $clause_value,
    });
    return $clause;
}
*op = \&match;

sub match_verbatim($$$)
{
    my ($field, $op, $value) = @_;

    my $field_obj = ref($field)
        ? $field
        : SQL::Functional::FieldClause->new({
            name => $field,
        });
    my $clause_value = 
        ref($value) && $value->does( 'SQL::Functional::Clause' )
        ? $value
        : SQL::Functional::VerbatimClause->new({
            value => $value,
        });

    my $clause = SQL::Functional::MatchClause->new({
        field => $field_obj,
        op => $op,
        value => $clause_value,
    });
    return $clause;
}

sub ORDER_BY($;@)
{
    my (@fields) = @_;
    my $clause = SQL::Functional::OrderByClause->new({
        fields => \@fields,
    });
    return $clause;
}

sub DESC($)
{
    my ($field) = @_;
    # TODO should this be an object? It'd be consistent with everything 
    # else to make it one. Is there an argument besides consistency? 
    # Seems just fine like this so far . . . 
    return "$field DESC";
}

sub INNER_JOIN($$$)
{
    my ($table, $field1, $field2) = @_;
    my $clause = SQL::Functional::JoinClause->new(
        table => $table,
        field1 => $field1,
        field2 => $field2,
        type => 'inner',
    );
    return $clause;
}

sub LEFT_JOIN($$$)
{
    my ($table, $field1, $field2) = @_;
    my $clause = SQL::Functional::JoinClause->new(
        table => $table,
        field1 => $field1,
        field2 => $field2,
        type => 'left',
    );
    return $clause;
}

sub RIGHT_JOIN($$$)
{
    my ($table, $field1, $field2) = @_;
    my $clause = SQL::Functional::JoinClause->new(
        table => $table,
        field1 => $field1,
        field2 => $field2,
        type => 'right',
    );
    return $clause;
}

sub FULL_JOIN($$$)
{
    my ($table, $field1, $field2) = @_;
    my $clause = SQL::Functional::JoinClause->new(
        table => $table,
        field1 => $field1,
        field2 => $field2,
        type => 'full',
    );
    return $clause;
}

*JOIN = \&INNER_JOIN;
*LEFT_OUTER_JOIN = \&LEFT_JOIN;
*RIGHT_OUTER_JOIN = \&RIGHT_JOIN;
*FULL_OUTER_JOIN = \&FULL_JOIN;
*OUTER_JOIN = \&FULL_JOIN;

sub SUBSELECT($$@)
{
    my ($fields, @clauses) = @_;
    my @fields;
    if( ref $fields eq 'ARRAY' ) {
        @fields = map {
            (ref($_) && $_->isa( 'SQL::Functional::FieldClause' ))
                ? $_
                : SQL::Functional::FieldClause->new({
                    name => $_,
                });
        } @$fields;
    }
    elsif( $fields->isa( 'SQL::Functional::FieldClause' ) ) {
        @fields = ($fields);
    }
    else {
        @fields = ( SQL::Functional::FieldClause->new({
            name => $fields,
        }) );
    }

    my $clause = SQL::Functional::SelectClause->new({
        fields => \@fields,
        clauses => \@clauses,
    });
    return $clause;
}

sub AND
{
    my (@clauses) = @_;
    my $clause = SQL::Functional::AndClause->new({
        clauses => \@clauses,
    });
    return $clause;
}

sub OR
{
    my (@clauses) = @_;
    my $clause = SQL::Functional::OrClause->new({
        clauses => \@clauses,
    });
    return $clause;
}

sub INSERT ($$$)
{
    my ($into, $fields, $values) = @_;
    my $clause = SQL::Functional::InsertClause->new(
        into => $into,
        fields => ref $fields ? $fields : [$fields],
        values => $values,
    );
    return ($clause->to_string, $clause->get_params);
}

sub VALUES ($)
{
    my ($values) = @_;
    my $clause = SQL::Functional::ValuesClause->new(
        clauses => $values,
    );
    return $clause;
}

sub UPDATE ($$;$)
{
    my ($table, $set, $where) = @_;
    my $clause = SQL::Functional::UpdateClause->new(
        table => $table,
        set => $set,
        where => $where,
    );
    return ($clause->to_string, $clause->get_params);
}

sub SET
{
    my (@clauses) = @_;
    my $clause = SQL::Functional::SetClause->new(
        clauses => \@clauses,
    );
    return $clause;
}

sub DELETE ($;$)
{
    my ($from, $where) = @_;
    my $clause = SQL::Functional::DeleteClause->new(
        from => $from,
        where => $where,
    );
    return ($clause->to_string, $clause->get_params);
}

sub wrap ($)
{
    my ($clause) = @_;
    my $wrap = SQL::Functional::WrapClause->new({
        clause => $clause,
    });
    return $wrap;
}

sub IS_NULL ($)
{
    my ($field) = @_;
    my $field_clause = ref $field
        ? $field
        : SQL::Functional::FieldClause->new({
            name => $field,
        });

    my $clause = SQL::Functional::NullClause->new({
        field => $field_clause,
    });
    return $clause;
}

sub IS_NOT_NULL ($)
{
    my ($field) = @_;
    my $field_clause = ref $field
        ? $field
        : SQL::Functional::FieldClause->new({
            name => $field,
        });

    my $clause = SQL::Functional::NullClause->new(
        field => $field_clause,
        not => 1,
    );
    return $clause;
}

sub GROUP_BY ($)
{
    my ($field) = @_;
    my $field_clause = ref $field
        ? $field
        : SQL::Functional::FieldClause->new({
            name => $field,
        });

    my $clause = SQL::Functional::GroupByClause->new({
        field => $field_clause,
    });
    return $clause;
}

sub LIMIT ($)
{
    my ($num) = @_;
    my $limit = SQL::Functional::LimitClause->new({
        num => $num,
    });
    return $limit;
}

sub TRUNCATE($)
{
    my ($table) = @_;
    my $trunc = SQL::Functional::TruncateClause->new({
        table => $table,
    });
    return ($trunc->to_string, $trunc->get_params);
}

sub DISTINCT ($)
{
    my ($fields) = @_;
    my @fields;

    if( ref $fields eq 'ARRAY' ) {
        @fields = map {
            (ref($_) && $_->isa( 'SQL::Functional::FieldClause' ))
                ? $_
                : SQL::Functional::FieldClause->new({
                    name => $_,
                });
        } @$fields;
    }
    elsif( $fields->isa( 'SQL::Functional::FieldClause' ) ) {
        @fields = ($fields);
    }
    else {
        @fields = ( SQL::Functional::FieldClause->new({
            name => $fields,
        }) );
    }

    my $clause = SQL::Functional::DistinctClause->new({
        fields => \@fields,
    });
    return $clause;
}

sub func ($;@)
{
    my ($func_name, @args) = @_;

    my $clause = SQL::Functional::FunctionClause->new({
        name => $func_name,
        args => \@args,
    });

    return $clause;
}

sub literal ($)
{
    my ($str) = @_;
    my $clause = SQL::Functional::LiteralClause->new({
        literal => $str,
    });
    return $clause;
}

sub COUNT ($)
{
    my ($fields) = @_;
    my @fields;

    if( ref $fields eq 'ARRAY' ) {
        @fields = map {
            (ref($_) && $_->isa( 'SQL::Functional::FieldClause' ))
                ? $_
                : SQL::Functional::FieldClause->new({
                    name => $_,
                });
        } @$fields;
    }
    elsif( $fields->isa( 'SQL::Functional::FieldClause' ) ) {
        @fields = ($fields);
    }
    else {
        @fields = ( SQL::Functional::FieldClause->new({
            name => $fields,
        }) );
    }
    
    my $clause = SQL::Functional::CountClause->new({
        fields => \@fields,
    });
    return $clause;
}


1;
__END__


=head1 NAME

  SQL::Functional - Create SQL programmatically

=head1 SYNOPSIS

    my ($select, @select_params) = SELECT star,
        FROM( 'foo' ),
        WHERE match( 'bar', '=', 1 );
    
    # Run through DBI
    my $sth = $dbh->prepare_cached( $select ) or die $dbh->errstr;
    $sth->execute( @select_params ) or die $sth->errstr;
    my $results = $sth->fetchall_arrayref;
    $sth->finish;
    
    my ($insert, @insert_params) = INSERT INTO 'foo',
        [
            'bar',
        ],
        VALUES [
            1,
        ];
    my ($update, @update_params) = UPDATE 'foo', SET( 
            op( 'bar', '=', 1 ),
            op( 'baz', '=', 2 ),
        ),
        WHERE match( 'qux', '=', 3 );
    my ($delete, @delete_params) = DELETE FROM( 'foo' ),
        WHERE match( 'bar', '=', 1 );

=head1 DESCRIPTION

Builds SQL programmatically through a function-based interface.

=head1 EXPORTED FUNCTIONS

Generally, functions mapping to SQL keywords (like C<SELECT> or C<FROM>) are 
uppercase. Additional functions (like C<match> and C<table>) are lowercase.

=head2 Rawwrrr, why are you polluting my namespace?!!

Functions gotta go somewhere. If you want to keep it out of your top level 
namespace, but also want to keep things short, try this:

    package Q;
    use SQL::Functional;
    
    package main;
    my ($sql, @params) = Q::SELECT Q::star, Q::FROM 'foo';

Not exactly pretty, but it works.

=head2 Top-level Functions

These return a list. The first element is the generated SQL. The rest are the 
bind params.

=head3 SELECT

=head3 INSERT

=head3 UPDATE

=head3 DELETE

=head2 Helper Functions

These are used to build the statement. Their return values eventually make 
their way to one of the top-level functions above.

=head3 star

A star, like the one you would use to say C<SELECT * FROM . . .>.

=head3 field

Creates a L<SQL::Functional::FieldClause> and returns it. You pass in the 
name of a field, like the names of columns..

=head3 col

Alias for C<field()>.

=head3 FROM

  FROM(qw{ foo bar baz })

Creates a L<SQL::Functional::FromClause> and returns it. You pass in a list of 
tables as a string name. Alternatively, they can also be specified by a 
L<SQL::Functional::TableClause> object, which just so happens to be returned 
by the C<table> function:

  my $foo_tbl = table 'foo';
  my $from_clause = FROM $foo_tbl;

=head3 WHERE

Creates a L<SQL::Functional::WhereClause> and returns it. You pass in a 
single sub clause. Since the C<and> and C<or> functions are a single clause 
that take other clauses, you can chain these together to create your full 
C<WHERE> clause.

    my $where_clause = WHERE AND(
        match( 'bar', '=', 1 ),
        OR(
            match( 'baz', '=', 2 ),
            match( 'qux', '=', 3 ),
        ),
    );

=head3 match

Creates a L<SQL::Functional::MatchClause> and returns it.  This is how you 
would setup SQL phrases like C<baz = 1> in your C<WHERE>. It takes a 
string, an SQL operator, and a value to match. "Raw" values will always be set 
as a bind parameter. Alternatively, if the value is an object that does the 
L<SQL::Functional::Clause> role, it will be added as-is.

=head3 op

Alias for C<match>. The wording of C<match> tends to look better inside 
C<SELECT ... WHERE ...> statements, while C<op> tends to be better inside 
C<UPDATE ... SET ...> statements.

=head3 match_verbatim

Creates a L<SQL::Functional::MatchClause> and returns it. The difference 
between this and C<match> is that the third argument is used directly, 
rather than a placeholder. This is useful, for example, when you want to 
do a join like:

    WHERE foo.id = bar.foo_id

Don't know what's wrong with C<INNER JOIN>, but some people prefer this syntax.

=head3 table

Creates a L<SQL::Functional::TableClause> and returns it. Takes a string for 
the name of the table.

If you'd like to alias your table name, you can create it with this function, 
and then call the C<as> method on the object.  For instance:

    my $foo_tbl = table 'foo';
    my $bar_tbl = table 'bar';
    $foo_tbl->as( 'f' );
    $bar_tbl->as( 'b' );

    my ($sql, @sql_params) = SELECT [
            $foo_tbl->field( 'qux' ),
            $foo_tbl->field( 'quux' ),
            $bar_tbl->field( 'quuux' ),
        ],
        FROM( $foo_tbl, $bar_tbl ),
        ...

The calls to the C<field> method will include the table alias.

=head3 INTO

Alias for C<table>. The wording here is better for C<INESRT> statements.

=head3 ORDER_BY

  ORDER_BY 'foo', 'bar';

Creates a L<SQL::Functional::OrderByClause> and returns it. Takes a list of 
fields, with sorting being done in the order given. See C<DESC> for 
sorting a field in decending order.

=head3 DESC

  ORDER_BY 'foo', DESC 'bar';

Used with C<ORDER_BY> to set a field to sort in decending order.

=head3 INNER_JOIN

  INNER_JOIN( $table, $field1, $field2 );

Creates a L<SQL::Functional::JoinClause> with C<join_type = 'inner'> and 
returns it. The first argument, (C<$table>), is an 
C<SQL::Functional::TableClause> object, which is the table being joined. The 
second argument is the field on the main table that will be checked. The third 
argument is the field on the joined table.

=head3 JOIN

Alias for C<INNER_JOIN>.

=head3 LEFT_JOIN

  LEFT_JOIN( $table, $field1, $field2 );

Creates a L<SQL::Functional::JoinClause> with C<join_type = 'left'> and 
returns it. The first argument, (C<$table>), is an 
C<SQL::Functional::TableClause> object, which is the table being joined. The 
second argument is the field on the main table that will be checked. The third 
argument is the field on the joined table.

=head3 LEFT_OUTER_JOIN

Alias for C<LEFT_JOIN>.

=head3 RIGHT_JOIN

  RIGHT_JOIN( $table, $field1, $field2 );

Creates a L<SQL::Functional::JoinClause> with C<join_type = 'right'> and 
returns it. The first argument, (C<$table>), is an 
C<SQL::Functional::TableClause> object, which is the table being joined. The 
second argument is the field on the main table that will be checked. The third 
argument is the field on the joined table.

=head3 RIGHT_OUTER_JOIN

Alias for C<RIGHT_JOIN>.

=head3 FULL_JOIN

  FULL_JOIN( $table, $field1, $field2 );

Creates a L<SQL::Functional::JoinClause> with C<join_type = 'full'> and 
returns it. The first argument, (C<$table>), is an 
C<SQL::Functional::TableClause> object, which is the table being joined. The 
second argument is the field on the main table that will be checked. The third 
argument is the field on the joined table.

=head3 FULL_OUTER_JOIN

Alias for C<FULL_JOIN>.

=head3 SUBSELECT

Creates a L<SQL::Functional::SubSelectClause> object and returns it. Takes 
the same arguments as C<SELECT>, but returns the clause object rather than 
the SQL string and bind params.

=head3 AND

Creates a L<SQL::Functional::AndClause> and returns it. Takes a series of 
clauses (generally created by C<match>/C<op>), which will be joined with 
C<AND>'s. You can pass in as many clauses as you want, and even nest in 
C<OR> clauses:

    WHERE AND(
        match( 'bar', '=', 1 ),
        OR(
            match( 'baz', '=', 2 ),
            match( 'qux', '=', 3 ),
        ),
        match( 'foo', '=', 4 ),
    );

=head3 OR

Creates a L<SQL::Functional::OrClause> and returns it. Takes a series of 
clauses (generally created by C<match>/C<op>), which will be joined with 
C<OR>'s. You can pass in as many clauses as you want, and even nest in 
C<AND> clauses:

    WHERE OR(
        match( 'bar', '=', 1 ),
        AND(
            match( 'baz', '=', 2 ),
            match( 'qux', '=', 3 ),
        ),
        match( 'foo', '=', 4 ),
    );

=head3 VALUES

Creates a L<SQL::Functional::ValuesCaluse> and returns it. Takes an arrayref 
of values, which will become bind variables.

=head3 SET

Creates a L<SQL::Functional::SetClause> and returns it. Takes a list of 
L<SQL::Functional::MatchClause> objects, which you can make with C<op> 
(or C<match>).

=head3 wrap

Creates a L<SQL::Functional::WrapClause> and returns it. Takes a clause 
as an argument.

This is used when you need to wrap a portion of the SQL in parens. For 
instance, subqueries in a C<SELECT> statement need this:

  SELECT * FROM foo WHERE bar IN (SELECT id FROM bar);

Which you could build like this:

  SELECT star,
      FROM( 'foo' ),
      WHERE match( 'bar', 'IN', wrap(
          SUBSELECT ['id'], FROM 'bar'
      ));

On the other hand, C<INSERT> statements with subqueries don't take parens:

  INSERT INTO foo (bar) SELECT id from bar;

In which case you I<don't> need to use C<wrap()>:

  INSERT INTO 'foo', [ 'bar' ],
      SUBSELECT ['id'], FROM( 'baz' ), WHERE match( 'qux', '=', 1 );

=head3 IS_NULL

Creates a L<SQL::Functional::NullClause> and returns it. Takes a field to 
check as being null.

=head3 IS_NOT_NULL

Creates a L<SQL::Functional::NullClause> and returns it. Takes a field to 
check as being not null.

=head3 LIMIT

Creates a L<SQL::Functional::LimitClause> and returns it.  Takes a number 
that limits the number of rows returned.

=head3 TRUNCATE

Creates a L<SQL::Functional::TruncateClause> and returns it.  Takes a table 
name.

=head3 DISTINCT

Creates a L<SQL::Functional::DistinictClause> and returns it.  Takes a list of 
fields, which will be listed as C<DISTINCT> rows in the SQL.

=head3 func

Creates a L<SQL::Functional::FunctionClause> and returns it.  Takes a 
function name, followed by any parameters.

=head3 literal

Creates a L<SQL::Functional::LiteralClause> and returns it. 
Takes a string which will be put literally into the final SQL, rather than as 
a placeholder.

=head3 COUNT

Creates a L<SQL::Functional::CountClause> and returns it. Takes a set of 
fields, which could be passed as:

=over 4

=item * Scalar String -- for a single field

=item * ArrayRef of Strings -- for several fields

=item * An object that does L<SQL::Functional::FieldRole>.

=back

=head1 WRITING EXTENSIONS

C<SQL::Functional> can be easily extended for new SQL clauses using the
L<SQL::Functional::Clause> Moose role. See the documentation on that 
module to get started.

=head1 WHY ANOTHER WAY TO WRITE SQL?

I should preface this section by saying that I'm not trying to insult the 
developers of C<SQL::Abstract> or C<DBIx::Class>. They've obviously worked 
hard to create successful and widely used libraries for a very common task. 
Perl is better for what they've accomplished.  That said, I think they're 
stuck in an object-oriented way of thinking in a problem space that could be 
expressed more naturally with functions.

Existing ways of making database calls fall into one of three approaches: 
direct string manipulation by hand, an object interface that outputs SQL 
(as in L<SQL::Abstract>), or an object-relation mapper (L<DBIx::Class>).

Direct string manipulation is fine when your database is almost trivial; just 
a few tables and straightforward relationships. The C<SQL::Abstract> approach 
can handle slightly more complicated databases, but it tends to break down into 
esoteric, unintuitive syntax when things get really tough. Good object 
relational mappers can make some very complicated things easy, but there comes 
a point where you still need hand-optimized SQL.

What we end up with is that direct string manipulation is the way to go for 
both trivial I<and> difficult cases. The middle ground is held by libraries 
that write the SQL for you.

If we look at C<SQL::Abstract>'s documentation (most of the examples below 
are directly copied from there), we see quite a few places where it's 
hamfisting the syntax in order to get increasingly complicated features to work.
Here's an example of using direct SQL to set a date column:

    my %where  = (
        date_entered => { '>' => \["to_date(?, 'MM/DD/YYYY')", "11/26/2008"] },
        date_expires => { '<' => \"now()" }
    );
    # Becomes:
    #   WHERE date_entered > to_date(?, 'MM/DD/YYYY') AND date_expires < now()
    # With '11/26/2008' in the bind vars.

Why are we taking a reference to a scalar, or worse, a reference to an array 
reference?  Quite simply because C<SQL::Abstract> has to do everything in terms 
of arguments to methods on objects, and this is a way to twist Perl's syntax to 
get the result you want.

Switching between C<AND> and C<OR> operations gets complicated as well. 
You can do statements separated by C<AND> like this:

    my %where  = (
        user   => 'nwiger',
        status => { '!=', 'completed', -not_like => 'pending%' }
    );
    # Becomes: WHERE user = ? AND status != ? AND status NOT LIKE ?

Or separated by C<OR> like this:

    my %where = (
        status => { '=', ['assigned', 'in-progress', 'pending'] }
    );
    # Becomes: WHERE status = ? OR status = ? OR status = ?

So hashrefs give us C<AND> and arrayrefs give us C<OR>, which is already rather 
arbitrary. On top of that, we run into the problem of unique keys in hashes. 
That means the syntax can't be extended in the what would otherwise be the 
obvious way:

    my %where = (
        status => { '!=' => 2, '!=' => 1 }
    );
    # Doesn't work, second '!=' clobbers the first

Instead, the syntax has to be further extended in less and less natural ways:

    my %where = (
        status => [ -and => {'!=', 2},
                            {'!=', 1} ];
    );

At which point things start to look like an Abstract Syntax Tree. A point which 
reminds me of an 
L<old post from BrowserUK on Perlmonks|http://perlmonks.org/?node_id=510249>:

    LISP has virtually no syntax (aside from all the parens), so whan you write 
    LISP code, you are essentially writing an AST (abstract syntax tree).

Which has stuck with me ever since I read it. We can represent Abstract 
Syntax Trees very naturally with functions. For instance, Lisp might 
handle the multiple C<AND> statement like this:

    (WHERE
        (AND
            (match 'status' '!=' 2)
            (match 'status' '!=' 1)
        )
    )

Which looks at least vaguely like direct SQL, while avoiding some of the easy 
syntax errors and other cumbersome issues that you get with verbatim SQL 
strings.

With the right function definitions, we can get pretty close to the Lisp 
example in Perl:

    WHERE AND(
        match( 'status', '!=', 2 ),
        match( 'status', '!=', 1 ),
    )

You could copy-and-paste that in an email to a DBA with only a short explanation
of what's going on.  It's not too far from the AST that an SQL parser might 
create internally.

As it happens, C<SQL::Functional> uses a lot of objects to pass data around 
between functions. Objects aren't bad, they just aren't always the right tool. 
Objects and functions can be used in harmony, and it's wonderful that Perl 
allows you to do both without getting in your way.

=head1 SEE ALSO

=over 4

=item * L<SQL::Abstract>

=item * L<DBIx::Class>

=item * L<DBI>

=back

Also, all the classes at C<SQL::Functional::*Clause>.

=head1 LICENSE

Copyright (c) 2016  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut
