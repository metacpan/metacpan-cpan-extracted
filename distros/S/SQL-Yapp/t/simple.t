#! /usr/bin/perl
#
# Some simple tests used while implementing new features.

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 5;

use SQL::Yapp
    table_prefix => 'T'
  , write_dialect => 'mysql'
  , quote_identifier => sub {
        join('.', map { "`$_`" } grep { defined($_) } @_)
    }
  , quote => sub {
        qq{'$_[0]'}
    }
  #, debug => 1
;

{
    my $c= sqlCheck{> 5};
    is($c, q{ > '5'});
}

{
    my $qp= SQL::Yapp::parse('Expr', q{ CASE a WHEN > 5 THEN 1 ELSE 2 END });
    my $q= eval $qp;
    is($q, q{CASE `a` WHEN  > '5' THEN '1' ELSE '2' END});
}

{
    my $c= sqlCheck{> 5};
    my $q= sqlExpr{ CASE a WHEN $c THEN 1 ELSE 2 END };
    is($q, q{CASE `a` WHEN  > '5' THEN '1' ELSE '2' END});
}

eval {
    my $c= sqlCheck{> 5};
    my $q= sqlExpr{ $c + 0 };
};
like($@, qr/but found Check/);

{
    my %a= (
        surname => 'Doe',
        age     => sqlCheck{ > 50 }
    );
    my $q= sql{ UPDATE t SET forename = 'Jonathan' WHERE {} AND %a };
    is($q, q{UPDATE `Tt` SET `forename` = 'Jonathan' }.
           q{WHERE (`age`  > '50') AND (`surname` = 'Doe')});
}

0;
