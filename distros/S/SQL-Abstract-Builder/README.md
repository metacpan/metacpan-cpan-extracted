# SQL::Abstract::Builder

It builds & executes relational queries.

(c) 2012 Traian Nedelea

This is licensed under the Do What The Fuck You Want Public License. You may
obtain a copy of the license [here][wtfpl].

## What is it?

It gives you a very simple way to define fetch documents (rows and related
children) from your relational DB (instead of just rows).

## How do I use it?

    my @docs = query {"dbi:mysql:$db",$user} build {
        -columns => [qw(id foo bar)],
        -from => 'table1',
        -key => 'id',
    } include {
        -columns => [qw(id baz glarch)],
        -from => 'table2',
        -key => 'table1_id',
    } include {
        -columns => [qw(id alfa)],
        -from => 'table3',
        -key => 'table1_id',
    };

The blocks are just `SQL::Abstract::More` with one addition: the `-key` field.
A key specified in an `include` will be matched against the key given in a
`build`.

## How does it work?

A `LEFT JOIN` query is built for every included table, then the queries are
executed and merged into related documents based on the `-key`s specified.

[wtfpl]: http://sam.zoy.org/wtfpl (WTFPL)
