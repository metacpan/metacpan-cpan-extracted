package SQL_OOP_CpmprehensiveTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Select;

__PACKAGE__->runtests;

sub to_string_twice : Test(2) {
    
    my $a = SQL::OOP::Base->new("a");
    is($a->to_string, 'a');
    is($a->to_string, 'a');
}

sub array_to_string_twice : Test(2) {
    
    my $a = SQL::OOP::Array->new("a")->set_sepa(',');
    is($a->to_string, 'a');
    is($a->to_string, 'a');
}

sub array_to_string_twice2 : Test(2) {
    
    my $a = SQL::OOP::Array->new(SQL::OOP::Base->new('a'), SQL::OOP::Base->new('b'))->set_sepa(', ');
    is($a->to_string, 'a, b');
    is($a->to_string, 'a, b');
}

sub select_to_string_twice1 : Test(2) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => 'a',
        $select->ARG_FROM   => 'b',
    );
    my $a = SQL::OOP::Array->new($select)->set_sepa(', ');
    is($a->to_string, 'SELECT a FROM b');
    is($a->to_string, 'SELECT a FROM b');
}

sub select_to_string_twice2 : Test(2) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => 'a',
        $select->ARG_FROM   => SQL::OOP::Base->new('b'),
    );
    my $a = SQL::OOP::Array->new($select)->set_sepa(', ');
    is($a->to_string, 'SELECT a FROM b');
    is($a->to_string, 'SELECT a FROM b');
}

sub select_to_string_twice3 : Test(2) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => 'a',
        $select->ARG_FROM   => SQL::OOP::Array->new('b')->set_sepa(''),
    );
    is($select->to_string, 'SELECT a FROM b');
    is($select->to_string, 'SELECT a FROM b');
}

sub select_to_string_twice4 : Test(1) {
    
    my $select = SQL::OOP::Select->new();
    $select->set(
        $select->ARG_FIELDS => 'a',
        $select->ARG_FROM   => 'b',
    );
    my $select2 = SQL::OOP::Select->new();
    $select2->set(
        $select2->ARG_FIELDS    => 'a',
        $select2->ARG_FROM    => $select,
    );
    is($select2->to_string, 'SELECT a FROM (SELECT a FROM b)');
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
