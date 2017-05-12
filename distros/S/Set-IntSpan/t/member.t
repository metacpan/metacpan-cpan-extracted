# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

sub Table { [ map { [ split(' ', $_) ] } split(/\s*\n\s*/, shift) ] }

my @Sets     = split(' ',  q{ - (-) (-3 3-) 3 3-5 3-5,7-9 } );
my @Elements = ( 1..7 );

my $Member = Table <<TABLE;
0 0 0 0 0 0 0
1 1 1 1 1 1 1
1 1 1 0 0 0 0
0 0 1 1 1 1 1
0 0 1 0 0 0 0
0 0 1 1 1 0 0
0 0 1 1 1 0 1
TABLE

my $Insert = Table <<TABLE;
 1         2       3       4       5       6     7
(-)       (-)     (-)     (-)     (-)     (-)   (-)
(-3       (-3     (-3     (-4     (-3,5   (-3,6 (-3,7
1,3-)     2-)     3-)     3-)     3-)     3-)   3-)
1,3       2-3     3       3-4     3,5     3,6   3,7
1,3-5     2-5     3-5     3-5     3-5     3-6   3-5,7
1,3-5,7-9 2-5,7-9 3-5,7-9 3-5,7-9 3-5,7-9 3-9   3-5,7-9
TABLE

my $Remove = Table <<TABLE;
-       -       -       -       -       -       -
(-0,2-) (-1,3-) (-2,4-) (-3,5-) (-4,6-) (-5,7-) (-6,8-)
(-0,2-3 (-1,3   (-2     (-3     (-3     (-3     (-3
3-)     3-)     4-)     3,5-)   3-4,6-) 3-5,7-) 3-6,8-)
3       3       -       3       3       3       3
3-5     3-5     4-5     3,5     3-4     3-5     3-5
3-5,7-9 3-5,7-9 4-5,7-9 3,5,7-9 3-4,7-9 3-5,7-9 3-5,8-9
TABLE


print "1..", 3 * @Sets * @Elements, "\n";
Member();
Insert();
Remove();


sub Member
{
    print "#member\n";

    for my $s (0..$#Sets)
    {
	for my $i (0..$#Elements)
	{
	    my $run_list = $Sets[$s];
	    my $set = new Set::IntSpan $run_list;
	    my $int = $Elements[$i];
	    my $result = member $set $int;

	    printf "#%-12s %-12s %d -> %d\n",
	    "member", $run_list, $int, $result;
	    my $expected = $Member->[$s][$i];
	    $result ? $expected : ! $expected or Not; OK;
	}
    }
}


sub Insert { Delta("insert", $Insert) }
sub Remove { Delta("remove", $Remove) }

sub Delta
{
    my($method, $expected) = @_;

    print "#$method\n";

    for my $s (0..$#Sets)
    {
	for my $i (0..$#Elements)
	{
	    my $run_list = $Sets[$s];
	    my $set = new Set::IntSpan $run_list;
	    my $int = $Elements[$i];
	    $set->$method($int);
	    my $result = run_list $set;

	    printf "#%-12s %-12s %d -> %s\n",
	    $method, $run_list, $int, $result;
	    $result eq $expected->[$s][$i] or Not; OK;
	}
    }
}
