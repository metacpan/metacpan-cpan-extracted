package SQL_OOP_OrderTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Select;

__PACKAGE__->runtests;

sub order_by : Test {
    
    my $orderby = SQL::OOP::Order->new('a', 'b');
    is($orderby->to_string, q{"a", "b"});
}

sub expect_bare_string : Test(3) {
    
    my $o = SQL::OOP::Order->new;
    $o->append(SQL::OOP->new(q{date('now')}));
    is($o->to_string, q{date('now')});
    $o->append_desc(SQL::OOP->new(q{date('now')}));
    is($o->to_string, q{date('now'), date('now') DESC});
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => '*', 
        $select->ARG_ORDERBY => $o
    );
    is($select->to_string, q{SELECT * ORDER BY date('now'), date('now') DESC});
}

sub order_append : Test {

    my $order = SQL::OOP::Order->new();
    $order->append(
        $order->new_asc('a'),
        $order->new_asc('b'),
        $order->new_desc('c')
    );
    is($order->to_string, qq{"a", "b", "c" DESC}, 'Append order by obj');
}

sub order_append_literal : Test(4) {

    my $order = SQL::OOP::Order->new();
    $order->append('"a"');
    is($order->to_string, qq{"a"}, 'Append literal order');
    $order->append('"b" DESC');
    is($order->to_string, qq{"a", "b" DESC}, 'Append literal order2');
    $order->append_asc('c');
    is($order->to_string, qq{"a", "b" DESC, "c"}, 'Append literal order3');
    $order->append_desc('d');
    is($order->to_string, qq{"a", "b" DESC, "c", "d" DESC}, 'Append literal order4');
}

sub order_abstract : Test(3) {
    
    {
        my $sql = SQL::OOP::Order->abstract([['col1'], ['col2']]);
        is($sql->to_string, q{"col1", "col2"});
    }
    {
        my $sql = SQL::OOP::Order->abstract([['col1', 1], ['col2']]);
        is($sql->to_string, q{"col1" DESC, "col2"});
    }
    {
        my $sql = SQL::OOP::Order->abstract([['col1'], ['col2', 1]]);
        is($sql->to_string, q{"col1", "col2" DESC});
    }
}

sub order_abstract_scalar_for_asc : Test(2) {
    
    {
        my $sql = SQL::OOP::Order->abstract([['col1', 1], 'col2']);
        is($sql->to_string, q{"col1" DESC, "col2"});
    }
    {
        my $sql = SQL::OOP::Order->abstract(['col1', ['col2', 1]]);
        is($sql->to_string, q{"col1", "col2" DESC});
    }
}

sub new_with_key_in_array_ref : Test(1) {
    my $sql = SQL::OOP::Order->new(['a','b'],['c','d']);
    is($sql->to_string, q{"a"."b", "c"."d"});
}

sub new_asc_with_key_in_array_ref : Test(1) {
    my $sql = SQL::OOP::Order->new_asc(['a','b']);
    is($sql->to_string, q{"a"."b"});
}

sub new_desc_with_key_in_array_ref : Test(1) {
    my $sql = SQL::OOP::Order->new_desc(['a','b']);
    is($sql->to_string, q{"a"."b" DESC});
}

sub append_with_key_in_array_ref : Test(2) {
    my $sql = SQL::OOP::Order->new;
    $sql->append_asc(['a','b']);
    is($sql->to_string, q{"a"."b"});
    $sql->append_desc(['c','d']);
    is($sql->to_string, q{"a"."b", "c"."d" DESC});
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
