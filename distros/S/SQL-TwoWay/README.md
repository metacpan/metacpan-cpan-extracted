# NAME

SQL::TwoWay - Run same SQL in valid SQL and DBI placeholder.

# SYNOPSIS

    use SQL::TwoWay;

    my $name = 'STARTING OVER';
    my ($sql, @binds) = two_way_sql(
        q{SELECT *
        FROM cd
        WHERE name=/* $name */"MASTERPIECE"}, {
        name => $name,
    });

    # $sql: SELECT * FROM cd WHERE name=?
    # $binds[0] = 'STARTING OVER'

# DESCRIPTION

SQL::TwoWay is a way to support 2way SQL.

I guess building complex SQL using O/R Mapper or SQL builder, like SQL::Abstract is worth.
When you writing complex SQL, you should write SQL by your hand.

And then, you got a issue: "I can't run my query on MySQL console!". Yes.
A query like `SELECT * FROM cd WHERE name=?` is not runnable on console because that contains placeholder.

So, the solution is SQL::TwoWay.

You can write a query like this.

    SELECT * FROM cd WHERE name=/* $name */"MASTERPIECE";

This query is 100% valid SQL.

And you can make `<$sql`\> and `<@binds`\> from this query. `SQL::TwoWay::two_way_sql()` function convert this query.

Here is a example code:

    my ($sql, @binds) = two_way_sql(
        q{SELECT * FROM cd WHERE name=/* $name */"MASTERPIECE"},
        {
            name => 'STARTING OVER'
        }
    );

`$sql` is:

    SELECT * FROM cd WHERE name=?;

And `@binds` is:

    ('STARTING OVER')

So, you can use same SQL in MySQL console and Perl code. It means __2way SQL__.

# SYNTAX

- /\* $var \*/4
- /\* $var \*/(1,2,3)
- /\* $var \*/"String"

    Replace variables.

- /\* IF $cond \*/n=3/\* ELSE \*/n=5/\* END \*/
- /\* IF $cond \*/n=3/\* END \*/

# PSEUDO BNF

    if : /* IF $var */
    else : /* ELSE */
    end : /* END */
    variable : /* $var */ literal
    literal: TBD
    sql : .

    root = ( stmt )+
    stmt = sql | variable | if_stmt
    if_stmt = "IF" statement+ "ELSE" statement+ "END"
            | "IF" statement+ "END"

# LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

[s2dao](http://s2dao.seasar.org/en/index.html) supports 2 way SQL in Java.
