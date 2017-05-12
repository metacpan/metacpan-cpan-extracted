package SQL_OOP_WhereTest;
use strict;
use warnings;
use lib qw(lib);
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Select;

__PACKAGE__->runtests;

sub not_in : Test(6) {
    
    my $where = SQL::OOP::Where->new();
    my $in = $where->not_in('col', [1, 2, 3]);
    is($in->to_string, q{"col" NOT IN (?, ?, ?)});
    my @bind = $in->bind;
    is(scalar @bind, 3);
    is(shift @bind, '1');
    is(shift @bind, '2');
    is(shift @bind, '3');

    my $sub = SQL::OOP::Select->new;
    $sub->set(
        $sub->ARG_FIELDS => '*',
        $sub->ARG_FROM => 'tbl',
    );
    $in = $where->not_in('col', $sub);
    is($in->to_string, q{"col" NOT IN (SELECT * FROM tbl)});
}

sub in : Test(6) {
    
    my $where = SQL::OOP::Where->new();
    my $in = $where->in('col', [1, 2, 3]);
    is($in->to_string, q{"col" IN (?, ?, ?)});
    my @bind = $in->bind;
    is(scalar @bind, 3);
    is(shift @bind, '1');
    is(shift @bind, '2');
    is(shift @bind, '3');

    my $sub = SQL::OOP::Select->new;
    $sub->set(
        $sub->ARG_FIELDS => '*',
        $sub->ARG_FROM => 'tbl',
    );
    $in = $where->in('col', $sub);
    is($in->to_string, q{"col" IN (SELECT * FROM tbl)});
}

sub cmp_value_undef : Test(1) {
    
    my $where = SQL::OOP::Where->new();
    my $a = $where->cmp('=', 'a', undef);
    is($a, '');
}

sub cmp_nested : Test(2) {
    
    my $where = SQL::OOP::Where->new();
    my $sql = SQL::OOP::Base->new('test');
    {
        my $a = $where->cmp('=', 'col1', $sql);
        is($a->to_string, '"col1" = test');
    }
    {
        my $a = $where->cmp('=', SQL::OOP::ID->new('col1'), $sql);
        is($a->to_string, '"col1" = test');
    }
}

sub cmp_nested2 : Test(1) {
    
    my $where = SQL::OOP::Where->new();
    my $a = $where->cmp('=', SQL::OOP::Base->new('func(col1)'),
                                    SQL::OOP::Base->new('func(col2)'));
    is($a->to_string, q{func(col1) = func(col2)});
}

sub order_by : Test(3) {
    
    my $where = SQL::OOP::Where->new();
    my $obj = $where->cmp('=', 'key1', 'val1');
    is($obj->to_string, q{"key1" = ?});
    my $obj2 = $where->or();
    $obj2->append($where->cmp('=', 'key2', 'val2'));
    is($obj2->to_string, q{"key2" = ?});
    $obj2->append($where->or(
        $where->cmp('=', 'key3', 'val3'),
        $where->cmp('=', 'key4', 'val4')
    ));
    is($obj2->to_string, q{"key2" = ? OR ("key3" = ? OR "key4" = ?)});
}

sub and : Test(1) {
    
    my $where = SQL::OOP::Where->new;
    my $and = $where->and('a','b');
    is($and->to_string, q{a AND b});
}

sub and_with_sub : Test(1) {
    
    my $where = SQL::OOP::Where->new;
    my $and = $where->and(sub{'a'},sub{'b'}->());
    is($and->to_string, q{a AND b});
}

sub abstract_and : Test(1) {
    
    my $seed = [
        a => 'b',
        c => 'd',
    ];
    my $where = SQL::OOP::Where->and_abstract($seed);
    is($where->to_string, q{"a" = ? AND "c" = ?});
}

sub abstract_and_with_op : Test(1) {
    
    my $seed = [
        a => 'b',
        c => 'd',
    ];
    my $where = SQL::OOP::Where->and_abstract($seed, "LIKE");
    is($where->to_string, q{"a" LIKE ? AND "c" LIKE ?});
}

sub abstract_or : Test(1) {
    
    my $seed = [
        a => 'b',
        c => 'd',
    ];
    my $where = SQL::OOP::Where->or_abstract($seed);
    is($where->to_string, q{"a" = ? OR "c" = ?});
}

sub cmp_key_by_array : Test(2) {
    
    my $id = SQL::OOP::ID->new('public','table','c1');
    is($id->to_string, q{"public"."table"."c1"});
    my $where = SQL::OOP::Where->cmp('=', $id, 'val');
    is($where->to_string, q{"public"."table"."c1" = ?});
}

sub cmp_key_by_array_ref : Test(1) {
    
    my $where = SQL::OOP::Where->cmp('=', ['public','table','c1'], 'val');
    is($where->to_string, q{"public"."table"."c1" = ?});
}

sub is_null : Test(2) {
    
    my $where = SQL::OOP::Where->is_null('col1');
    is($where->to_string, q{"col1" IS NULL});
    my $where2 = SQL::OOP::Where->is_null(SQL::OOP::ID->new('col1'));
    is($where2->to_string, q{"col1" IS NULL});
}

sub between : Test(2) {
    
    my $where = SQL::OOP::Where->between('col1', 1, 2);
    is($where->to_string, q{"col1" BETWEEN ? AND ?});
    my $where2 = SQL::OOP::Where->between(SQL::OOP::ID->new('col1'), 1, 2);
    is($where2->to_string, q{"col1" BETWEEN ? AND ?});
}

sub between_smart : Test(2) {
    
    my $where = SQL::OOP::Where->between('col1', 1, undef);
    is($where->to_string, q{"col1" >= ?});
    my $where2 = SQL::OOP::Where->between(SQL::OOP::ID->new('col1'), 1, undef);
    is($where2->to_string, q{"col1" >= ?});
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
