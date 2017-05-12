# -*- perl -*-

use strict;
use Set::IntSpan 1.17 qw(grep_set map_set);

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

sub Equal
{
    my($a, $b) = @_;

    @$a==@$b or return 0;
    while (@$a) { shift @$a == shift @$b or return 0 }
    1
}


my @Sets  = split(' ', q{ - (-) (-0 0-) 1 5 1-5 3-7 1-3,8,10-23 });

my @Greps = qw(1 0 $_==1 $_<5 $_&1);

my @Maps  = ('', split(' ', q{1 $_ -$_ $_+5 -$_,$_ $_%5}));

#              -     (-)   (-0    0-)        1      5    1-5    3-7  1--23
my @First = (undef, undef, undef,     0,     1,     5,     1,     3,     1);
my @Last  = (undef, undef,     0, undef,     1,     5,     5,     7,    23);
my @Start = (undef,     0,     0,     0, undef, undef, undef, undef, undef);


print "1..", @Sets * (@Greps + @Maps + 3) + 3*16 + 2*6 + 11 + 12, "\n";

Grep   ();
Map    ();
First  ();
Last   ();
Start  ();
StartN ();
Next   ();
Prev   ();
Current();
Wrap   ();


sub Grep
{
    print "#grep_set\n";
    my @exp4 = ('-', undef, undef, undef);

    my @expected = 
    ([@exp4, '1', '5', '1-5'  , '3-7'  , '1-3,8,10-23'             ],
     [@exp4, '-', '-', '-'    , '-'    , '-'                       ],
     [@exp4, '1', '-', '1'    , '-'    , '1'                       ],
     [@exp4, '1', '-', '1-4'  , '3-4'  , '1-3'                     ],
     [@exp4, '1', '5', '1,3,5', '3,5,7', '1,3,11,13,15,17,19,21,23']);

    for (my $s=0; $s<@Sets; $s++)
    {
        for (my $g=0; $g<@Greps; $g++)
        {
	    my $set  = new Set::IntSpan $Sets[$s];
	    my $result = grep_set { eval $Greps[$g] } $set;
	    my $expected = $expected[$g][$s];

	    my $pResult = defined $result ? $result->run_list : 'undef';
	    printf "#%3d: grep_set { %-8s } %-12s -> %s\n",
	    $N, $Greps[$g], $Sets[$s], $pResult;
    	
	    not defined $result and not defined $expected or 
		defined $result and     defined $expected and
    		$result->run_list eq $expected or Not; OK;
        }
    }
}


sub Map
{
    print "#map_set\n";
    my @exp4 = ('-', undef, undef, undef);

    my @expected = 
    ([@exp4, '-'   , '-'   , '-'        , '-'        , '-'               ],
     [@exp4, '1'   , '1'   , '1'        , '1'        , '1'               ],
     [@exp4, '1'   , '5'   , '1-5'      , '3-7'      , '1-3,8,10-23'     ],
     [@exp4, '-1'  , '-5'  , '-5--1'    , '-7--3'    , '-23--10,-8,-3--1'],
     [@exp4, '6'   , '10'  , '6-10'     , '8-12'     , '6-8,13,15-28'    ],
     [@exp4, '-1,1', '-5,5', '-5--1,1-5', '-7--3,3-7', '-23--10,-8,-3--1,1-3,8,10-23'],
     [@exp4, '1'   , '0'   , '0-4'      , '0-4'      , '0-4'             ]);

    for (my $s=0; $s<@Sets; $s++)
    {
        for (my $m=0; $m<@Maps; $m++)
        {
	    my $set  = new Set::IntSpan $Sets[$s];
	    my $result = map_set { eval $Maps[$m] } $set;
	    my $expected = $expected[$m][$s];

	    my $pResult = defined $result ? $result->run_list : 'undef';
	    printf "#%3d: map_set  { %-8s } %-12s -> %s\n",
	    $N, $Maps[$m], $Sets[$s], $pResult;
	    
	    not defined $result and not defined $expected or 
		defined $result and     defined $expected and
    		$result->run_list eq $expected or Not; OK;
        }
    }
}


sub First { Terminal('first', @First); }
sub Last  { Terminal('last' , @Last ); }
sub Start { Terminal('start', @Start); }


sub Terminal
{
    my($method, @expected) = @_;
    print "#$method\n";
	
    for (my $s=0; $s<@Sets; $s++)
    {
	my $set      = new Set::IntSpan $Sets[$s];
	my $result   = $set->$method(0);
	my $expected = $expected[$s];

	my $pResult = defined $result ? $result : 'undef';
	printf "#%3d: %-9s { %-12s } -> %s\n",
	$N, $method, $Sets[$s], $pResult;
    	
    	not defined $result and not defined $expected or 
    	    defined $result and     defined $expected and
    		    $result == $expected or Not; OK;
    }
}


sub StartN
{
    print "#start()\n";
    for my $runList ('2-5,8,10-14', '(-5,8,10-14', '2-5,8,10-)')
    {
	my $set = new Set::IntSpan $runList;

	for my $n (0..15)
	{
	    my $result   = $set->start($n);
	    my $expected = $set->member($n) ? $n : undef;

	    my $pResult = defined $result ? $result : 'undef';
	    printf "#%3d: start(%2d) { %12s } -> %s\n",
	    $N, $n, $runList, $pResult;
	    
	    not defined $result and not defined $expected or 
		defined $result and     defined $expected and
    		    $result == $expected or Not; OK;
	}
    }
}


sub Next
{
    print "#next\n";
    for my $runList (@Sets)
    {
	my $set = new Set::IntSpan $runList;
	finite $set or next;

	my @result;
	for (my $n=$set->first; defined $n; $n=$set->next) 
	{ 
	    push @result, $n;
	}
	
	my @expected = elements $set;

	printf "#%3d: next: %12s -> %s\n",
	$N, $runList, join(',', @expected);
	Equal(\@result, \@expected) or Not; OK;
    }
}


sub Prev
{
    print "#prev\n";
    for my $runList (@Sets)
    {
	my $set = new Set::IntSpan $runList;
	finite $set or next;

	my @result;
	for (my $n=$set->last; defined $n; $n=$set->prev) 
	{ 
	    push @result, $n;
	}
	
	my @expected = reverse elements $set;

	printf "#%3d: prev: %12s -> %s\n",
	$N, $runList, join(',', @expected);
	Equal(\@result, \@expected) or Not; OK;
    }
}


sub Table { map { [ split(' ', $_) ] } split(/\n/, shift) }

sub Current
{
    print "#current\n";
    my $set = new Set::IntSpan '(-0, 3-5, 7-)';
    
    $set->start(0);

    my @walk = Table <<TABLE;
next 3
prev 0
prev -1
next 0
next 3
next 4
next 5
next 7
prev 5
next 7
next 8
TABLE

    for my $step (@walk)
    {
	my($direction, $expected) = @$step;

	$set->$direction();
	my $result = $set->current;

	printf "#%3d: $direction -> $result\n", $N;
	$result==$expected or Not; OK;
    }
}


sub Wrap
{
    print "#wrap\n";

    my @forward  = (1, 2, undef, 1, 2, undef);
    my @backward = (2, 1, undef, 2, 1, undef);

    my $set = new Set::IntSpan '1-2';

    for my $i (0..5)
    {
	my $result   = $set->next;
	my $expected = $forward[$i];
	my $pResult  = defined $result ? $result : 'undef';
	printf "#%3d: next -> $pResult\n", $N;

	not defined $result and not defined $expected or 
	    defined $result and     defined $expected and
		    $result == $expected or Not; OK;
    }

    for my $i (0..5)
    {
	my $result   = $set->prev;
	my $expected = $backward[$i];
	my $pResult  = defined $result ? $result : 'undef';
	printf "#%3d: next -> $pResult\n", $N;

	not defined $result and not defined $expected or 
	    defined $result and     defined $expected and
		    $result == $expected or Not; OK;
    }
}
