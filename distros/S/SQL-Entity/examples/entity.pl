use strict;
use warnings;


use SQL::Entity ':all';


my $dept = SQL::Entity->new(
    name        => 'dept',
    primary_key => ['deptno'],
    alias       => 'd',
    columns     => [
        sql_column(name => 'deptno'),
        sql_column(name => 'dname')
    ],
);


my $emp = SQL::Entity->new(
    name                  => 'emp',
    primary_key		  => ['empno'],
    unique_expression     => 'rowid',
    columns               => [
        sql_column(name => 'ename', unique => 1),
        sql_column(name => 'empno'),
        sql_column(name => 'deptno')
    ],
);

my ($query, $bind) = $emp->query;
