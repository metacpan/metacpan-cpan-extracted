package SQL_OOP_UpdateTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Select;
use SQL::OOP::Join;

__PACKAGE__->runtests;

sub join : Test(1) {
    
    my $expected = <<EOF;
SELECT
    hoge
FROM
    (table1 LEFT JOIN table2 ON "a" = "b")
WHERE
    a
EOF
    
    my $select = SQL::OOP::Select->new;
    $select->set(
        $select->ARG_FIELDS => 'hoge',
        $select->ARG_FROM   => sub {
            my $a = SQL::OOP::Join->new;
            return $a->set(
                $a->ARG_DIRECTION   => $a->ARG_DIRECTION_LEFT,
                $a->ARG_TABLE1      => 'table1',
                $a->ARG_TABLE2      => 'table2',
                $a->ARG_ON          => '"a" = "b"',
            );
        },
        $select->ARG_WHERE  => 'a',
    );
    
    is($select->to_string, compress_sql($expected));
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
