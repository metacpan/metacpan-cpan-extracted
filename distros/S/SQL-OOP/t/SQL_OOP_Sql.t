package SQL_OOP_Sql;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Array;
use SQL::OOP::Insert;
use SQL::OOP::Where;

__PACKAGE__->runtests;

sub bind_include_undef : Test(5) {
    
    my $sql = SQL::OOP::Base->new('a', ['a', undef, 'c']);
    is($sql->to_string, 'a');
    my @bind = $sql->bind;
    is(scalar @bind, 3);
    is(shift @bind, 'a');
    is(shift @bind, undef);
    is(shift @bind, 'c');
}

sub array : Test {
    
    my $sql = SQL::OOP::Array->new('a', 'b', 'c')->set_sepa(',');
    is($sql->to_string, q{a,b,c});
}

sub array_include_undef : Test {
    
    my $sql = SQL::OOP::Array->new('a', undef, 'c')->set_sepa(',');
    is($sql->to_string, q{a,c});
}

sub array_basic : Test(5) {
    
    my $sql1 = SQL::OOP::Base->new('a', ['a']);
    my $sql2 = SQL::OOP::Base->new('b', ['b']);
    my $sql3 = SQL::OOP::Base->new('c', ['c']);
    my $sql = SQL::OOP::Array->new($sql1, $sql2, $sql3)->set_sepa(',');
    is($sql->to_string, q{a,b,c});
    my @bind = $sql->bind;
    is(scalar @bind, 3);
    is(shift @bind, 'a');
    is(shift @bind, 'b');
    is(shift @bind, 'c');
}

sub array_basic_include_undef : Test(5) {
    
    my $sql1 = SQL::OOP::Base->new('a', ['a']);
    my $sql2 = SQL::OOP::Base->new('b', [undef]);
    my $sql3 = SQL::OOP::Base->new('c', ['c']);
    my $sql = SQL::OOP::Array->new($sql1, $sql2, $sql3)->set_sepa(',');
    is($sql->to_string, q{a,b,c});
    my @bind = $sql->bind;
    is(scalar @bind, 3);
    is(shift @bind, 'a');
    is(shift @bind, undef);
    is(shift @bind, 'c');
}

sub array_basic_include_undef2 : Test(5) {
    
    my $sql1 = SQL::OOP::Base->new('a', ['a']);
    my $sql2 = SQL::OOP::Base->new('b', undef);
    my $sql3 = SQL::OOP::Base->new('c', ['c']);
    my $sql = SQL::OOP::Array->new($sql1, $sql2, $sql3)->set_sepa(',');
    is($sql->to_string, q{a,b,c});
    my @bind = $sql->bind;
    is(scalar @bind, 2);
    is(shift @bind, 'a');
    is(shift @bind, 'c');
}

sub quote : Test {
    
    my $sql = SQL::OOP::ID->new('a');
    is($sql->to_string, q{"a"});
}

sub set_quote : Test {
    
    my $id = SQL::OOP::ID->new('a');
    $id->quote_char(q(`));
    is($id->to_string, q{`a`});
}

sub set_quote_deep : Test {
    my $elem = SQL::OOP::ID->new('a');
    my $array = SQL::OOP::Array->new($elem, $elem);
    $array->quote_char(q{`});
    is $array->to_string, q{(`a`) (`a`)};
}

sub arrayed_construction : Test(4) {
    
    my $expected = compress_sql(<<EOF);
SELECT
    *
FROM
    tbl1
WHERE
    "a" = ?
EOF
    
    ### case 1
    {
        my $sql = SQL::OOP::Array->new(
            'SELECT', '*', 'FROM', 'tbl1', 'WHERE', '"a" = ?');
        is($sql->to_string, $expected);
    }
    
    ### case 2
    {
        my $cond = SQL::OOP::Where->cmp('=', 'a', 'b');
        my $sql = SQL::OOP::Array->new(
            'SELECT', '*', 'FROM', 'tbl1', 'WHERE', $cond);
        my @bind = $sql->bind;
        is($sql->to_string, $expected);
        is(scalar @bind, 1);
        is(shift @bind, 'b');
    }
}

sub to_string_embedded : Test(2) {
    my $cond = SQL::OOP::Where->cmp('=', 'a', 'b');
    my $sql = SQL::OOP::Array->new(
        'SELECT', '*', 'FROM', 'tbl1', 'WHERE', $cond);
    my @bind = $sql->bind;
    is($sql->to_string_embedded, q{SELECT * FROM tbl1 WHERE "a" = 'b'});
    is($sql->to_string_embedded(q{`}), q{SELECT * FROM tbl1 WHERE "a" = `b`});
}

sub retrieve_from_array : Test(7) {
    my $sql = SQL::OOP::Array->new('a', 'b', 'c');
    my @a = $sql->values;
    is scalar @a, 3;
    is $a[0]->to_string, 'a';
    is $a[1]->to_string, 'b';
    is $a[2]->to_string, 'c';

    $sql = SQL::OOP::IDArray->new([['A','B'],['C','D']]);
    @a = $sql->values;
    is scalar @a, 2;
    is $a[0]->to_string, '"A"."B"';
    is $a[1]->to_string, '"C"."D"';
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
