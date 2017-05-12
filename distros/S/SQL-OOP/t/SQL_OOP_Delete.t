package SQL_OOP_UpdateTest;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Delete;

__PACKAGE__->runtests;

sub set_clause_separately : Test(1) {
    
    my $delete = SQL::OOP::Delete->new;
    $delete->set(
        $delete->ARG_TABLE => 'tbl1',
    );
    $delete->set(
        $delete->ARG_WHERE => 'some cond',
    );
    
    is($delete->to_string, q(DELETE FROM tbl1 WHERE some cond));
}

sub where : Test(3) {
    
    my $delete= SQL::OOP::Delete->new();
    $delete->set(
        $delete->ARG_TABLE => 'tbl1',
    );
    $delete->set(
        $delete->ARG_WHERE => SQL::OOP::Where->cmp('=', 'a', 'b'),
    );
    
    is($delete->to_string, q(DELETE FROM tbl1 WHERE "a" = ?));
    my @bind = $delete->bind;
    is(scalar @bind, 1);
    is(shift @bind, 'b');
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
