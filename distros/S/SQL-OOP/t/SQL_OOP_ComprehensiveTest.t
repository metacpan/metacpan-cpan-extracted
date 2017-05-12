package SQL_OOP_CpmprehensiveTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::IDArray;
use SQL::OOP::Select;

__PACKAGE__->runtests;

sub select_basic : Test {
    
    my $select = SQL::OOP::Select->new();
    my $fields = SQL::OOP::IDArray->new(qw(a b c));
    my $sql = $fields->to_string;
    is($sql, qq{"a", "b", "c"});
}

sub basic_test: Test(1) {
    
    my $b = SQL::OOP::Base->new('a,b,c');
    is($b->to_string, 'a,b,c', 'basic test for to_string');
}

sub include_undef : Test(1) {
    
    my $a = SQL::OOP::Array->new('', '', ('a',undef,'c'))->set_sepa(', ');
    is($a->to_string, 'a, c', 'array include undef test');
}

sub basic_test_array : Test(1) {
    
    my $a = SQL::OOP::Array->new('', '', qw(a b c))->set_sepa(', ');
    is($a->to_string, 'a, b, c', 'basic array test for bind');
}

sub where_append : Test(3) {

    my $where = SQL::OOP::Where->new();
    my $and = $where->and(
        'a',
        'b',
    );
    is($and->to_string, 'a AND b', 'where initial');
    $and->append('c');
    is($and->to_string, 'a AND b AND c', 'where append');
    $and->append($where->cmp('=', 'd', 'e'));
    is($and->to_string, 'a AND b AND c AND "d" = ?', 'where append obj');
}

sub where_basic : Test {
    
    my $where = SQL::OOP::Where->new();
    my $cmp = $where->cmp('=', 'column1', 'value');
    my $and = $where->and($cmp, $cmp);
    my $sql = $and->to_string;
    is($sql, qq{"column1" = ? AND "column1" = ?}, 'cmp and cmp');
}

sub cmp_expression: Test(4) {
    
    my $where = SQL::OOP::Where->new;
    my $cmp = $where->cmp('=', 'column1', 'value');
    my $sql = $cmp->to_string;
    my @bind = $cmp->bind;
    is($sql, qq{"column1" = ?}, 'to_string');
    is(shift @bind, qw(value), 'bind');
    is(shift @bind, undef, 'no more bind');
    
    my $sql2 = $cmp->to_string('WHERE');
    is($sql2, qq{WHERE "column1" = ?}, 'prefixed');
}

### Pertial adoption
sub select_class : Test(8) {
    
    my $expected = compress_sql(<<EXPECTED);
SELECT
    *
FROM
    table
WHERE
    "a" = ? AND "b" = ?
EXPECTED
    
    ### The following blocks are expected to generate same SQL
    {
        my $select = SQL::OOP::Select->new();
        $select->set(
            $select->ARG_FIELDS => '*',
            $select->ARG_FROM   => 'table',
            $select->ARG_WHERE  => q{"a" = ? AND "b" = ?},
        );
        
        is($select->to_string, $expected, 'All literaly');
    }
    {
        my $select = SQL::OOP::Select->new();
        $select->set(
            $select->ARG_FIELDS     => '*',
            $select->ARG_FROM       => 'table',
            $select->ARG_WHERE      => q{"a" = ? AND "b" = ?},
            $select->ARG_ORDERBY    => undef,
            $select->ARG_LIMIT      => '',
        );
        
        is($select->to_string, $expected, 'Some clause maybe empty');
    }
    {
        my $select = SQL::OOP::Select->new();
        $select->set(
            $select->ARG_FIELDS => '*',
            $select->ARG_FROM   => 'table',
            $select->ARG_WHERE  => SQL::OOP::Base->new(q{"a" = ? AND "b" = ?}, [1, 2]),
        );
        
        is($select->to_string, $expected, 'Literaly but need to bind');
        my @bind = $select->bind;
        is(shift @bind, '1', 'Literaly but need to bind[sql]');
        is(shift @bind, '2', 'Literaly but need to bind[bind]');
        is(shift @bind, undef, 'Literaly but need to bind[no more bind]');
    }
    {
        my $select = SQL::OOP::Select->new();
        my $where = SQL::OOP::Where->new;
        $select->set(
            $select->ARG_FIELDS => '*',
            $select->ARG_FROM   => 'table',
            $select->ARG_WHERE  => $where->and(
                $where->cmp('=', 'a', 1),
                $where->cmp('=', 'b', 1),
            ),
        );
        
        is($select->to_string, $expected, 'Use SQL::OOP::WHERE');
    }
    {
        my $select = SQL::OOP::Select->new();
        $select->set(
            $select->ARG_FIELDS => '*',
            $select->ARG_FROM   => 'table',
            $select->ARG_WHERE  => sub {
                my $where = SQL::OOP::Where->new;
                return $where->and(
                    $where->cmp('=', 'a', 1),
                    $where->cmp('=', 'b', 1),
                )
            },
        );
        
        is($select->to_string, $expected, 'Use WHERE in sub');
    }
}

sub total : Test(13) {
    
    my $expected = compress_sql(<<"EXPECTED");
SELECT
    "ky1", "ky2", *
FROM
    "tbl1", "tbl2", "tbl3"
WHERE
    "hoge1" >= ?
    AND
    "hoge2" = ?
    AND
    (
        "hoge3" = ?
        OR
        "hoge4" = ?
        OR
        "price" BETWEEN ? AND ?
        OR
        "vprice" IS NULL
        OR
        a = b
        OR
        a = b
        OR
        c = ? ?
        OR
        "price"
        BETWEEN ? AND ?
    )
ORDER BY
    "hoge1" DESC, "hoge2"
LIMIT
    11315
OFFSET
    1
EXPECTED
    
    {
        my $select = SQL::OOP::Select->new();
        $select->set(
            $select->ARG_FIELDS => SQL::OOP::Base->new(q{"ky1", "ky2", *}),
            $select->ARG_FROM   => q("tbl1", "tbl2", "tbl3"),
            $select->ARG_WHERE  => sub {
                my $where = SQL::OOP::Where->new();
                return $where->and(
                    $where->cmp('>=', 'hoge1', 'hoge1'),
                    $where->cmp('=', 'hoge2', 'hoge2'),
                    $where->or(
                        $where->cmp('=', 'hoge3', 'hoge3'),
                        $where->cmp('=', 'hoge4', 'hoge4'),
                        $where->between('price', 10, 20),
                        $where->is_null('vprice'),
                        SQL::OOP::Base->new('a = b'),
                        'a = b',
                        SQL::OOP::Base->new('c = ? ?', ['code1', 'code2']),
                        $where->between('price', 10, 20),
                    ),
                    $where->or(
                        $where->cmp('=', 'hoge3', undef),
                        $where->cmp('=', 'hoge4', undef),
                    ),
                )
            },
            $select->ARG_ORDERBY => sub {
                my $order = SQL::OOP::Order->new();
                foreach my $rec_ref (@{[['hoge1', 1],['hoge2']]}) {
                    if ($rec_ref->[1]) {
                        $order->append_desc($rec_ref->[0]);
                    } else {
                        $order->append_asc($rec_ref->[0]);
                    }
                }
                return $order;
            },
            $select->ARG_LIMIT  => 11315,
            $select->ARG_OFFSET => 1,
        );
        
        is($select->to_string, $expected, 'complex to_string');
        my @bind = $select->bind;
        is(scalar @bind, 10, 'complex bind size');
        is(shift @bind, qw(hoge1), 'complex bind');
        is(shift @bind, qw(hoge2), 'complex bind');
        is(shift @bind, qw(hoge3), 'complex bind');
        is(shift @bind, qw(hoge4), 'complex bind');
        is(shift @bind, qw(10), 'complex bind');
        is(shift @bind, qw(20), 'complex bind');
        is(shift @bind, qw(code1), 'complex bind');
        is(shift @bind, qw(code2), 'complex bind');
        is(shift @bind, qw(10), 'complex bind');
        is(shift @bind, qw(20), 'complex bind');
        is(shift @bind, undef, 'complex bind');
    }
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
