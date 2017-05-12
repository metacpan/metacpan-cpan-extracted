package SQL_OOP_UpdateTest;
use strict;
use warnings;
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Update;

__PACKAGE__->runtests;

sub set_clause_separately : Test(1) {
    
    my $update = SQL::OOP::Update->new;
    $update->set(
        $update->ARG_TABLE => 'tbl1',
        $update->ARG_DATASET => 'a = b, c = d',
    );
    $update->set(
        $update->ARG_WHERE => 'some cond',
    );
    
    is($update->to_string, q(UPDATE tbl1 SET a = b, c = d WHERE some cond));
}

sub where : Test(3) {
    
    my $update = SQL::OOP::Update->new();
    $update->set(
        $update->ARG_TABLE => 'tbl1',
        $update->ARG_DATASET => 'a = ?, b = ?',
    );
    $update->set(
        $update->ARG_WHERE => SQL::OOP::Where->cmp('=', 'a', 'b'),
    );
    
    is($update->to_string, q(UPDATE tbl1 SET a = ?, b = ? WHERE "a" = ?));
    my @bind = $update->bind;
    is(scalar @bind, 1);
    is(shift @bind, 'b');
}

sub values_by_array : Test(4) {
    
    my $sql = SQL::OOP::Update->new();
    $sql->set(
        $sql->ARG_DATASET => SQL::OOP::Dataset->new(a => 'b',c => 'd'),
    );
    is($sql->to_string, 'SET "a" = ?, "c" = ?');
    my @bind = $sql->bind;
    is(scalar @bind, 2);
    is(shift @bind, 'b');
    is(shift @bind, 'd');
}

sub value_order_specific : Test(3) {
    
    my $sql = SQL::OOP::Update->new();
    $sql->set(
        $sql->ARG_DATASET =>
            SQL::OOP::Dataset->new()->append(a => 'b')->append(c => 'd'),
    );
    is($sql->to_string, 'SET "a" = ?, "c" = ?');
    my @bind = $sql->bind;
    is(shift @bind, 'b');
    is(shift @bind, 'd');
}

sub update_value_is_a_array : Test(3) {
    
    my $array = SQL::OOP::Array->new->set_sepa(', ');
    $array->append(SQL::OOP::Base->new('a = ?', ['b']));
    $array->append(SQL::OOP::Base->new('c = ?', ['d']));
    my $sql = SQL::OOP::Update->new();
    $sql->set(
        $sql->ARG_DATASET => $array,
    );
    is($sql->to_string, 'SET a = ?, c = ?');
    my @bind = $sql->bind;
    is(shift @bind, 'b');
    is(shift @bind, 'd');
}

sub conprehensive : Test(8) {
    
    my $expected = compress_sql(<<EOF);
UPDATE tbl1 SET "a" = ? WHERE "c" = ?
EOF
    
    {
        my $update = SQL::OOP::Update->new();
        $update->set(
            $update->ARG_TABLE => 'tbl1',
            $update->ARG_DATASET => SQL::OOP::Dataset->new(a => 'b'),
            $update->ARG_WHERE => SQL::OOP::Where->cmp('=', 'c', 'd'),
        );
        is($update->to_string, $expected);
        my @bind = $update->bind;
        is(scalar @bind, 2);
        is(shift @bind, 'b');
        is(shift @bind, 'd');
    }
    
    {
        my $update = SQL::OOP::Update->new();
        $update->set(
            $update->ARG_TABLE => 'tbl1',
            $update->ARG_DATASET => SQL::OOP::Dataset->new(a => 'b'),
            $update->ARG_WHERE => SQL::OOP::Where->cmp('=', 'c', 'd'),
        );
        is($update->to_string, $expected);
        my @bind = $update->bind;
        is(scalar @bind, 2);
        is(shift @bind, 'b');
        is(shift @bind, 'd');
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
