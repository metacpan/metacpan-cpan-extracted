package SQL_OOP_UpdateTest;
use strict;
use warnings;
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Update;

__PACKAGE__->runtests;

sub sub_expression : Test(4) {
    
    my $update = SQL::OOP::Update->new;
    $update->set(
        $update->ARG_TABLE => 'tbl1',
        $update->ARG_DATASET => sub {
            my $ds = SQL::OOP::Dataset->new;
            $ds->append('a' => SQL::OOP::Base->new(q{"a" + ?}, [1]))
        },
        $update->ARG_WHERE => SQL::OOP::Where->cmp('=', 'a', 'b'),
    );
    
    is($update->to_string, q(UPDATE tbl1 SET "a" = "a" + ? WHERE "a" = ?));
    my @bind = $update->bind;
    is(scalar @bind, 2);
    is(shift @bind, 1);
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
