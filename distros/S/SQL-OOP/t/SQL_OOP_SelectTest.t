package SQL_OOP_SelectTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Select;

__PACKAGE__->runtests;

sub array_include_undef2 : Test(1) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_WHERE   => sub {
            SQL::OOP::Array->new('a', 'b', undef, 'c')->set_sepa(', ')
        }
    );
    is($select->to_string, 'WHERE a, b, c');
}

sub set_clause_separately : Test(2) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => 'key1',
        $select->ARG_FROM   => 'table1',
    );
    
    is($select->to_string, q(SELECT key1 FROM table1));
    
    ### append clause
    $select->set(
        $select->ARG_WHERE  => 'some cond',
    );
    
    is($select->to_string, q(SELECT key1 FROM table1 WHERE some cond));
}

sub set_clause_separately_with_bind : Test(3) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => 'key1',
        $select->ARG_FROM   => 'table1',
    );
    $select->set(
        $select->ARG_WHERE  => SQL::OOP::Where->cmp('=', 'a', 'b'),
    );
    
    is($select->to_string, q(SELECT key1 FROM table1 WHERE "a" = ?));
    my @bind = $select->bind;
    is(scalar @bind, 1);
    is(shift @bind, 'b');
}

sub array_to_string : Test(1) {
    
    my $array = SQL::OOP::Array->new('a', 'b', undef, 'c')->set_sepa(', ');
    is($array->to_string, 'a, b, c');
}

sub array_to_string3 : Test(1) {
    
    my $select = SQL::OOP::Select->new;
    $select->set(
        $select->ARG_WHERE => SQL::OOP::Where->cmp('=', 'col1', SQL::OOP::ID->new('col2'))
    );
    is($select->to_string, 'WHERE "col1" = ("col2")');
}

sub array_to_string4 : Test(1) {
    
    my $where = SQL::OOP::Where->new();
    my $sql = SQL::OOP::Base->new('col2');
    my $a = $where->cmp('=', 'col1', $sql);
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_WHERE  => $a,
    );
    is($select->to_string, 'SELECT * WHERE "col1" = col2');
}

sub function_in_field : Test(1) {
    
    my $select = SQL::OOP::Select->new;
    $select->set(
        $select->ARG_FIELDS => 'max(a) AS b',
        $select->ARG_FROM   => 'tbl',
    );
    is($select->to_string, 'SELECT max(a) AS b FROM tbl');
}

sub select_part_of_other1 : Test(1) {
    
    my $select = SQL::OOP::Select->new;
    $select->set(
        $select->ARG_FIELDS => 'col1',
        $select->ARG_FROM   => 'tbl',
        $select->ARG_WHERE   => 'test'
    );
    my $array = SQL::OOP::Array->new('col1', $select)->set_sepa(' = ');
    is($array->to_string, q{col1 = (SELECT col1 FROM tbl WHERE test)});
}

sub select_part_of_other2 : Test(3) {
    
    my $where = SQL::OOP::Where->new();
    my $sql = SQL::OOP::Select->new();
    $sql->set(
        $sql->ARG_FIELDS    => '*',
        $sql->ARG_WHERE     => $where->cmp('=', 'col1', 'col2')
    );
    my $a = $where->cmp('=', 'col1', $sql);
    is($a->to_string, '"col1" = (SELECT * WHERE "col1" = ?)');
    my @bind = $a->bind;
    is(scalar @bind, 1);
    is(shift @bind, 'col2');
}

sub cmp_nested_subquery2 : Test(3) {
    
    my $where = SQL::OOP::Where->new();
    my $select1 = SQL::OOP::Select->new;
    $select1->set(
        $select1->ARG_FIELDS    => '*',
        $select1->ARG_WHERE     => $where->cmp('=', 'col1', 'col2')
    );
    my $a = $where->cmp('=', 'col1', $select1);
    my $select2 = SQL::OOP::Select->new();
    $select2->set(
        $select2->ARG_FIELDS => '*',
        $select2->ARG_WHERE  => $a,
    );
    is($select2->to_string, q{SELECT * WHERE "col1" = (SELECT * WHERE "col1" = ?)});
    my @bind = $select2->bind;
    is(scalar @bind, 1);
    is(shift @bind, 'col2');
}

sub subquery_in_where : Test(1) {
    
    my $select = SQL::OOP::Select->new;
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_WHERE  => SQL::OOP::Where->cmp('=', 'col1', sub {
            my $select = SQL::OOP::Select->new;
            $select->set(
                $select->ARG_FIELDS  => '*',
                $select->ARG_WHERE   => 'test'
            );
        }),
    );
    
    is($select->to_string, q{SELECT * WHERE "col1" = (SELECT * WHERE test)});
}

sub subquery_in_where2 : Test(3) {
    
    my $where = SQL::OOP::Where->new;
    my $select = SQL::OOP::Select->new;
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_WHERE  => $where->cmp('=', 'col1',
            sub {
                my $sql = SQL::OOP::Select->new;
                $sql->set(
                    $sql->ARG_FIELDS => '*',
                    $sql->ARG_WHERE => $where->cmp('=', 'col1', 'col2')
                );
            }
        ),
    );
    is($select->to_string, q{SELECT * WHERE "col1" = (SELECT * WHERE "col1" = ?)});
    my @bind = $select->bind;
    is(scalar @bind, 1);
    is(shift @bind, 'col2');
}

sub subquery_in_where3 : Test(1) {
    
    my $expected = compress_sql(<<EOF);
SELECT
    *
FROM
    "tbl" A
WHERE
    "A"."col1" = (
        SELECT
            "col1"
        FROM
            "tbl2" AS "B"
        WHERE
            "A"."id" = ?
    )
EOF
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_FROM   => q("tbl" A),
        $select->ARG_WHERE  => sub {
            my $where = SQL::OOP::Where->new();
            my $select2 = SQL::OOP::Select->new();
            $select2->set(
                $select2->ARG_FIELDS => SQL::OOP::ID->new('col1'),
                $select2->ARG_FROM   => SQL::OOP::ID->new('tbl2')->as('B'),
                $select2->ARG_WHERE  =>
                    $where->cmp('=', SQL::OOP::ID->new('A', 'id'), 'col2')
            );
            return $where->cmp('=', SQL::OOP::ID->new('A', 'col1'), $select2);
        }
    );
    
    is($select->to_string, $expected);
    my @bind = $select->bind;
}

sub subquery_in_from : Test(1) {
    
    my $expected = compress_sql(<<EOF);
SELECT
    *
FROM
    (
        SELECT
            "col1", "col2"
        FROM
            "table1"
    )
EOF
    
    my $select = SQL::OOP::Select->new();
    my $select2 = SQL::OOP::Select->new();
    
    $select2->set(
        $select2->ARG_FIELDS => q("col1", "col2"),
        $select2->ARG_FROM   => q("table1"),
    );
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_FROM   => $select2,
    );
    
    is($select->to_string, $expected);
    my @bind = $select->bind;
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
