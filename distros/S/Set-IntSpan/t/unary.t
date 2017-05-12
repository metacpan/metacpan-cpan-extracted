# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

sub Table { map { [ split(' ', $_) ] } split(/\s*\n\s*/, shift) }

my @Unaries = Table <<TABLE;
-            (-)
(-1          2-)
1            (-0,2-)
1-3          (-0,4-)
1-3,5-9,15-) (-0,4,10-14
TABLE

print "1..", 4 * @Unaries, "\n";
Complement();


sub Complement
{
    print "#complement\n";

    for my $t (@Unaries)
    {
	Unary("complement", $t->[0], $t->[1]);
	Unary("complement", $t->[1], $t->[0]);
	U    ("C"	  , $t->[0], $t->[1]);
	U    ("C"	  , $t->[1], $t->[0]);
    }
}


sub Unary
{
    my($method, $operand, $expected) = @_;
    my $set = new Set::IntSpan $operand;
    my $setE = $set->$method();
    my $run_list = run_list $setE;

    printf "#%-12s %-10s -> %-10s\n", $method, $operand, $run_list;
    $run_list eq $expected or Not; OK;
}

sub U
{
    my($method, $operand, $expected) = @_;
    my $set = new Set::IntSpan $operand;
    $set->$method();
    my $run_list = run_list $set;

    printf "#%-12s %-10s -> %-10s\n", $method, $operand, $run_list;
    $run_list eq $expected or Not; OK;
}

