# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

my $Sets = [ split(' ', q{ - (-) (-0 0-) 1 5 1-5 3-7 1-3,8,10-23 }) ];

my $Equal = 
    [[qw( 1 0 0 0 0 0 0 0 0 )],
     [qw( 0 1 0 0 0 0 0 0 0 )],
     [qw( 0 0 1 0 0 0 0 0 0 )],
     [qw( 0 0 0 1 0 0 0 0 0 )],
     [qw( 0 0 0 0 1 0 0 0 0 )],
     [qw( 0 0 0 0 0 1 0 0 0 )],
     [qw( 0 0 0 0 0 0 1 0 0 )],
     [qw( 0 0 0 0 0 0 0 1 0 )],
     [qw( 0 0 0 0 0 0 0 0 1 )]];

my $Equivalent = 
    [[qw( 1 0 0 0 0 0 0 0 0 )],
     [qw( 0 1 1 1 0 0 0 0 0 )],
     [qw( 0 1 1 1 0 0 0 0 0 )],
     [qw( 0 1 1 1 0 0 0 0 0 )],
     [qw( 0 0 0 0 1 1 0 0 0 )],
     [qw( 0 0 0 0 1 1 0 0 0 )],
     [qw( 0 0 0 0 0 0 1 1 0 )],
     [qw( 0 0 0 0 0 0 1 1 0 )],
     [qw( 0 0 0 0 0 0 0 0 1 )]];

my $Superset = 
    [[qw( 1 0 0 0 0 0 0 0 0 )],
     [qw( 1 1 1 1 1 1 1 1 1 )],
     [qw( 1 0 1 0 0 0 0 0 0 )],
     [qw( 1 0 0 1 1 1 1 1 1 )],
     [qw( 1 0 0 0 1 0 0 0 0 )],
     [qw( 1 0 0 0 0 1 0 0 0 )],
     [qw( 1 0 0 0 1 1 1 0 0 )],
     [qw( 1 0 0 0 0 1 0 1 0 )],
     [qw( 1 0 0 0 1 0 0 0 1 )]];

my $Subset = 
    [[qw( 1 1 1 1 1 1 1 1 1 )],
     [qw( 0 1 0 0 0 0 0 0 0 )],
     [qw( 0 1 1 0 0 0 0 0 0 )],
     [qw( 0 1 0 1 0 0 0 0 0 )],
     [qw( 0 1 0 1 1 0 1 0 1 )],
     [qw( 0 1 0 1 0 1 1 1 0 )],
     [qw( 0 1 0 1 0 0 1 0 0 )],
     [qw( 0 1 0 1 0 0 0 1 0 )],
     [qw( 0 1 0 1 0 0 0 0 1 )]];


print "1..", 4 * @$Sets * @$Sets, "\n";
Equal     ();
Equivalent();
Superset  ();
Subset    ();


sub Equal      { Relation("equal"     , $Sets, $Equal     ) }
sub Equivalent { Relation("equivalent", $Sets, $Equivalent) }
sub Superset   { Relation("superset"  , $Sets, $Superset  ) }
sub Subset     { Relation("subset"    , $Sets, $Subset    ) }


sub Relation
{
    my($method, $sets, $expected) = @_;
    print "#$method\n";

    for (my $i=0; $i<@{$sets}; $i++)
    {
	for (my $j=0; $j<@{$sets}; $j++)
	{
	    Relation_1($method, $sets->[$i], $sets->[$j], $expected->[$i][$j]);
	}
    }
}


sub Relation_1
{
    my($method, $op1, $op2, $expected) = @_;
    my $result;
    my $set1 = new Set::IntSpan $op1;
    my $set2 = new Set::IntSpan $op2;
    $result = $set1->$method($set2);

    printf "#%-12s %-12s %-12s -> %d\n", $method, $op1, $op2, $result;
    $result ? $expected : ! $expected or Not; OK;
}
