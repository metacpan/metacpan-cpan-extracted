package SQL_OOP_IdentifierTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::IDArray;
use SQL::OOP::Select;

__PACKAGE__->runtests;

sub new_as : Test {
    
    my $table = SQL::OOP::ID->new('tbl1')->as('T1');
    is($table->to_string, q{"tbl1" AS "T1"});
}

sub dot_syntax : Test {
    
    my $fields = SQL::OOP::ID->new('public', 'tbl1');
    my $sql = $fields->to_string;
    is($sql, q{"public"."tbl1"});
}

sub dot_syntax_with_as : Test {
    
    my $fields = SQL::OOP::ID->new('public', 'tbl1')->as('T1');
    my $sql = $fields->to_string;
    is($sql, q{"public"."tbl1" AS "T1"});
}

sub fields_new : Test {
    
    my $fields = SQL::OOP::IDArray->new(qw(a b c));
    my $sql = $fields->to_string;
    is($sql, qq{"a", "b", "c"});
}

sub fields_append : Test {

    my $fields = SQL::OOP::IDArray->new(qw(a));
    is($fields->to_string, qq{"a"});
}

sub fields_append2 : Test {

    my $fields = SQL::OOP::IDArray->new(qw(a));
    $fields->append('b');
    is($fields->to_string, qq{"a", "b"});
}

sub fields_append_literal : Test {

    my $fields = SQL::OOP::IDArray->new(qw(a b c));
    $fields->append(SQL::OOP::Base->new('*'));
    is($fields->to_string, qq{"a", "b", "c", *});
}

sub nested_token : Test {

    my $fields = SQL::OOP::IDArray->new(qw(a b c));
    my $sub_query = SQL::OOP::Select->new();
    $sub_query->set(
        $sub_query->ARG_FIELDS  => 'hoge',
        $sub_query->ARG_WHERE   => 'a = b',
    );
    $fields->append($sub_query);
    is($fields->to_string, qq{"a", "b", "c", (SELECT hoge WHERE a = b)});
}

sub id_literaly : Test {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => SQL::OOP::IDArray->new(
            SQL::OOP::ID->new('column1'),
            SQL::OOP::Base->new('count(*) AS "B"'),
        ),
    );
    is($select->to_string, q{SELECT "column1", count(*) AS "B"});
}

sub array2 : Test {
    
    my $sql = SQL::OOP::Array->new('a', 'b', SQL::OOP::ID->new('c'))->set_sepa(',');
    is($sql->to_string, q{a,b,("c")});
}

sub array3 : Test {
    
    my $sql = SQL::OOP::ID->new('a', 'b', SQL::OOP::Base->new('c'));
    is($sql->to_string, q{"a"."b".c});
}

sub id_test : Test {
    
    my $id = SQL::OOP::ID->new('public','table','c1');
    is($id->to_string, q{"public"."table"."c1"});
}

sub id_is_escaped : Test(2) {
    
    my $id_part = SQL::OOP::ID::Parts->new('test"test');
    is($id_part->to_string, q{"test""test"});
    my $id = SQL::OOP::ID->new('table"1', 'column"1');
    is($id->to_string, q{"table""1"."column""1"});
}

sub id_suplied_in_ref :Test(1) {
    
    my $id = SQL::OOP::ID->new(['schema', 'table', 'col']);
    is($id->to_string, q{"schema"."table"."col"});
}

sub id_array_suplied_in_ref :Test(1) {
    my $id = SQL::OOP::IDArray->new([['schema', 'table', 'col1'], ['schema', 'table', 'col2']]);
    is($id->to_string, q{"schema"."table"."col1", "schema"."table"."col2"});
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
