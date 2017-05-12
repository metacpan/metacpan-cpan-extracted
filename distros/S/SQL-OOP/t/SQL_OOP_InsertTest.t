package SQL_OOP_InsertTest;
use strict;
use warnings;
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Insert;

__PACKAGE__->runtests;

sub set_clause_separately : Test(1) {
    
    my $insert = SQL::OOP::Insert->new();
    $insert->set(
        $insert->ARG_TABLE => 'key1',
    );
    $insert->set(
        $insert->ARG_DATASET => '(a) VALUES (b)',
    );
    
    is($insert->to_string, q(INSERT INTO key1 (a) VALUES (b)));
}

sub complex_command : Test(8) {
    
    my $expected1 = compress_sql(<<EOF);
INSERT INTO "tbl1" ("col1", "col2") VALUES (?, ?)
EOF
    
    {
        my $insert = SQL::OOP::Insert->new();
        $insert->set(
            $insert->ARG_TABLE => '"tbl1"',
            $insert->ARG_DATASET => SQL::OOP::Dataset->new(col1 => 'a', col2 => 'b')
        );
        
        my @bind = $insert->bind;
        is($insert->to_string, $expected1);
        is(scalar @bind, 2);
        is(shift @bind, 'a');
        is(shift @bind, 'b');
    }
    {
        my @vals = (
            ['col1', 'val1'],
            ['col2', 'val2'],
        );
        
        my $dataset = SQL::OOP::Dataset->new();
        foreach my $rec (@vals) {
            $dataset->append($rec->[0] => $rec->[1]);
        }
        my $insert = SQL::OOP::Insert->new();
        $insert->set(
            $insert->ARG_TABLE => '"tbl1"',
            $insert->ARG_DATASET => $dataset,
        );
        
        my @bind = $insert->bind;
        is($insert->to_string, $expected1);
        is(scalar @bind, 2);
        is(shift @bind, 'val1');
        is(shift @bind, 'val2');
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
