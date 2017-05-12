#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 34;

use SQL::Yapp
    table_prefix => 'T'
 # , write_dialect => 'mysql',
  , quote_identifier => sub {
        join('.', map { "`$_`" } grep { defined($_) } @_)
    },
  , quote => sub {
       "'\Q$_[0]\E'"
    },
;

sub make_select_a_concat_b()
{
    return sql{SELECT a || b || "'"};
}

{
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'COALESCE({} OR NOT @a)')."\n";

    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', '{} || @x')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'a || b')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'a || "\'"')."\n";
    ##print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'CAST(a AS CHAR)')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'CONCAT(a, b)')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'a ** b')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'POWER(a, b)')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'a ^ b')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', 'a--b')."\n";
    #print STDERR "DEBUG: A: ".SQL::Yapp::parse('Expr', '-b')."\n";

    is(sqlExpr{CAST(a AS CHAR)}, q{CAST( `a` AS CHARACTER )});

    is(sqlExpr{a--b}, q{`a` - (- `b`)});

    is(sqlExpr{-b}, q{- `b`});

    my @a=(1,2,3);
    is(sqlExpr{COALESCE({} OR NOT @a)}, q{COALESCE(((NOT '1') OR (NOT '2') OR (NOT '3')))});

    is(sqlExpr{COALESCE({} OR @a)}, q{COALESCE(('1' OR '2' OR '3'))});

    is(sqlExpr{5 + COALESCE(@a)}, q{'5' + COALESCE('1', '2', '3')});

    # Generic:
    SQL::Yapp::write_dialect('generic');

    is (sqlExpr{a & b},       q{`a` & `b`});
    is (sqlExpr{a | b},       q{`a` | `b`});
    is (sqlExpr{a ^ b},       q{`a` ^ `b`});
    is (sqlExpr{BITAND(a,b)}, q{BITAND(`a`, `b`)});
    is (sqlExpr{BITOR(a,b)},  q{BITOR(`a`, `b`)});
    is (sqlExpr{BITXOR(a,b)}, q{BITXOR(`a`, `b`)});
    is (sqlExpr{a ** b},      q{POWER(`a`, `b`)});
    is (sqlExpr{POW(a,b)},    q{POWER(`a`, `b`)});
    is (sqlExpr{a == b},      q{`a` = `b`});
    is (sqlExpr{a != b},      q{`a` <> `b`});
    is (sqlExpr{a % b},       q{MOD(`a`, `b`)});
    is (sqlExpr{a BETWEEN b AND c}, q{`a` BETWEEN `b` AND `c`});
    is (sqlExpr{a IN (@a IS NULL)}, q{`a` IN ('1' IS NULL, '2' IS NULL, '3' IS NULL)});
    is (sqlExpr{a IN (@a)}, q{`a` IN ('1', '2', '3')});

    # MySQL dialect:
    SQL::Yapp::write_dialect('mysql');
    my $q1= make_select_a_concat_b;
    is ($q1, q{SELECT CONCAT(`a`, `b`, '\'')});

    is (sqlExpr{a & b},       q{`a` & `b`});
    is (sqlExpr{a | b},       q{`a` | `b`});
    is (sqlExpr{a ^ b},       q{`a` ^ `b`});
    is (sqlExpr{BITAND(a,b)}, q{`a` & `b`});
    is (sqlExpr{BITOR(a,b)},  q{`a` | `b`});
    is (sqlExpr{BITXOR(a,b)}, q{`a` ^ `b`});

    # PostgreSQL dialect:
    SQL::Yapp::write_dialect('postgresql');
    my $q2= make_select_a_concat_b;
    is ($q2, q{SELECT `a` || `b` || '\''});

    # Oracle:
    SQL::Yapp::write_dialect('oracle');
    is (sqlExpr{a & b},       q{BITAND(`a`, `b`)});
    is (sqlExpr{a | b},       q{BITOR(`a`, `b`)});
    is (sqlExpr{a ^ b},       q{BITXOR(`a`, `b`)});
    is (sqlExpr{BITAND(a,b)}, q{BITAND(`a`, `b`)});
    is (sqlExpr{BITOR(a,b)},  q{BITOR(`a`, `b`)});
    is (sqlExpr{BITXOR(a,b)}, q{BITXOR(`a`, `b`)});
}

0;
