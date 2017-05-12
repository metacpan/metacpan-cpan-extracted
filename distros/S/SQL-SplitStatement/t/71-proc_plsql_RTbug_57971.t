#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 1;

# Bug report (by Dan Horne):
# https://rt.cpan.org/Public/Bug/Display.html?id=57971

my $sql_code = <<'SQL';
create or replace procedure test (num1 number) is
v_test varchar2 is
begin
select col1
into v_test
from my_tab;
end;
/

create table my_tab(
col1 varchar2(30),
col2 number
);

insert into my_tab(col1, col2) values ('hello', 3);
SQL

my $splitter;
my @statements;

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 3,
    'Statements correctly split'
);

